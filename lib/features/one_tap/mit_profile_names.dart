import 'dart:convert';

import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const mitProfileNamesKey = 'mit_profile_names';

bool validMitProfileName(String value) => value.trim().length <= 60 &&
    !RegExp(r'[\x00-\x1F\x7F]').hasMatch(value);

class MitProfileNames extends StateNotifier<Map<String, String>> {
  MitProfileNames(this.preferences) : super(_read(preferences));
  final SharedPreferences? preferences;
  static Map<String, String> _read(SharedPreferences? preferences) {
    try {
      final raw = preferences?.getString(mitProfileNamesKey);
      if (raw == null || raw.length > 65536) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return Map.unmodifiable({for (final entry in decoded.entries)
        if (entry.key is String && entry.value is String && validMitProfileName(entry.value as String) &&
            (entry.value as String).trim().isNotEmpty) (entry.key as String): (entry.value as String).trim()});
    } catch (_) { return {}; }
  }
  Future<void> rename(String id, String name) async {
    if (!validMitProfileName(name) || preferences == null) throw const FormatException('Не удалось сохранить название.');
    final next = {...state};
    if (name.trim().isEmpty) { next.remove(id); } else { next[id] = name.trim(); }
    // Do not use the generic preference logger for user-entered profile names.
    if (!await preferences!.setString(mitProfileNamesKey, jsonEncode(next))) throw StateError('name storage failed');
    state = Map.unmodifiable(next);
  }
}

final mitProfileNamesProvider = StateNotifierProvider<MitProfileNames, Map<String, String>>((ref) =>
  MitProfileNames(ref.watch(sharedPreferencesProvider).valueOrNull));

List<String> moveMitBackup(List<String> ids, String id, int direction) {
  final next = [...ids]; final index = next.indexOf(id); final target = index + direction;
  if (index < 0 || target < 0 || target >= next.length || direction.abs() != 1) return next;
  next.removeAt(index); next.insert(target, id); return next;
}
