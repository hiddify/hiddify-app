import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/widget/warp_hop_options.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;
  late Translations t;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(overrides: [translationsProvider.overrideWith((ref) => AppLocale.en.build())]);
    await container.read(sharedPreferencesProvider.future);
    t = await container.read(translationsProvider.future);
  });
  tearDown(() => container.dispose());

  Future<void> show(WidgetTester tester, WarpHopPreferences hop) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: WarpHopOptions(hop))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('extra security offers the tunnel, the licence and the MTU only', (tester) async {
    await show(tester, ConfigOptions.extraSecurityWarp);
    final warp = t.pages.settings.chain.warp;
    for (final title in [warp.tunnel, warp.licenseKey, warp.mtu]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    for (final title in [warp.endpoint, warp.noise.title, warp.scanner.title, warp.masque.title, warp.awg.title]) {
      expect(find.text(title), findsNothing, reason: title);
    }
  });

  testWidgets('the unblocker keeps its endpoint, scanner, noise and tunnel settings', (tester) async {
    await show(tester, ConfigOptions.unblockerWarp);
    final warp = t.pages.settings.chain.warp;
    for (final title in [
      warp.tunnel,
      warp.licenseKey,
      warp.endpoint,
      warp.mtu,
      warp.scanner.title,
      warp.noise.title,
      warp.masque.title,
      warp.awg.title,
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });
}
