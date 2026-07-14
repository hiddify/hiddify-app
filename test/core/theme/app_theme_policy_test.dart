import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/app_theme_policy.dart';

void main() {
  test('ships Woman in Red as dark-only without an appearance picker', () {
    expect(AppThemePolicy.themeMode, ThemeMode.dark);
    expect(AppThemePolicy.showAppearancePicker, isFalse);
  });

  test('uses the iOS dark status-bar appearance contract at the app root', () {
    final appSource = File('lib/features/app/widget/app.dart').readAsStringSync();

    expect(appSource, contains('statusBarBrightness: Brightness.dark'));
  });
}
