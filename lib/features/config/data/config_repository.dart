import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/config.dart';

part 'config_repository.g.dart';

@Riverpod(keepAlive: true)
Future<ConfigRepository> configRepository(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return ConfigRepository(prefs);
}

class ConfigRepository {
  final SharedPreferences _prefs;
  static const _key = 'hiddify_configs';

  ConfigRepository(this._prefs);

  List<Config> getConfigs() {
    final list = _prefs.getStringList(_key) ?? [];
    return list.map((e) => Config.fromJson(Map<String, dynamic>.from(jsonDecode(e) as Map))).toList();
  }

  Future<void> addConfig(Config config) async {
    final configs = getConfigs();
    configs.add(config);
    await _saveConfigs(configs);
  }
  
  Future<void> removeConfig(String id) async {
    final configs = getConfigs();
    configs.removeWhere((c) => c.id == id);
    await _saveConfigs(configs);
  }

  Future<void> _saveConfigs(List<Config> configs) async {
    final list = configs.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_key, list);
  }
}
