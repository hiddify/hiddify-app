import 'package:flutter/material.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_preferences.g.dart';

abstract class AppPreferences {
  static final locale = PreferencesNotifier.create<String, String>(
    'app_locale',
    'fa', 
  );

  static final themeMode = PreferencesNotifier.create<ThemeMode, String>(
    'app_theme_mode',
    ThemeMode.system,
    mapFrom: _themeModeFromString,
    mapTo: _themeModeToString,
  );

  static final fontScale = PreferencesNotifier.create<double, double>(
    'app_font_scale',
    1,
  );

  static final hapticFeedback = PreferencesNotifier.create<bool, bool>(
    'app_haptic_feedback',
    true,
  );
}

ThemeMode _themeModeFromString(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String _themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

enum AppLocale {
  system('system', 'سیستم'),
  fa('fa', 'فارسی'),
  en('en', 'English');

  const AppLocale(this.code, this.displayName);
  final String code;
  final String displayName;

  static AppLocale fromCode(String code) => AppLocale.values.firstWhere(
    (l) => l.code == code,
    orElse: () => AppLocale.fa,
  );
}

@Riverpod(keepAlive: true)
class AppLocaleNotifier extends _$AppLocaleNotifier {
  late final _pref = PreferencesEntry<String, String>(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: 'app_locale',
    defaultValue: 'fa',
  );

  @override
  AppLocale build() => AppLocale.fromCode(_pref.read());

  Future<void> update(AppLocale locale) {
    state = locale;
    return _pref.write(locale.code);
  }
}

@Riverpod(keepAlive: true)
class AppThemeModeNotifier extends _$AppThemeModeNotifier {
  late final _pref = PreferencesEntry<String, String>(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: 'app_theme_mode',
    defaultValue: 'system',
  );

  @override
  ThemeMode build() => _themeModeFromString(_pref.read());

  Future<void> update(ThemeMode mode) {
    state = mode;
    return _pref.write(_themeModeToString(mode));
  }
}

@Riverpod(keepAlive: true)
class AppFontScaleNotifier extends _$AppFontScaleNotifier {
  late final _pref = PreferencesEntry<double, double>(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: 'app_font_scale',
    defaultValue: 1,
  );

  @override
  double build() => _pref.read();

  Future<void> update(double scale) {
    state = scale.clamp(0.8, 1.4);
    return _pref.write(state);
  }
}
