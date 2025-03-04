import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:json_path/json_path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'config_option_notifier.g.dart';

@Riverpod(keepAlive: true)
class ConfigOptionNotifier extends _$ConfigOptionNotifier with AppLogger {
  @override
  Future<bool> build() async {
    final serviceRunning = await ref.watch(serviceRunningProvider.future);
    final serviceSingboxOptions = ref.read(connectionRepositoryProvider).configOptionsSnapshot;
    ref.listen(
      ConfigOptions.singboxConfigOptions,
      (previous, next) async {
        if (!serviceRunning || serviceSingboxOptions == null) return;
        if (next case AsyncData(:final value) when next != previous) {
          if (_lastUpdate == null || DateTime.now().difference(_lastUpdate!) > const Duration(milliseconds: 100)) {
            _lastUpdate = DateTime.now();
            state = AsyncData(value != serviceSingboxOptions);
          }
        }
      },
      fireImmediately: true,
    );
    return false;
  }

  DateTime? _lastUpdate;

  Future<String?> _exportJson(bool excludePrivate) async {
    try {
      final options = await ref.read(ConfigOptions.singboxConfigOptions.future);
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
      return encoder.convert(map);
    } catch (e, st) {
      loggy.warning("error creating config options json", e, st);
      return null;
    }
  }

  Future<bool> exportJsonClipboard({bool excludePrivate = true}) async {
    try {
      final json = await _exportJson(excludePrivate);
      if (json == null) return false;
      await Clipboard.setData(ClipboardData(text: json));
      return true;
    } catch (e, st) {
      loggy.warning("error exporting config options to clipboard", e, st);
      return false;
    }
  }

  Future<bool> exportJsonFile({bool excludePrivate = true}) async {
    try {
      final json = await _exportJson(excludePrivate);
      if (json == null) return false;
      final bytes = utf8.encode(json);
      final outputFile = await FilePicker.platform.saveFile(
        fileName: 'options.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (outputFile == null) return false;
      if (PlatformUtils.isDesktop) {
        final file = File(outputFile);
        if (file.extension != '.json') return false;
        if (!await file.exists()) await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
      }
      return true;
    } catch (e, st) {
      loggy.warning("error exporting config options to json file", e, st);
      return false;
    }
  }

  Future<bool> _importJson(String input) async {
    try {
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
      loggy.warning("error importing config options from input", e, st);
      return false;
    }
  }

  Future<bool> importFromClipboard() async {
    try {
      final input = await Clipboard.getData(Clipboard.kTextPlain).then((value) => value?.text);
      if (input == null) return false;
      return await _importJson(input);
    } catch (e, st) {
      loggy.warning("error importing config options from clipboard", e, st);
      return false;
    }
  }

  Future<bool> importFromJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null) return false;
      final file = File(result.files.single.path!);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      return await _importJson(utf8.decode(bytes));
    } catch (e, st) {
      loggy.warning("error importing config options from json file", e, st);
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
