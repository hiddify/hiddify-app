import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:json_path/json_path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'config_option_notifier.g.dart';

@Riverpod(keepAlive: true)
class ConfigOptionNotifier extends _$ConfigOptionNotifier with AppLogger {
  @override
  Future<bool> build() async {
    final serviceRunning = await ref.watch(serviceRunningProvider.future);
    final serviceSingboxOptions = ref
        .read(connectionRepositoryProvider)
        .configOptionsSnapshot;
    ref.listen(singboxConfigOptionProvider, (previous, next) {
      if (!serviceRunning || serviceSingboxOptions == null) return;
      if (next case AsyncData(:final value) when next != previous) {
        if (_lastUpdate == null ||
            DateTime.now().difference(_lastUpdate!) >
                const Duration(milliseconds: 100)) {
          _lastUpdate = DateTime.now();
          state = AsyncData(value != serviceSingboxOptions);
        }
      }
    }, fireImmediately: true);
    return false;
  }

  DateTime? _lastUpdate;

  Future<bool> exportJsonToClipboard({bool excludePrivate = true}) async {
    try {
      final options = await ref.read(singboxConfigOptionProvider.future);
      Map map = options.toJson();
      if (excludePrivate) {
        for (final key in ConfigOptions.privatePreferencesKeys) {
          final query = key.split('.').map((e) => '["$e"]').join();
          final res = JsonPath('\$$query').read(map).firstOrNull;
          if (res != null) {
            map = res.pointer.remove(map)! as Map;
          }
        }
      }

      const encoder = JsonEncoder.withIndent('  ');
      final json = encoder.convert(map);
      await Clipboard.setData(ClipboardData(text: json));
      return true;
    } catch (e, st) {
      loggy.warning("error exporting config options to clipboard", e, st);
      return false;
    }
  }

  Future<bool> importFromClipboard() async {
    try {
      final input = await Clipboard.getData(
        "text/plain",
      ).then((value) => value?.text);
      if (input == null) return false;
      if (jsonDecode(input) case final Map<String, dynamic> map) {
        for (final option in ConfigOptions.preferences.entries) {
          final query = option.key.split('.').map((e) => '["$e"]').join();
          final res = JsonPath('\$$query').read(map).firstOrNull;
          if (res?.value case final value?) {
            try {
              await ref.read(option.value.notifier).updateRaw(value);
            } catch (e) {
              loggy.debug("error updating [${option.key}]: $e", e);
            }
          }
        }
      }
      return true;
    } catch (e, st) {
      loggy.warning("error importing config options to clipboard", e, st);
      return false;
    }
  }

  Future<void> resetOption() async {
    for (final option in ConfigOptions.preferences.values) {
      await ref.read(option.notifier).reset();
    }
    ref.invalidateSelf();
  }
}
