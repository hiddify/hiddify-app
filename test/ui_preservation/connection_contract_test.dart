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
import 'package:hiddify/features/diagnostics/observed_connection_repository.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
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
  }) async {
    final events = <String>[];
    final spy = ButtonConnectionSpy(status, events);
    final dialogs = FixtureDialogs(events);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWith((ref) => prefs),
          translationsProvider.overrideWith((ref) => t),
          connectionNotifierProvider.overrideWith(() => spy),
          activeProfileProvider.overrideWith(() => FixtureProfile(profile ? connectionProfile : null)),
          activeProxyNotifierProvider.overrideWith(() => FixtureProxy(delay)),
          configOptionNotifierProvider.overrideWith(() => FixtureConfig(reconnect)),
          dialogNotifierProvider.overrideWith(() => dialogs),
          bottomSheetsNotifierProvider.overrideWith(() => FixtureSheets(events)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ConnectionButton())),
        ),
      ),
    );
    ProviderScope.containerOf(tester.element(find.byType(ConnectionButton))).read(activeProfileProvider);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return (spy, dialogs, events);
  }

  Finder button() => find.byKey(const ValueKey('home_connection_button'));
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
