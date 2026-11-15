import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/router/go_router/go_router_notifier.dart';
import 'package:hiddify/features/intro/widget/intro_page.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The first-start screen guesses the region from the time zone; these hold whatever it guessed,
/// so they pass in any TZ (run with TZ=Asia/Tehran to start from Iran and Persian).
void main() {
  late ProviderContainer container;

  setUp(() async {
    IntroPage.resetForTest();
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
    await container.read(sharedPreferencesProvider.future);
    await container.read(translationsProvider.future);
    await container.read(analyticsControllerProvider.future);
  });
  tearDown(() => container.dispose());

  Translations t() => container.read(translationsProvider).requireValue;
  Region region() => container.read(ConfigOptions.region);

  // pumpAndSettle would wait on real futures (the translations) that fake time never completes
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            navigatorKey: rootNavKey,
            routes: [GoRoute(path: '/', builder: (_, _) => const IntroPage())],
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> pick(WidgetTester tester, String tile, String choice) async {
    await tester.tap(find.text(tile));
    await settle(tester);
    await tester.tap(find.text(choice).last);
    await settle(tester);
  }

  Future<void> pickRegion(WidgetTester tester, Region r) =>
      pick(tester, t().pages.settings.routing.region, r.present(t()));
  Future<void> pickLanguage(WidgetTester tester, AppLocale l) =>
      pick(tester, t().pages.settings.general.locale, l.localeName);

  testWidgets('the region can be changed after the time zone picked one', (tester) async {
    await show(tester);
    final other = region() == Region.cn ? Region.tr : Region.cn;
    await pickRegion(tester, other);
    expect(region(), other);
  });

  testWidgets('picking Persian sets Iran', (tester) async {
    await show(tester);
    await pickLanguage(tester, AppLocale.ru);
    await pickLanguage(tester, AppLocale.fa);
    expect(region(), Region.ir);
  });

  testWidgets('the language replaces a region guessed from the time zone', (tester) async {
    await show(tester);
    await pickLanguage(tester, AppLocale.zhCn);
    expect(region(), Region.cn);
  });

  testWidgets('a region the user picked stays when the language changes', (tester) async {
    await show(tester);
    await pickRegion(tester, Region.tr);
    await pickLanguage(tester, AppLocale.fa);
    expect(region(), Region.tr);
  });

  test('a language spoken in no listed region leaves the region alone; Persian keeps Afghanistan', () {
    expect(IntroPage.regionForLocale(AppLocale.en, Region.ir), isNull);
    expect(IntroPage.regionForLocale(AppLocale.fa, Region.af), Region.af);
    expect(IntroPage.regionForLocale(AppLocale.fa, Region.other), Region.ir);
    expect(IntroPage.regionForLocale(AppLocale.ptBr, Region.other), Region.br);
  });
}
