import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/diagnostics/home_presentation_providers.dart';
import 'package:hiddify/features/diagnostics/home_presentation_snapshot.dart';
import 'package:hiddify/features/diagnostics/observed_connection_repository.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/connection_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final t = AppLocale.en.buildSync();
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'haptic_feedback': false,
      'disable_memory_limit': false,
      'enable-warp': true,
      'warp-detour-mode': 'warpOverProxy',
    });
    prefs = await SharedPreferences.getInstance();
  });
  Future<(ButtonConnectionSpy, FixtureDialogs, List<String>)> mount(
    WidgetTester tester,
    AsyncValue<ConnectionStatus> status, {
    int delay = 1,
    bool reconnect = false,
    bool profile = true,
    TargetPlatform platform = TargetPlatform.android,
    Stream<OutboundInfo>? proxyStream,
    ButtonConnectionSpy Function(List<String> events)? spyFactory,
    List<ProviderObserver> observers = const [],
  }) async {
    final events = <String>[];
    final spy = spyFactory?.call(events) ?? ButtonConnectionSpy(status, events);
    final dialogs = FixtureDialogs(events);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      ProviderScope(
        observers: observers,
        overrides: [
          sharedPreferencesProvider.overrideWith((ref) => prefs),
          translationsProvider.overrideWith((ref) => t),
          connectionNotifierProvider.overrideWith(() => spy),
          activeProfileProvider.overrideWith(() => FixtureProfile(profile ? connectionProfile : null)),
          activeProxyNotifierProvider.overrideWith(
            () => proxyStream == null ? FixtureProxy(delay) : _ProxyStreamFixture(proxyStream),
          ),
          configOptionNotifierProvider.overrideWith(() => FixtureConfig(reconnect)),
          dialogNotifierProvider.overrideWith(() => dialogs),
          bottomSheetsNotifierProvider.overrideWith(() => FixtureSheets(events)),
          homePresentationDiagnosticsEnabledProvider.overrideWithValue(true),
          homePresentationRuntimeIosProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: platform),
          home: const Scaffold(body: Center(child: ConnectionButton())),
        ),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(ConnectionButton))).read(activeProfileProvider);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return (spy, dialogs, events);
  }

  Finder button() => find.byKey(const ValueKey('home_connection_button'));
  HomePresentationSnapshot snapshot(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(ConnectionButton))).read(homePresentationSnapshotProvider)!;
  for (final entry in <(AsyncValue<ConnectionStatus>, String, bool)>[
    (const AsyncData(Disconnected()), t.connection.tapToConnect, true),
    (const AsyncData(Connecting()), t.connection.connecting, false),
    (const AsyncData(Connected()), t.connection.connected, true),
    (const AsyncData(Disconnecting()), t.connection.disconnecting, false),
    (const AsyncLoading(), '', false),
    (AsyncError(StateError('synthetic'), StackTrace.empty), '', true),
  ]) {
    testWidgets('real button ${entry.$1}: label, enabled and tap', (tester) async {
      final (_, _, events) = await mount(tester, entry.$1, delay: entry.$1 is AsyncError ? 0 : 1);
      final semantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .singleWhere((s) => s.properties.button == true && s.properties.enabled != null);
      expect(semantics.properties.label, entry.$2);
      expect(semantics.properties.enabled, entry.$3);
      await tester.tap(button());
      await tester.pump();
      expect(events, entry.$3 ? (entry.$1.valueOrNull is Connected ? ['toggle'] : ['notice', 'toggle']) : isEmpty);
    });
  }
  for (final delay in [0, 1, 64999, 65000, 65001]) {
    testWidgets('latency $delay preserves distinct connected and WARP boundaries', (tester) async {
      await mount(tester, const AsyncData(Connected()), delay: delay);
      expect(find.text(delay <= 0 || delay >= 65000 ? t.connection.connecting : t.connection.connected), findsWidgets);
      expect(find.text(t.connection.secure), delay > 0 && delay <= 65000 ? findsOneWidget : findsNothing);
    });
  }
  for (final entry in <(int, HomeLatencyBand, HomeLabelChoice)>[
    (0, HomeLatencyBand.nonPositive, HomeLabelChoice.connecting),
    (1, HomeLatencyBand.valid, HomeLabelChoice.connected),
    (64999, HomeLatencyBand.valid, HomeLabelChoice.connected),
    (65000, HomeLatencyBand.atLimit, HomeLabelChoice.connecting),
    (65001, HomeLatencyBand.aboveLimit, HomeLabelChoice.connecting),
  ]) {
    testWidgets('probe records the actual Android-theme label branch at latency ${entry.$1}', (tester) async {
      await mount(tester, const AsyncData(Connected()), delay: entry.$1);

      expect(
        snapshot(tester),
        HomePresentationSnapshot(
          asyncVariant: HomeAsyncVariant.data,
          connectionValue: HomeConnectionValue.connected,
          labelChoice: entry.$3,
          themePlatform: HomeThemePlatform.android,
          runtimeIos: true,
          reconnect: HomeReconnectValue.falseValue,
          latencyBand: entry.$2,
          tickersEnabled: true,
          lifecycleState: HomeLifecycleState.resumed,
        ),
      );
    });
  }
  for (final delay in [0, 1, 64999, 65000, 65001]) {
    testWidgets('iOS Connected label and disconnect action ignore latency $delay', (tester) async {
      final (_, _, events) = await mount(
        tester,
        const AsyncData(Connected()),
        delay: delay,
        platform: TargetPlatform.iOS,
      );
      final semantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .singleWhere((s) => s.properties.button == true && s.properties.enabled != null);
      expect(semantics.properties.label, t.connection.connected);
      expect(semantics.properties.enabled, true);
      await tester.tap(button());
      await tester.pump();
      expect(events, ['toggle']);
    });
  }
  for (final entry in <(String, Stream<OutboundInfo>)>[
    ('loading', const Stream<OutboundInfo>.empty()),
    ('missing', Stream<OutboundInfo>.value(OutboundInfo())),
    ('error', Stream<OutboundInfo>.error(StateError('synthetic'), StackTrace.empty)),
  ]) {
    testWidgets('iOS Connected stays actionable with proxy ${entry.$1}', (tester) async {
      final (_, _, events) = await mount(
        tester,
        const AsyncData(Connected()),
        platform: TargetPlatform.iOS,
        proxyStream: entry.$2,
      );
      final semantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .singleWhere((s) => s.properties.button == true && s.properties.enabled != null);
      expect(semantics.properties.label, t.connection.connected);
      expect(semantics.properties.enabled, true);
      await tester.tap(button());
      await tester.pump();
      expect(events, ['toggle']);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('iOS actual Connecting remains disabled regardless of proxy latency', (tester) async {
    final (_, _, events) = await mount(
      tester,
      const AsyncData(Connecting()),
      delay: 0,
      platform: TargetPlatform.iOS,
    );
    final semantics = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .singleWhere((s) => s.properties.button == true && s.properties.enabled != null);
    expect(semantics.properties.label, t.connection.connecting);
    expect(semantics.properties.enabled, false);
    await tester.tap(button());
    await tester.pump();
    expect(events, isEmpty);
  });
  testWidgets('iOS connection error remains enabled and retryable', (tester) async {
    final (_, _, events) = await mount(
      tester,
      AsyncError(StateError('synthetic'), StackTrace.empty),
      delay: 0,
      platform: TargetPlatform.iOS,
    );
    final semantics = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .singleWhere((s) => s.properties.button == true && s.properties.enabled != null);
    expect(semantics.properties.label, '');
    expect(semantics.properties.enabled, true);
    await tester.tap(button());
    await tester.pump();
    expect(events, ['notice', 'toggle']);
  });
  for (final entry in <(String, AsyncValue<ConnectionStatus>, String, bool, List<String>)>[
    (
      'error',
      AsyncError<ConnectionStatus>(StateError('synthetic'), StackTrace.empty)
          .copyWithPrevious(const AsyncData(Connected())),
      '',
      true,
      ['notice', 'toggle'],
    ),
    (
      'loading',
      const AsyncLoading<ConnectionStatus>().copyWithPrevious(
        const AsyncData(Connected()),
        isRefresh: false,
      ),
      '',
      false,
      <String>[],
    ),
  ]) {
    testWidgets('iOS ${entry.$1} with previous Connected preserves label and action', (tester) async {
      late _MetadataConnectionSpy metadataSpy;
      await mount(
        tester,
        const AsyncData(Disconnected()),
        delay: 0,
        platform: TargetPlatform.iOS,
        spyFactory: (events) => metadataSpy = _MetadataConnectionSpy(events),
      );
      metadataSpy.restoredStatus = entry.$2;
      await tester.pump();

      final actual = ProviderScope.containerOf(tester.element(find.byType(ConnectionButton))).read(
        connectionNotifierProvider,
      );
      expect(actual.valueOrNull, const Connected());
      expect(
        actual,
        entry.$1 == 'error'
            ? isA<AsyncError<ConnectionStatus>>()
            : isA<AsyncLoading<ConnectionStatus>>(),
      );
      final semantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .singleWhere((s) => s.properties.button == true && s.properties.enabled != null);
      expect(semantics.properties.label, entry.$3);
      expect(semantics.properties.enabled, entry.$4);
      await tester.tap(button());
      await tester.pump();
      expect(metadataSpy.events, entry.$5);
      expect(snapshot(tester).asyncVariant, entry.$1 == 'error' ? HomeAsyncVariant.error : HomeAsyncVariant.loading);
      expect(snapshot(tester).connectionValue, HomeConnectionValue.connected);
      expect(snapshot(tester).labelChoice, HomeLabelChoice.empty);
    });
  }
  for (final warpEnabled in [true, false]) {
    testWidgets('error with valid latency keeps retry usable with WARP $warpEnabled', (tester) async {
      await prefs.setBool('enable-warp', warpEnabled);
      final failure = StateError('synthetic');
      final (_, _, events) = await mount(tester, AsyncError(failure, StackTrace.empty));
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(button(), findsOneWidget);
      expect(find.text(t.connection.secure), findsNothing);
      final semantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .singleWhere((s) => s.properties.button == true && s.properties.enabled != null);
      expect(semantics.properties.label, '');
      expect(semantics.properties.enabled, true);
      await tester.tap(button());
      await tester.pump();
      expect(events, ['notice', 'toggle']);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('WARP disabled hides secure label', (tester) async {
    await prefs.setBool('enable-warp', false);
    await mount(tester, const AsyncData(Connected()));
    expect(find.text(t.connection.secure), findsNothing);
  });
  testWidgets('reconnect takes priority over invalid latency and notice', (tester) async {
    final (spy, _, events) = await mount(tester, const AsyncData(Connected()), delay: 0, reconnect: true);
    expect(find.text(t.connection.reconnect), findsWidgets);
    await tester.tap(button());
    await tester.pump();
    expect(events, ['reconnect']);
    expect(spy.reconnectedProfile, connectionProfile);
    expect(snapshot(tester).labelChoice, HomeLabelChoice.reconnect);
    expect(snapshot(tester).reconnect, HomeReconnectValue.trueValue);
  });
  testWidgets('probe publishes one deduplicated snapshot without a frame loop', (tester) async {
    final observer = _HomePresentationObserver();
    await mount(tester, const AsyncData(Connected()), observers: [observer]);
    final updatesAfterSettling = observer.updates;
    expect(updatesAfterSettling, greaterThanOrEqualTo(1));

    for (var index = 0; index < 8; index++) {
      await tester.pump();
    }

    expect(observer.updates, updatesAfterSettling);
    expect(tester.takeException(), isNull);
  });
  testWidgets('iOS reconnect takes priority over Connected label and disconnect action', (tester) async {
    final (spy, _, events) = await mount(
      tester,
      const AsyncData(Connected()),
      delay: 0,
      reconnect: true,
      platform: TargetPlatform.iOS,
    );
    final semantics = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .singleWhere((s) => s.properties.button == true && s.properties.enabled != null);
    expect(semantics.properties.label, t.connection.reconnect);
    expect(semantics.properties.enabled, true);
    await tester.tap(button());
    await tester.pump();
    expect(events, ['reconnect']);
    expect(spy.reconnectedProfile, connectionProfile);
  });
  testWidgets('no profile awaits dialog then opens sheet then awaits experimental notice', (tester) async {
    final (_, dialogs, events) = await mount(tester, const AsyncData(Disconnected()), profile: false);
    dialogs.noProfile = Completer<void>();
    dialogs.notice = Completer<bool>();
    await tester.tap(button());
    await tester.pump();
    expect(events, ['no-profile']);
    dialogs.noProfile!.complete();
    await tester.pump();
    expect(events, ['no-profile', 'add-profile:null', 'notice']);
    dialogs.notice!.complete(true);
    await tester.pump();
    expect(events, ['no-profile', 'add-profile:null', 'notice', 'toggle']);
  });
  testWidgets('cancel experimental notice prevents start', (tester) async {
    final (_, dialogs, events) = await mount(tester, const AsyncData(Disconnected()));
    dialogs.noticeResult = false;
    await tester.tap(button());
    await tester.pump();
    expect(events, ['notice']);
  });

  for (final observe in [false, true]) {
    group('real ConnectionNotifier with repository boundary fake (diagnostics=$observe)', () {
      late ProviderContainer container;
      late RecordingConnectionRepository repo;
      late SafeDiagnosticJournal journal;
      Future<void> flush() async {
        for (var i = 0; i < 8; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      Future<ConnectionNotifier> initialize({bool profile = true}) async {
        repo = RecordingConnectionRepository();
        journal = SafeDiagnosticJournal();
        container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) => prefs),
            translationsProvider.overrideWith((ref) => t),
            connectionRepositoryProvider.overrideWithValue(
              observe ? ObservedConnectionRepository(repo, journal) : repo,
            ),
            activeProfileProvider.overrideWith(() => FixtureProfile(profile ? connectionProfile : null)),
            dialogNotifierProvider.overrideWith(() => FixtureDialogs([])),
          ],
        );
        final notifier = container.read(connectionNotifierProvider.notifier);
        await flush();
        return notifier;
      }

      tearDown(() async {
        container.dispose();
        await repo.statuses.close();
        journal.dispose();
      });
      test('OFF starts once while pending with exact profile/memory arguments', () async {
        final notifier = await initialize();
        repo.statuses.add(const Disconnected());
        await flush();
        repo.connectGate = Completer<void>();
        await notifier.toggleConnection();
        await flush();
        await notifier.toggleConnection();
        await flush();
        expect(repo.calls, ['connect']);
        expect(repo.args, [(connectionProfile, false)]);
        expect(container.read(Preferences.startedByUser), true);
        repo.connectGate!.complete();
        await flush();
      });
      test('ON disconnects once and clears started-by-user', () async {
        final notifier = await initialize();
        repo.statuses.add(const Connected());
        await flush();
        await notifier.toggleConnection();
        expect(repo.calls, ['disconnect']);
        expect(container.read(Preferences.startedByUser), false);
      });
      for (final status in [const Connecting(), const Disconnecting()]) {
        test('$status ignores toggle and reconnect', () async {
          final notifier = await initialize();
          repo.statuses.add(status);
          await flush();
          await notifier.toggleConnection();
          await notifier.reconnect(connectionProfile);
          expect(repo.calls, isEmpty);
        });
      }
      test('loading ignores toggle', () async {
        final notifier = await initialize();
        await notifier.toggleConnection();
        expect(repo.calls, isEmpty);
      });
      test('no profile never invokes repository start', () async {
        final notifier = await initialize(profile: false);
        repo.statuses.add(const Disconnected());
        await flush();
        await notifier.toggleConnection();
        await flush();
        expect(repo.calls, isEmpty);
      });
      test('connected reconnect passes exact arguments, null profile disconnects', () async {
        final notifier = await initialize();
        repo.statuses.add(const Connected());
        await flush();
        await notifier.reconnect(connectionProfile);
        expect(repo.calls, ['reconnect']);
        expect(repo.args, [(connectionProfile, false)]);
        await notifier.reconnect(null);
        expect(repo.calls, ['reconnect', 'disconnect']);
      });
      test('repository failure becomes error and clears started flag', () async {
        final notifier = await initialize();
        repo.statuses.add(const Disconnected());
        await flush();
        repo.failure = const MissingVpnPermission();
        await notifier.toggleConnection();
        await flush();
        expect(repo.calls, ['connect']);
        expect(container.read(connectionNotifierProvider).error, const MissingVpnPermission());
        expect(container.read(Preferences.startedByUser), false);
      });
      test('stream error retries connection', () async {
        final notifier = await initialize();
        repo.statuses.addError(StateError('synthetic'));
        await flush();
        expect(container.read(connectionNotifierProvider), isA<AsyncError<ConnectionStatus>>());
        await notifier.toggleConnection();
        await flush();
        expect(repo.calls, ['connect']);
        expect(repo.args, [(connectionProfile, false)]);
      });
    });
  }
}

class _ProxyStreamFixture extends ActiveProxyNotifier {
  _ProxyStreamFixture(this.stream);

  final Stream<OutboundInfo> stream;

  @override
  Stream<OutboundInfo> build() => stream;
}

class _MetadataConnectionSpy extends ButtonConnectionSpy {
  _MetadataConnectionSpy(List<String> events) : super(const AsyncLoading(), events);

  AsyncValue<ConnectionStatus> get restoredStatus => state;

  set restoredStatus(AsyncValue<ConnectionStatus> next) {
    state = next;
  }

  @override
  Stream<ConnectionStatus> build() => Stream.value(const Connected());
}

class _HomePresentationObserver extends ProviderObserver {
  int updates = 0;

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider == homePresentationSnapshotProvider) updates++;
  }
}
