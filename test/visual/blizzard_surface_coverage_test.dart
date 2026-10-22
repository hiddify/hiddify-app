import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/dialog/widgets/setting_input_dialog.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/features/about/widget/about_page.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hiddify/features/common/qr_code_dialog.dart';
import 'package:hiddify/features/diagnostics/diagnostic_providers.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostics_page.dart';
import 'package:hiddify/features/intro/widget/intro_page.dart';
import 'package:hiddify/features/log/data/log_data_providers.dart';
import 'package:hiddify/features/log/data/log_path_resolver.dart';
import 'package:hiddify/features/log/model/log_entity.dart';
import 'package:hiddify/features/log/overview/logs_overview_notifier.dart';
import 'package:hiddify/features/log/overview/logs_overview_state.dart';
import 'package:hiddify/features/log/overview/logs_page.dart';
import 'package:hiddify/features/profile/details/json_editor.dart';
import 'package:hiddify/features/profile/details/profile_details_notifier.dart';
import 'package:hiddify/features/profile/details/profile_details_page.dart';
import 'package:hiddify/features/profile/details/profile_details_state.dart';
import 'package:hiddify/features/profile/overview/profiles_modal.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_page.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/features/settings/overview/settings_page.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/placeholders.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../support/blizzard_capture.dart';
import '../support/blizzard_visual_fixture.dart';
import '../support/connection_fixtures.dart';
import '../support/home_fixture.dart' as home;
import '../support/profile_settings_fixtures.dart' show FixtureCore, FixtureHttp;
import '../support/surface_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerBlizzardSurfaceCoverage();
}

Widget _appliedBlizzard(Widget child) => Builder(
  builder: (context) => Theme(data: BlizzardTheme.from(Theme.of(context)), child: child),
);

