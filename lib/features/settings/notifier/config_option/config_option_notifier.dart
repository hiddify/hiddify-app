import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:json_path/json_path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'config_option_notifier.g.dart';

@Riverpod(keepAlive: true)
class ConfigOptionNotifier extends _$ConfigOptionNotifier with AppLogger {
  @override
  Future<bool> build() async {
    final serviceRunning = ref.watch(serviceRunningProvider);

    ref.listen(ConfigOptions.singboxConfigOptions, (previous, next) async {
      if (!serviceRunning || previous == null) return;
      // Read on every change: a hot reload keeps the status connected, so this
      // notifier is not rebuilt, and a snapshot taken in build would go stale.
      final serviceSingboxOptions = ref.read(connectionRepositoryProvider).configOptionsSnapshot;
      if (next != previous && next != serviceSingboxOptions) {
        if (_lastUpdate == null || DateTime.now().difference(_lastUpdate!) > const Duration(milliseconds: 100)) {
          _lastUpdate = DateTime.now();
          // router mode readies the system (IP forwarding) only when the core starts, so a change
          // between it and VPN mode, the same TUN, is a reconnect too, never a hot reload
          if (serviceSingboxOptions?.enableTun != next.enableTun ||
              serviceSingboxOptions?.routerMode != next.routerMode) {
            loggy.debug("tun or router mode changed, reconnecting");
            final connection = ref.read(connectionNotifierProvider.notifier);
            await connection.toggleConnection();
            // The first toggle returns when the stop is sent; the status becomes Disconnected a
            // little later, through the status stream. A toggle before that finds Disconnecting
            // and does nothing, so the connection never came back: on Windows and Linux, where
            // the stop also tears down the admin service, VPN ↔ proxy modes always lost that race.
            await _untilDisconnected();
            await connection.toggleConnection();
          } else {
            final activeProfile = await ref.read(activeProfileProvider.future);
            return await ref.read(connectionNotifierProvider.notifier).reconnect(activeProfile);
          }
          state = const AsyncData(false);
        }
      }
    }, fireImmediately: true);
    return false;
  }

  DateTime? _lastUpdate;

  /// Waits for the connection to report Disconnected (or a failure), at most [_stopWait].
  Future<void> _untilDisconnected() async {
    final deadline = DateTime.now().add(_stopWait);
    while (DateTime.now().isBefore(deadline)) {
      final status = ref.read(connectionNotifierProvider);
      if (status is AsyncError || status.valueOrNull is Disconnected) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    loggy.warning("the core did not report disconnected within $_stopWait; connecting anyway");
  }

  /// Longer than the stop's own bounds (12 s for a managed core), so a stop that gives up still
  /// reports first.
  static const _stopWait = Duration(seconds: 15);

  Future<String?> _exportJson(bool excludePrivate) async {
    try {
      final options = ref.read(ConfigOptions.singboxConfigOptions);
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
    final t = ref.read(translationsProvider).requireValue;
    try {
      final json = await _exportJson(excludePrivate);
      if (json == null) return false;
      await Clipboard.setData(ClipboardData(text: json));
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.export.clipboard.success);
      return true;
    } on PlatformException {
      ref.read(inAppNotificationControllerProvider).showInfoToast(t.common.msg.export.clipboard.contentTooLarge);
      return false;
    } catch (e, st) {
      loggy.warning("error exporting config options to clipboard", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.export.clipboard.failure);
      return false;
    }
  }

  Future<bool> exportJsonFile({bool excludePrivate = true}) async {
    final t = ref.read(translationsProvider).requireValue;
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
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.export.file.success);
      return true;
    } catch (e, st) {
      loggy.warning("error exporting config options to json file", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.export.file.failure);
      return false;
    }
  }

  Future<void> _importJson(String input) async {
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
  }

  Future<bool> importFromClipboard() async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final input = await Clipboard.getData(Clipboard.kTextPlain).then((value) => value?.text);
      if (input == null) return false;
      await _importJson(input);
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.import.success);
      return true;
    } catch (e, st) {
      loggy.warning("error importing config options from clipboard", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.import.failure);
      return false;
    }
  }

  Future<bool> importFromJsonFile() async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null) return false;
      final file = File(result.files.single.path!);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      await _importJson(utf8.decode(bytes));
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.import.success);
      return true;
    } catch (e, st) {
      loggy.warning("error importing config options from json file", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.import.failure);
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
