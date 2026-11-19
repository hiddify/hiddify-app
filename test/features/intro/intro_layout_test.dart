import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/router/go_router/go_router_notifier.dart';
import 'package:hiddify/features/intro/widget/intro_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Start button never lies over the page: on Android 7 (360x640 dp) the floating button
/// covered the footer text, which the page could only be scrolled clear of by hand.
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

  // pumpAndSettle would wait on real futures (the translations) that fake time never completes
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> show(WidgetTester tester, Size size, double pixelRatio) async {
    tester.view.physicalSize = size * pixelRatio;
    tester.view.devicePixelRatio = pixelRatio;
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

  for (final (name, size, ratio) in [
    ('Android 7 phone', const Size(360, 640), 2.0),
    ('desktop window', const Size(1000, 700), 1.0),
  ]) {
    testWidgets('the Start button does not cover the page on a $name', (tester) async {
      await show(tester, size, ratio);
      final button = tester.getRect(find.byType(FloatingActionButton));
      final page = tester.getRect(find.byType(SingleChildScrollView));
      expect(button.overlaps(page), isFalse, reason: 'button $button lies over the page $page');
      expect(button.bottom, lessThanOrEqualTo(size.height));
      // it stays at the end, where it was
      expect(button.right, closeTo(size.width - 16, 1));
    });
  }
}