void registerBlizzardSurfaceCoverage() {
  for (final editor in Editors.values) {
    testWidgets('legacy JSON ${editor.name} toolbar preserves trailing alignment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverflowBox(
              minWidth: 700,
              maxWidth: 700,
              minHeight: 500,
              maxHeight: 500,
              child: SizedBox(
                width: 700,
                height: 500,
                child: JsonEditor(json: '{"name":"initial"}', editors: [editor], onChanged: (_) {}),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.getSize(find.byType(JsonEditor)).width, 700);
      // This intentionally measures the wide legacy toolbar, independently of
      // the native host's phone viewport. Narrow Blizzard geometry is separate.
      // Confirmed against the shipped baseline: DecoratedBox paints its border
      // without adding an inset; the original toolbar has 10 px end padding.
      expect(
        tester.getRect(find.byTooltip('Copy')).right,
        closeTo(tester.getRect(find.byType(JsonEditor)).right - 10, .01),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('real scoped JSON editor keeps draft selection and focus when appearance changes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(599, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final changes = <dynamic>[];
    Widget app(AppThemeMode mode) {
      final base = AppTheme(mode, Platform.isIOS ? '.SF Pro Text' : '');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: base.lightTheme(null),
        darkTheme: base.darkTheme(null),
        themeMode: mode.flutterThemeMode,
        builder: (context, child) => Center(
          child: SizedBox(
            width: 599,
            height: 620,
            child: RepaintBoundary(
              key: blizzardFixtureCanvas,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: const Size(599, 620)),
                child: child!,
              ),
            ),
          ),
        ),
        home: Scaffold(
          body: JsonEditor(
            key: const ValueKey('scoped-editor'),
            json: '{"name":"initial"}',
            editors: const [Editors.text],
            onChanged: changes.add,
          ),
        ),
      );
    }

    await tester.pumpWidget(app(AppThemeMode.dark));
    await tester.pump(const Duration(seconds: 1));
    final field = find.byType(TextField).last;
    await tester.tap(field);
    await tester.enterText(field, '{"name":"draft"}');
    final before = tester.widget<EditableText>(find.byType(EditableText).last);
    before.controller.selection = const TextSelection.collapsed(offset: 8);
    await tester.pump(const Duration(milliseconds: 600));
    expect(changes, [
      {'name': 'draft'},
    ]);
    if (expectsBlizzard(AppThemeMode.dark, Brightness.dark, 599)) {
      expect(before.style.fontFamily, 'monospace');
      expect(before.style.fontSize, 13);
    }
    await captureBlizzardFixture(tester, 'JsonEditor-dark-draft');
    await tester.pumpWidget(app(AppThemeMode.light));
    await tester.pump(const Duration(seconds: 1));
    final after = tester.widget<EditableText>(find.byType(EditableText).last);
    expect(identical(before.controller, after.controller), isTrue);
    expect(identical(before.focusNode, after.focusNode), isTrue);
    expect(after.focusNode.hasFocus, isTrue);
    expect(after.controller.text, '{"name":"draft"}');
    expect(after.controller.selection.baseOffset, 8);
    expect(changes.length, 1);
    expect(tester.takeException(), isNull);
    await captureBlizzardFixture(tester, 'JsonEditor-light-same-draft');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final width in [320.0, 393.0]) {
    testWidgets('real ten-server list remains reachable and forwards actions at $width', (tester) async {
      final group = OutboundGroup(
        tag: 'select',
        selected: 'Synthetic server 1',
        items: List.generate(
          10,
          (index) => OutboundInfo(
            tag: 'Synthetic server ${index + 1}',
            tagDisplay: 'Synthetic server ${index + 1}',
            type: 'vless',
            urlTestDelay: index == 1 ? 0 : (index == 2 ? 65001 : 84 + index),
          ),
        ),
      );
      final core = FixtureCore()..group = group;
      final http = FixtureHttp();
      final f = await home.mountHomeFixture(
        tester,
        width: width,
        scale: 1.3,
        locale: AppLocale.ru,
        child: const ProxiesOverviewPage(),
        extraOverrides: [
          proxiesOverviewNotifierProvider.overrideWith(() => SurfaceProxies(AsyncData(group))),
          proxyRepositoryProvider.overrideWith((ref) => ProxyRepositoryImpl(singbox: core, client: http)),
        ],
      );
      final grid = find.byType(GridView);
      for (var index = 1; index <= 10; index++) {
        final label = find.text('Synthetic server $index');
        await tester.scrollUntilVisible(
          label,
          90,
          scrollable: find.descendant(of: grid, matching: find.byType(Scrollable)),
        );
        expect(label.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      final last = find.byWidgetPredicate((w) => w is ProxyTile && w.proxy.tag == 'Synthetic server 10');
      await tester.tap(last);
      await tester.pump(const Duration(seconds: 1));
      expect(core.selections, [('select', 'Synthetic server 10')]);
      expect(f.container.read(proxiesOverviewNotifierProvider).requireValue!.selected, 'Synthetic server 10');
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(seconds: 1));
      expect(core.delayTests, ['select']);
      expect(tester.takeException(), isNull);
      await f.close(tester);
    });
  }
  for (final entry in settingsSurfaces.entries) {
    testWidgets('real ${entry.key} preferences have nonempty reachable controls and readable theme', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = await mountVisualFixture(tester, child: entry.value);
      final rows = interactiveRows();
      expect(rows, findsWidgets, reason: 'Cannot pass with an empty interactive inventory');
      var measured = 0;
      final scroll = find.descendant(of: find.byType(entry.value.runtimeType), matching: find.byType(Scrollable)).first;
      for (var pass = 0; pass < 8; pass++) {
        for (final element in rows.evaluate().toList()) {
          final finder = find.byWidget(element.widget);
          if (finder.hitTestable().evaluate().isEmpty) continue;
          final size = tester.getSize(finder);
          expect(size.width, greaterThanOrEqualTo(44));
          expect(size.height, greaterThanOrEqualTo(44));
          measured++;
        }
        if (scroll.evaluate().isEmpty) break;
        final state = tester.state<ScrollableState>(scroll);
        if (state.position.pixels >= state.position.maxScrollExtent) break;
        await tester.drag(scroll, const Offset(0, -450));
        await tester.pumpAndSettle();
      }
      expect(measured, greaterThan(0));
      final state = tester.state<ScrollableState>(scroll);
      expect(state.position.extentAfter, lessThan(1), reason: 'Last actions must be reachable by scroll');
      final theme = fixture.innerTheme!;
      expect(contrastRatio(theme.colorScheme.onSurface, theme.colorScheme.surface), greaterThanOrEqualTo(4.5));
      expect(tester.takeException(), isNull);
      await fixture.close(tester);
    });
  }
  for (final state in ['loading', 'empty', 'error', 'data']) {
    final logsDescription = Platform.isIOS
        ? 'iOS safe diagnostics controls with legacy log override $state'
        : 'real logs $state retains visible noncolor state and controls';
    testWidgets(logsDescription, (tester) async {
      final logs = switch (state) {
        'loading' => const AsyncLoading<List<LogEntity>>(),
        'empty' => const AsyncData(<LogEntity>[]),
        'error' => AsyncError<List<LogEntity>>(StateError('Synthetic log error'), StackTrace.current),
        _ => const AsyncData([LogEntity(message: '00:00 INFO Synthetic diagnostic message')]),
      };
      final journal = Platform.isIOS ? SafeDiagnosticJournal() : null;
      if (journal != null) {
        journal.record(
          operation: DiagnosticOperation.connect,
          stage: DiagnosticStage.accepted,
          code: DiagnosticCode.started,
          operationId: journal.nextOperationId(),
        );
        addTearDown(journal.dispose);
      }
      final f = await home.mountHomeFixture(
        tester,
        child: const LogsPage(),
        extraOverrides: [
          logsOverviewNotifierProvider.overrideWith(() => SurfaceLogs(LogsOverviewState(logs: logs))),
          logPathResolverProvider.overrideWith((ref) => LogPathResolver(Directory.systemTemp)),
          if (journal != null) safeDiagnosticJournalProvider.overrideWithValue(journal),
        ],
      );
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(IconButton), findsWidgets);
      if (Platform.isIOS) {
        expect(find.byType(SafeDiagnosticsPage), findsOneWidget);
        expect(find.text('Safe diagnostics'), findsOneWidget);
        for (final key in const [
          Key('safe-diagnostics-send-test'),
          Key('safe-diagnostics-copy'),
          Key('safe-diagnostics-clear'),
        ]) {
          final action = find.byKey(key);
          expect(action, findsOneWidget);
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.getSize(action).shortestSide, greaterThanOrEqualTo(44));
        }
        expect(journal!.events, isNotEmpty);
        await tester.tap(find.byKey(const Key('safe-diagnostics-clear')));
        await tester.pump();
        await journal.flush();
        expect(journal.events, isEmpty);
        expect(find.text('No diagnostic events yet.'), findsOneWidget);
      } else {
        final dropdown = find.byWidgetPredicate((w) => w is DropdownButton);
        expect(dropdown, findsOneWidget);
        await tester.tap(dropdown);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byWidgetPredicate((w) => w is DropdownMenuItem), findsWidgets);
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(milliseconds: 400));
        if (state == 'data') expect(find.textContaining('Synthetic diagnostic', findRichText: true), findsOneWidget);
        if (state == 'loading') expect(find.byType(CircularProgressIndicator), findsOneWidget);
        if (state == 'error') expect(find.byType(SliverErrorBodyPlaceholder), findsOneWidget);
        if (state == 'empty') {
          expect(f.container.read(logsOverviewNotifierProvider).logs.requireValue, isEmpty);
          expect(find.textContaining('Synthetic diagnostic', findRichText: true), findsNothing);
          expect(find.byType(SliverErrorBodyPlaceholder), findsNothing);
          expect(find.byType(CircularProgressIndicator), findsNothing);
        }
      }
      expect(tester.takeException(), isNull);
      await f.close(tester);
    });
    testWidgets('real proxies $state retains sort and test actions', (tester) async {
      final error = StateError('Synthetic proxy error');
      final value = switch (state) {
        'loading' => const AsyncLoading<OutboundGroup?>(),
        'empty' => const AsyncData<OutboundGroup?>(null),
        'error' => AsyncError<OutboundGroup?>(error, StackTrace.current),
        _ => AsyncData<OutboundGroup?>(OutboundGroup(tag: 'select', items: [])),
      };
      final proxies = _SurfaceProxiesSpy(value);
      final f = await home.mountHomeFixture(
        tester,
        child: const ProxiesOverviewPage(),
        extraOverrides: [proxiesOverviewNotifierProvider.overrideWith(() => proxies)],
      );
      final blizzard = home.expectsBlizzard(AppThemeMode.dark, Brightness.dark, 393);
      final delayAction = find.byKey(const ValueKey('servers_test_delay_button'));
      if (blizzard) {
        expect(delayAction, findsOneWidget);
        expect(tester.getSize(delayAction).shortestSide, greaterThanOrEqualTo(44));
        if (state == 'data') {
          expect(find.text('Servers'), findsOneWidget);
          expect(find.textContaining('0 servers'), findsOneWidget);
          await tester.ensureVisible(delayAction);
        }
        expect(delayAction.hitTestable(), findsOneWidget);
        await tester.tap(delayAction);
        await tester.pump();
        expect(proxies.delayTests, ['select']);
      } else {
        final legacyAction = find.byType(FloatingActionButton);
        expect(legacyAction, findsOneWidget);
        expect(tester.getSize(legacyAction).shortestSide, greaterThanOrEqualTo(44));
        await tester.tap(legacyAction);
        await tester.pump();
        expect(proxies.delayTests, ['select']);
      }
      if (state == 'loading') expect(find.byType(CircularProgressIndicator), findsOneWidget);
      if (state == 'empty') {
        expect(find.text(f.container.read(translationsProvider).requireValue.pages.proxies.empty), findsOneWidget);
      }
      if (state == 'error') {
        expect(find.text(f.container.read(translationsProvider).requireValue.presentShortError(error)), findsOneWidget);
      }
      expect(find.byType(PopupMenuButton<ProxiesSort>), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton<ProxiesSort>));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PopupMenuItem<ProxiesSort>), findsNWidgets(ProxiesSort.values.length));
      expect(tester.takeException(), isNull);
      await f.close(tester);
    });
  }
  for (final state in ['loading', 'empty', 'error']) {
    testWidgets('Blizzard proxies $state keeps the delay action reachable', (tester) async {
      final error = StateError('Synthetic proxy error');
      final value = switch (state) {
        'loading' => const AsyncLoading<OutboundGroup?>(),
        'empty' => const AsyncData<OutboundGroup?>(null),
        _ => AsyncError<OutboundGroup?>(error, StackTrace.current),
      };
      final proxies = _SurfaceProxiesSpy(value);
      final f = await home.mountHomeFixture(
        tester,
        child: _appliedBlizzard(const ProxiesOverviewPage()),
        extraOverrides: [proxiesOverviewNotifierProvider.overrideWith(() => proxies)],
      );
      final delayAction = find.byKey(const ValueKey('servers_test_delay_button'));
      expect(delayAction, findsOneWidget);
      expect(tester.getSize(delayAction).shortestSide, greaterThanOrEqualTo(44));
      expect(delayAction.hitTestable(), findsOneWidget);
      await tester.tap(delayAction);
      await tester.pump();
      expect(proxies.delayTests, ['select']);
      if (state == 'loading') expect(find.byType(CircularProgressIndicator), findsOneWidget);
      if (state == 'empty') {
        expect(find.text(f.container.read(translationsProvider).requireValue.pages.proxies.empty), findsOneWidget);
      }
      if (state == 'error') {
        expect(find.text(f.container.read(translationsProvider).requireValue.presentShortError(error)), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await f.close(tester);
    });
  }
  testWidgets('real About information and action rows are rendered', (tester) async {
    final f = await home.mountHomeFixture(
      tester,
      child: const AboutPage(),
      extraOverrides: [appUpdateNotifierProvider.overrideWith(SurfaceAppUpdate.new)],
    );
    expect(find.byType(ListTile), findsWidgets);
    expect(interactiveRows(), findsWidgets);
    final menu = find.byWidgetPredicate((w) => w is PopupMenuButton);
    expect(menu, findsOneWidget);
    await tester.tap(menu);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byWidgetPredicate((w) => w is PopupMenuItem), findsWidgets);
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });

  for (final entry in dialogSurfaces.entries) {
    testWidgets('real ${entry.key} dialog has visible content and accessible action geometry', (tester) async {
      final f = await home.mountHomeFixture(tester, child: entry.value);
      expect(find.byType(AlertDialog), findsOneWidget);
      final actions = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton && w.onPressed != null),
      );
      expect(actions, findsWidgets);
      for (final element in actions.evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      expect(tester.takeException(), isNull);
      await f.close(tester);
    });
  }
  testWidgets('real QR output retains measurable code and textual label', (tester) async {
    final f = await home.mountHomeFixture(
      tester,
      child: const QrCodeDialog('https://example.invalid', message: 'Synthetic profile'),
    );
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.getSize(find.byType(QrImageView)).width, 268);
    expect(find.text('Synthetic profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });
  testWidgets('real Intro retains preference and start controls', (tester) async {
    IntroPage.locationInfoLoaded = true; // External IP geolocation excluded from renderer fixture.
    final f = await home.mountHomeFixture(tester, child: const IntroPage());
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(Text), findsWidgets);
    expect(tester.takeException(), isNull);
    await f.close(tester);
    IntroPage.locationInfoLoaded = false;
  });
  testWidgets('real Settings overview renders section navigation and overflow', (tester) async {
    final f = await home.mountHomeFixture(tester, child: SettingsPage());
    expect(find.byType(ListTile), findsWidgets);
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });

  testWidgets('real profile details renders draft fields and disabled save before changes', (tester) async {
    final f = await home.mountHomeFixture(
      tester,
      child: ProfileDetailsPage(id: connectionProfile.id),
      extraOverrides: [
        profileDetailsNotifierProvider(connectionProfile.id).overrideWith(
          () => SurfaceDetails(
            ProfileDetailsState(
              loadingState: const AsyncData(null),
              profile: connectionProfile,
              configContent: '{"outbounds":[]}',
              isDetailsChanged: false,
            ),
          ),
        ),
      ],
    );
    expect(find.byType(TextFormField), findsWidgets);
    final saves = tester.widgetList<ButtonStyleButton>(find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(saves.where((w) => w.onPressed == null), isNotEmpty);
    final layoutError = tester.takeException();
    if (expectsBlizzard(AppThemeMode.dark, Brightness.dark, 393)) {
      expect(layoutError, isNull);
    } else {
      // Baseline desktop JSON toolbar overflows in this phone-width host fixture.
      // Explicit characterization, not a claim of visual acceptance.
      expect(layoutError.toString(), contains('A RenderFlex overflowed'));
    }
    await f.close(tester);
  });
  testWidgets('real profiles sheet renders actual profile row and footer controls', (tester) async {
    final profiles = home.TileProfilesSpy()..profiles = [connectionProfile];
    final f = await home.mountHomeFixture(
      tester,
      child: const ProfilesModal(),
      extraOverrides: [profilesNotifierProvider.overrideWith(() => profiles)],
    );
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text(connectionProfile.name), findsWidgets);
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });

  testWidgets('real input modal focus enters field and traversal stays inside modal', (tester) async {
    final f = await home.mountHomeFixture(
      tester,
      child: SafeArea(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const SettingInputDialog<int>(
                title: 'Port',
                initialValue: 1080,
                mapTo: int.tryParse,
                digitsOnly: true,
              ),
            ),
            child: const Text('Open input'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open input'));
    await tester.pumpAndSettle();
    final input = tester.widget<EditableText>(find.byType(EditableText));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(input.focusNode.hasFocus, true);
    await tester.enterText(find.byType(TextField), '2080');
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focusContext = FocusManager.instance.primaryFocus!.context!;
      expect(
        focusContext.findAncestorWidgetOfExactType<AlertDialog>(),
        isNotNull,
        reason: 'Modal keyboard traversal must not enter underlying actions',
      );
    }
    expect(input.controller.text, '2080');
    await f.close(tester);
  });

  testWidgets('real input suggestions retain selection and use the scoped material', (tester) async {
    final f = await home.mountHomeFixture(
      tester,
      child: SafeArea(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const SettingInputDialog<String>(
                title: 'Synthetic choice',
                initialValue: 'One',
                possibleValues: ['One', 'Two'],
              ),
            ),
            child: const Text('Open suggestions'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open suggestions'));
    await tester.pumpAndSettle();
    expect(find.byType(TypeAheadField<String>), findsOneWidget);
    final controller = tester.widget<EditableText>(find.byType(EditableText)).controller;
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Two'), findsOneWidget);
    final material = tester.element(find.text('Two')).findAncestorWidgetOfExactType<Material>()!;
    if (home.expectsBlizzard(AppThemeMode.dark, Brightness.dark, 393)) {
      expect(material.color, const Color(0xFF102235));
      expect(material.borderRadius, BorderRadius.circular(12));
    } else {
      expect(material.color, isNull);
      expect(material.borderRadius, BorderRadius.circular(8));
    }
    await tester.tap(find.text('Two'));
    await tester.pump();
    expect(controller.text, 'Two');
    expect(identical(controller, tester.widget<EditableText>(find.byType(EditableText)).controller), isTrue);
    expect(f.events, isEmpty);
    expect(tester.takeException(), isNull);
    await f.close(tester);
  });

  testWidgets('scoped high contrast changes actual surface contrast and reduced motion configures dock', (
    tester,
  ) async {
    // Numeric behavioral acceptance is armed only on an actual iOS process.
    final normal = await mountVisualFixture(tester, child: settingsSurfaces['dns']!);
    final regularRatio = contrastRatio(
      normal.innerTheme!.colorScheme.onSurfaceVariant,
      normal.innerTheme!.colorScheme.surface,
    );
    await normal.close(tester);
    final accessible = await mountVisualFixture(
      tester,
      child: settingsSurfaces['dns']!,
      highContrast: true,
      disableAnimations: true,
    );
    if (expectsBlizzard(AppThemeMode.dark, Brightness.dark, 393)) {
      final ratio = contrastRatio(
        accessible.innerTheme!.colorScheme.onSurfaceVariant,
        accessible.innerTheme!.colorScheme.surface,
      );
      expect(ratio, greaterThan(regularRatio));
      expect(ratio, greaterThanOrEqualTo(7));
      // Material's internal AnimatedDefaultTextStyle retains its framework
      // theme duration even when destination selection is instantaneous.
      // Connection and destination transitions are exercised separately.
      final tab = find.byKey(const ValueKey('blizzard_bottom_dock_tab_0'));
      expect(
        tester.widget<AnimatedContainer>(find.descendant(of: tab, matching: find.byType(AnimatedContainer))),
        isA<AnimatedContainer>().having((widget) => widget.duration, 'duration', Duration.zero),
      );
    }
    await accessible.close(tester);
  });
}

class _SurfaceProxiesSpy extends SurfaceProxies {
  _SurfaceProxiesSpy(super.initial);

  final delayTests = <String>[];

  @override
  Future<void> urlTest(String groupTag) async {
    delayTests.add(groupTag);
  }
}
