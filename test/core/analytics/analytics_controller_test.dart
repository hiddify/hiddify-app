import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('analytics is disabled on a fresh install', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    expect(readAnalyticsEnabled(preferences), isFalse);
  });

  test('analytics keeps an explicit user choice', () async {
    SharedPreferences.setMockInitialValues({enableAnalyticsPrefKey: true});
    final preferences = await SharedPreferences.getInstance();

    expect(readAnalyticsEnabled(preferences), isTrue);
  });

  test('analytics keeps an explicit opt-out', () async {
    SharedPreferences.setMockInitialValues({enableAnalyticsPrefKey: false});
    final preferences = await SharedPreferences.getInstance();

    expect(readAnalyticsEnabled(preferences), isFalse);
  });
}
