import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'config_controller.g.dart';

@Riverpod(keepAlive: true)
class ConfigController extends _$ConfigController {
  static const _key = 'hiddify_configs';

  @override
  FutureOr<List<Config>> build() async {
    try {
      final prefs = await ref.watch(sharedPreferencesProvider.future);
      final list = prefs.getStringList(_key) ?? [];
      Logger.config.debug('Loaded ${list.length} configs from storage');
      if (list.isEmpty) return [];
      return await compute(_parseConfigs, list);
    } catch (e, stack) {
      Logger.config.error('Failed to load configs', e, stack);
      return [];
    }
  }

  Future<void> add(Config config) async {
    Logger.config.info('Adding config: ${config.name} (${config.type})');
    final current = state.asData?.value ?? [];
    state = AsyncValue.data([...current, config]);
    await _save();
  }

  Future<void> addAll(Iterable<Config> configs) async {
    final list = configs.toList();
    if (list.isEmpty) return;

    final current = state.asData?.value ?? [];
    final existingContents = current.map((e) => e.content).toSet();
    final uniqueToAdd = list
        .where((c) => !existingContents.contains(c.content))
        .toList();
    if (uniqueToAdd.isEmpty) return;

    Logger.config.info('Adding ${uniqueToAdd.length} configs');
    state = AsyncValue.data([...current, ...uniqueToAdd]);
    await _save();
  }

  Future<void> remove(String id) async {
    Logger.config.info('Removing config: $id');
    final current = state.asData?.value ?? [];
    state = AsyncValue.data(current.where((c) => c.id != id).toList());
    await _save();
  }

  Future<void> select(String id) async {
    Logger.config.info('Selecting config: $id');
    final current = state.asData?.value ?? [];
    final index = current.indexWhere((c) => c.id == id);
    if (index != -1) {
    final config = current[index];
      final newList = List<Config>.from(current)
        ..removeAt(index)
        ..insert(0, config);
      state = AsyncValue.data(newList);
      await _save();
    }
  }

  Future<void> updateConfig(Config config) async {
    Logger.config.info('Updating config: ${config.id}');
    final current = state.asData?.value ?? [];
    final index = current.indexWhere((c) => c.id == config.id);
    if (index != -1) {
      final newList = List<Config>.from(current)..[index] = config;
      state = AsyncValue.data(newList);
      await _save();
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final current = state.asData?.value ?? [];
      if (current.isEmpty) {
        await prefs.setStringList(_key, []);
        Logger.storage.debug('Cleared configs in storage');
        return;
      }
      final payload = current.map((e) => e.toJson()).toList();
      final list = await compute(_encodeConfigs, payload);
      await prefs.setStringList(_key, list);
      Logger.storage.debug('Saved ${list.length} configs to storage');
    } catch (e, stack) {
      Logger.storage.error('Failed to save configs', e, stack);
    }
  }
}

List<Config> _parseConfigs(List<String> list) {
  final configs = <Config>[];
  for (final e in list) {
    try {
      final json = jsonDecode(e);
      if (json is Map<String, dynamic>) {
        configs.add(Config.fromJson(json));
      }
    } catch (_) {
      // Ignore malformed configs
    }
  }
  return configs;
}

List<String> _encodeConfigs(List<Map<String, dynamic>> configsJson) =>
    configsJson.map((e) => jsonEncode(e)).toList();
