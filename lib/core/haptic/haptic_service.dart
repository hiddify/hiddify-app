import 'package:flutter/services.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'haptic_service.g.dart';

@Riverpod(keepAlive: true)
class HapticService extends _$HapticService {
  @override
  bool build() {
    return _preferences.getBool(hapticFeedbackPrefKey) ?? true;
  }

  static const String hapticFeedbackPrefKey = "haptic_feedback";
  SharedPreferences get _preferences =>
      ref.read(sharedPreferencesProvider).requireValue;

  Future<void> updatePreference(bool value) async {
    state = value;
    await _preferences.setBool(hapticFeedbackPrefKey, value);
  }

  Future<void> lightImpact() async {
    if (state) {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> mediumImpact() async {
    if (state) {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> heavyImpact() async {
    if (state) {
      await HapticFeedback.heavyImpact();
    }
  }
}
