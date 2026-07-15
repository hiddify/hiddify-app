import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/features/proxy/model/auto_mode_selection.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_page.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _ProxiesState extends ProxiesOverviewNotifier {
  _ProxiesState(this.selection);

  final AutoModeSelection selection;
  final requestedGroups = <String>[];

  @override
  Stream<OutboundGroup?> build() => Stream.value(OutboundGroup(tag: 'select'));

  @override
  Future<AutoModeSelection?> urlTest(String groupTag) async {
    requestedGroups.add(groupTag);
    return selection;
  }
}

class _SortState extends ProxiesSortNotifier {
  @override
  ProxiesSort build() => ProxiesSort.unsorted;

  @override
  Future<void> update(ProxiesSort value) async => state = value;
}

void main() {
  String feedback(AutoModeSelection selection) =>
      autoModeSelectionFeedback(selection, autoLabel: 'Auto', timeoutLabel: 'Timeout', emptyLabel: 'No servers');

  test('presents the selected server and measured latency', () {
    expect(
      feedback(
        const AutoModeSelection(
          outboundTag: 'Stockholm',
          reason: AutoModeSelectionReason.lowestLatency,
          latency: Duration(milliseconds: 42),
        ),
      ),
      'Auto: Stockholm · 42 ms',
    );
  });

  test('presents deterministic, timeout, and empty outcomes truthfully', () {
    expect(
      feedback(
        const AutoModeSelection(outboundTag: 'Amsterdam', reason: AutoModeSelectionReason.deterministicFallback),
      ),
      'Auto: Amsterdam',
    );
    expect(
      feedback(const AutoModeSelection(outboundTag: 'Berlin', reason: AutoModeSelectionReason.latencyUnavailable)),
      'Auto: Berlin · Timeout',
    );
    expect(
      feedback(const AutoModeSelection(outboundTag: null, reason: AutoModeSelectionReason.noAuthorizedServers)),
      'No servers',
    );
  });

  testWidgets('the production Auto Mode action tests select and shows the chosen server', (tester) async {
    const selection = AutoModeSelection(
      outboundTag: 'Stockholm',
      reason: AutoModeSelectionReason.lowestLatency,
      latency: Duration(milliseconds: 42),
    );
    final notifier = _ProxiesState(selection);
    final translations = await AppLocale.en.build();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translationsProvider.overrideWith((ref) => translations),
          proxiesOverviewNotifierProvider.overrideWith(() => notifier),
          proxiesSortNotifierProvider.overrideWith(_SortState.new),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [NovaThemeData.dark]),
          home: const ProxiesOverviewPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(notifier.requestedGroups, ['select']);
    expect(find.text('Auto: Stockholm · 42 ms'), findsOneWidget);
  });

  testWidgets('the production Auto Mode action reports an empty authorized set', (tester) async {
    final notifier = _ProxiesState(
      const AutoModeSelection(outboundTag: null, reason: AutoModeSelectionReason.noAuthorizedServers),
    );
    final translations = await AppLocale.en.build();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translationsProvider.overrideWith((ref) => translations),
          proxiesOverviewNotifierProvider.overrideWith(() => notifier),
          proxiesSortNotifierProvider.overrideWith(_SortState.new),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [NovaThemeData.dark]),
          home: const ProxiesOverviewPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(notifier.requestedGroups, ['select']);
    expect(find.text(translations.pages.proxies.empty), findsOneWidget);
  });
}
