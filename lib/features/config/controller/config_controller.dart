import 'dart:convert';

import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'config_controller.g.dart';

@Riverpod(keepAlive: true)
class ConfigController extends _$ConfigController {
  static const _key = 'hiddify_configs';

  @override
  FutureOr<List<Config>> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => Config.fromJson(Map<String, dynamic>.from(jsonDecode(e) as Map))).toList();
  }

  Future<void> add(Config config) async {
    final current = state.asData?.value ?? [];
    state = AsyncValue.data([...current, config]);
    await _save();
  }

  Future<void> remove(String id) async {
    final current = state.asData?.value ?? [];
    state = AsyncValue.data(current.where((c) => c.id != id).toList());
    await _save();
  }

  Future<void> select(String id) async {
    final current = state.asData?.value ?? [];
    final index = current.indexWhere((c) => c.id == id);
    if (index != -1) {
      final config = current[index];
      final newList = List<Config>.from(current)..removeAt(index)..insert(0, config);
      state = AsyncValue.data(newList);
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final current = state.asData?.value ?? [];
    final list = current.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, list);
  }
}
