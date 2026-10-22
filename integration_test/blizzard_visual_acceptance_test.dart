import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/widgets/quick_settings_modal.dart';
import 'package:hiddify/features/profile/add/add_profile_modal.dart';
import 'package:hiddify/features/profile/overview/profiles_modal.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_page.dart';
import 'package:hiddify/features/settings/overview/settings_page.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/blizzard_capture.dart';
import '../test/support/blizzard_visual_acceptance_fixture.dart';
import '../test/support/home_fixture.dart';
import '../test/support/surface_fixtures.dart';

const _captureMode = String.fromEnvironment('BLIZZARD_CAPTURE_MODE', defaultValue: 'smoke');
final _stageRunId = DateTime.now().microsecondsSinceEpoch.toRadixString(16);

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.runAsync(() => _waitForRunnerAck('capture', name, 'BLIZZARD_CAPTURE_READY'));
}

Future<void> _startVideo(WidgetTester tester, String name) async {
  await tester.runAsync(() => _waitForRunnerAck('video', name, 'BLIZZARD_VIDEO_START'));
}

Future<void> _waitForRunnerAck(String kind, String name, String marker) async {
  final ack = File('${Directory.systemTemp.path}/blizzard_${kind}_${name}_$_stageRunId.ack');
  if (await ack.exists()) await ack.delete();
  debugPrint('$marker $name $_stageRunId ${ack.path}');
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (!await ack.exists()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Timed out waiting for runner ack: $kind/$name');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  await ack.delete();
}

Future<void> _close(HomeFixture fixture, WidgetTester tester) async {
  await fixture.close(tester);
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
  await tester.pump();
}

int _pipelineSemanticsHandles(IntegrationTestWidgetsFlutterBinding binding) {
  // The leak assertion in WidgetTester still adds this deprecated counter to
  // the binding counter. Mirror that exact check while Flutter retains it.
  // ignore: deprecated_member_use
  return binding.pipelineOwner.debugOutstandingSemanticsHandles;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  late int setupBindingHandles;
  late int setupPipelineHandles;

  setUpAll(() async {
    // iOS may register a platform-owned accessibility client on the first live
    // frame. Warm it before testWidgets records its per-test leak baseline.
    runApp(const MaterialApp(home: SizedBox.shrink()));
    await binding.endOfFrame;
    await Future<void>.delayed(const Duration(seconds: 1));
    setupBindingHandles = binding.debugOutstandingSemanticsHandles;
    setupPipelineHandles = _pipelineSemanticsHandles(binding);
    debugPrint(
      'BLIZZARD_SEMANTICS setup platform=${binding.platformDispatcher.semanticsEnabled} '
      'binding=$setupBindingHandles pipeline=$setupPipelineHandles',
    );
  });

  testWidgets('native Blizzard visual acceptance capture', (tester) async {
    expect(Platform.isIOS, isTrue, reason: 'Requires an actual iOS process');
    expect(_pipelineSemanticsHandles(binding), setupPipelineHandles);
    final viewport = tester.view.physicalSize / tester.view.devicePixelRatio;
    if (_captureMode == 'full') {
      expect(viewport.width, closeTo(393, .01));
      expect(viewport.height, closeTo(852, .01));
    }
    debugPrint(
      'BLIZZARD_SEMANTICS before platform=${binding.platformDispatcher.semanticsEnabled} '
      'binding=${binding.debugOutstandingSemanticsHandles} '
      'pipeline=${_pipelineSemanticsHandles(binding)}',
    );
    final testBaselineBindingHandles = binding.debugOutstandingSemanticsHandles;

    var fixture = await mountHomeFixture(
      tester,
      profile: blizzardVisualAcceptanceProfile,
      locale: AppLocale.ru,
      width: viewport.width,
      height: viewport.height,
      nativeViewport: true,
      extraOverrides: blizzardVisualAcceptanceOverrides,
    );
    expect(tester.binding.renderViews.single.size, viewport);
    expect(tester.getSize(find.byKey(blizzardFixtureCanvas)), viewport);
    expect(find.text('0.0.1 (22)'), findsOneWidget);
    expect(find.text('Akonit Premium'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data?.replaceAll(RegExp('[\u2066\u2069]'), '') == '∞ GiB · осталось 169 дней',
      ),
      findsOneWidget,
    );
    expect(find.text('VPN подключён'), findsOneWidget);
    expect(find.text('Задержка 84 мс'), findsOneWidget);
    expect(find.text('Финляндия'), findsOneWidget);
    expect(find.text('Вьюга 1G · VLESS'), findsOneWidget);
    final proxy = await fixture.container.read(activeProxyNotifierProvider.future);
    expect(proxy.tagDisplay, 'Финляндия');
    expect(proxy.type, 'VLESS');
    expect(proxy.urlTestDelay, 84);
    expect(proxy.ipinfo.countryCode, 'FI');

    if (_captureMode == 'full') {
      await _capture(tester, 'home_initial');
      await _startVideo(tester, 'home_loop_16s');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 16500)));
      await _capture(tester, 'home_loop_16s');
      debugPrint('BLIZZARD_VIDEO_END home_loop_16s');
    }
    await _close(fixture, tester);

    if (_captureMode == 'full') {
      fixture = await mountHomeFixture(
        tester,
        profile: blizzardVisualAcceptanceProfile,
        locale: AppLocale.ru,
        width: viewport.width,
        height: viewport.height,
        nativeViewport: true,
        extraOverrides: blizzardVisualAcceptanceOverrides,
        settingsChild: SettingsPage(),
      );
      await tester.tap(find.byKey(const ValueKey('blizzard_bottom_dock_tab_1')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SettingsPage), findsOneWidget);
      await _capture(tester, 'settings');
      await _close(fixture, tester);

      final group = OutboundGroup(
        tag: 'select',
        selected: 'finland-vless',
        items: [
          OutboundInfo(
            tag: 'finland-vless',
            tagDisplay: 'Финляндия',
            groupSelectedTagDisplay: 'Вьюга 1G',
            type: 'VLESS',
            urlTestDelay: 84,
            ipinfo: IpInfo(ip: '192.0.2.84', countryCode: 'FI'),
          ),
          OutboundInfo(
            tag: 'finland-vless-long',
            tagDisplay: 'Finland • Helsinki • Long synthetic server name',
            type: 'VLESS',
            urlTestDelay: 65001,
          ),
        ],
      );
      fixture = await mountHomeFixture(
        tester,
        profile: blizzardVisualAcceptanceProfile,
        locale: AppLocale.ru,
        width: viewport.width,
        height: viewport.height,
        nativeViewport: true,
        proxiesChild: const ProxiesOverviewPage(),
        extraOverrides: [
          ...blizzardVisualAcceptanceOverrides,
          proxiesOverviewNotifierProvider.overrideWith(() => SurfaceProxies(AsyncData(group))),
        ],
      );
      await tester.tap(find.byType(ActiveProxyFooter));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(ProxiesOverviewPage), findsOneWidget);
      expect(find.text('Финляндия'), findsOneWidget);
      await _capture(tester, 'servers');
      await _close(fixture, tester);

      final profiles = TileProfilesSpy()..profiles = [blizzardVisualAcceptanceProfile];
      fixture = await mountHomeFixture(
        tester,
        profile: blizzardVisualAcceptanceProfile,
        locale: AppLocale.ru,
        width: viewport.width,
        height: viewport.height,
        nativeViewport: true,
        extraOverrides: [...blizzardVisualAcceptanceOverrides, profilesNotifierProvider.overrideWith(() => profiles)],
      );
      await tester.tap(find.byType(ProfileTile));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(ProfilesModal), findsOneWidget);
      expect(find.text('Akonit Premium'), findsWidgets);
      await _capture(tester, 'profiles');
      await _close(fixture, tester);

      fixture = await mountHomeFixture(
        tester,
        profile: blizzardVisualAcceptanceProfile,
        locale: AppLocale.ru,
        width: viewport.width,
        height: viewport.height,
        nativeViewport: true,
        extraOverrides: blizzardVisualAcceptanceOverrides,
      );
      await tester.tap(find.byKey(const ValueKey('profile_add_button')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(AddProfileModal), findsOneWidget);
      await _capture(tester, 'add_profile');
      await _close(fixture, tester);

      fixture = await mountHomeFixture(
        tester,
        profile: blizzardVisualAcceptanceProfile,
        locale: AppLocale.ru,
        width: viewport.width,
        height: viewport.height,
        nativeViewport: true,
        extraOverrides: blizzardVisualAcceptanceOverrides,
      );
      await tester.tap(find.byKey(const ValueKey('profile_quick_settings')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(QuickSettingsModal), findsOneWidget);
      await _capture(tester, 'quick_settings');
      await _close(fixture, tester);

      fixture = await mountHomeFixture(
        tester,
        profile: blizzardVisualAcceptanceProfile,
        locale: AppLocale.ru,
        width: viewport.width,
        height: viewport.height,
        nativeViewport: true,
        extraOverrides: blizzardVisualAcceptanceOverrides,
        settingsChild: SettingsPage(),
      );
      await _startVideo(tester, 'lifecycle_tab_return');
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await _capture(tester, 'lifecycle_return');
      await tester.tap(find.byKey(const ValueKey('blizzard_bottom_dock_tab_1')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SettingsPage), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('blizzard_bottom_dock_tab_0')));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Akonit Premium'), findsWidgets);
      await _capture(tester, 'tab_return');
      debugPrint('BLIZZARD_VIDEO_END lifecycle_tab_return');
      await _close(fixture, tester);
    }

    debugPrint(
      'BLIZZARD_SEMANTICS closed platform=${binding.platformDispatcher.semanticsEnabled} '
      'binding=${binding.debugOutstandingSemanticsHandles} '
      'pipeline=${_pipelineSemanticsHandles(binding)}',
    );
    expect(binding.debugOutstandingSemanticsHandles, testBaselineBindingHandles);
    expect(_pipelineSemanticsHandles(binding), setupPipelineHandles);
    expect(tester.takeException(), isNull);
  });
}
