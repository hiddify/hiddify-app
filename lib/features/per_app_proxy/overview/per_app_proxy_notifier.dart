import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/per_app_proxy/data/auto_selection_data_provider.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/utils/utils.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:installed_apps/index.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'per_app_proxy_notifier.g.dart';

@riverpod
Future<List<AppInfo>> apps(Ref ref) async => PlatformUtils.isAndroid ? await InstalledApps.getInstalledApps(false, true) : [];

@riverpod
Future<List<AppInfo>> appsHideSystem(Ref ref) async => PlatformUtils.isAndroid ? await InstalledApps.getInstalledApps(true, true) : [];

@Riverpod(keepAlive: true)
class SelectedAppsFilteredByMode extends _$SelectedAppsFilteredByMode with AppLogger {
  late final _include = PreferencesEntry(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: "per_app_proxy_include_list",
    defaultValue: <String>[],
  );

  late final _exclude = PreferencesEntry(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: "per_app_proxy_exclude_list",
    defaultValue: <String>[],
  );

  @override
  List<String> build() => ref.watch(Preferences.perAppProxyMode) == PerAppProxyMode.include ? _include.read() : _exclude.read();

  Future<void> update(List<String> value) {
    state = value;
    if (ref.read(Preferences.perAppProxyMode) == PerAppProxyMode.include) {
      return _include.write(value);
    }
    return _exclude.write(value);
  }

  Future<bool> share() async {
    final t = ref.watch(translationsProvider).requireValue;
    final agree = await ref.read(dialogNotifierProvider.notifier).showConfirmation(
          title: t.settings.network.share.dialogTitle,
          message: t.settings.network.share.msg,
          positiveBtnTxt: t.general.kContinue,
        );
    if (agree != true) return false;
    final rs = await ref.watch(autoSelectionRepoProvider).getByPerAppProxyMode();
    if (rs.$2.isSuccess()) {
      final selectedApps = state;
      selectedApps.removeWhere(
        (element) => rs.$1!.contains(element) || element.isEmpty,
      );
      if (selectedApps.isEmpty) {
        ref.read(inAppNotificationControllerProvider).showInfoToast(t.settings.network.share.emptyList);
        return false;
      } else {
        ref.watch(autoSelectionRepoProvider).share(t, selectedApps);
        return true;
      }
    } else {
      return false;
    }
  }

  Future<void> clearSelection() async {
    await _include.write([]);
    await _exclude.write([]);
    state = [];
  }

  Future<bool> autoSelection() async {
    final t = ref.watch(translationsProvider).requireValue.settings.network.autoSelection;
    final region = ref.watch(ConfigOptions.region);
    final responses = await Future.wait([
      ref.watch(autoSelectionRepoProvider).getInclude(),
      ref.watch(autoSelectionRepoProvider).getExclude(),
    ]);
    if (responses.any((e) => e.$2.isNotFound())) {
      ref.read(inAppNotificationControllerProvider).showInfoToast(
            t.regionNotFound(region: region.name),
            duration: const Duration(seconds: 5),
          );
      return false;
    } else if (responses.any((e) => e.$2.isFailure())) {
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.failure);
      return false;
    } else {
      await _include.write(responses[0].$1!);
      await _exclude.write(responses[1].$1!);
      state = ref.watch(Preferences.perAppProxyMode) == PerAppProxyMode.include ? _include.read() : _exclude.read();
      ref.read(Preferences.autoSelectionAppsRegion.notifier).update(region);
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.success);
      return true;
    }
  }

  Future<bool> exportJsonClipboard() async {
    final t = ref.watch(translationsProvider).requireValue.settings.network.export;
    try {
      final json = _exportJson();
      if (json == null) return false;
      await Clipboard.setData(ClipboardData(text: json));
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.success);
      return true;
    } on PlatformException {
      ref.read(inAppNotificationControllerProvider).showInfoToast(t.contentTooLarge, duration: const Duration(seconds: 5));
      return false;
    } catch (e, st) {
      loggy.warning("error exporting to clipboard", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.failure);
      return false;
    }
  }

  Future<bool> exportJsonFile() async {
    final t = ref.watch(translationsProvider).requireValue.settings.network.export;
    try {
      final json = _exportJson();
      if (json == null) return false;
      final bytes = utf8.encode(json);
      final outputFile = await FilePicker.platform.saveFile(
        fileName: 'per-app proxy.json',
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
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.success);
      return true;
    } catch (e, st) {
      loggy.warning("error exporting config options to json file", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.failure);
      return false;
    }
  }

  Future<bool> importFromClipboard() async {
    try {
      final input = await Clipboard.getData(Clipboard.kTextPlain).then((value) => value?.text);
      if (input == null) return false;
      return await _importJson(input);
    } catch (e, st) {
      loggy.warning("error importing from clipboard", e, st);
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

  String? _exportJson() {
    try {
      final map = {
        "proxy": _include.read(),
        "bypass": _exclude.read(),
      };
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(map);
    } catch (e, st) {
      loggy.warning("error creating export json", e, st);
      return null;
    }
  }

  Future<bool> _importJson(String input) async {
    var isSuccess = false;
    try {
      if (jsonDecode(input) case final Map<String, dynamic> map) {
        await _include.write((map['proxy']! as List).map((e) => e.toString()).toList());
        await _exclude.write((map['bypass']! as List).map((e) => e.toString()).toList());
        state = ref.watch(Preferences.perAppProxyMode) == PerAppProxyMode.include ? _include.read() : _exclude.read();
        isSuccess = true;
        return true;
      } else {
        return false;
      }
    } catch (e, st) {
      loggy.warning("error importing from input", e, st);
      return false;
    } finally {
      final t = ref.watch(translationsProvider).requireValue.settings.network.import;
      if (isSuccess) {
        ref.read(inAppNotificationControllerProvider).showSuccessToast(t.success);
      } else {
        ref.read(inAppNotificationControllerProvider).showErrorToast(t.failure);
      }
    }
  }
}
