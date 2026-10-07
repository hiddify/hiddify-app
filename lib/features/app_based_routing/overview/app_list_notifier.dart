import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/app_based_routing/data/selected_data_provider.dart';
import 'package:hiddify/features/app_based_routing/model/per_app_proxy_backup.dart';
import 'package:hiddify/features/app_based_routing/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/app_based_routing/model/pkg_flag.dart';
import 'package:hiddify/features/app_based_routing/overview/auto_selection_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:installed_apps/index.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_list_notifier.g.dart';

/// An app's logo, fetched once per run: the plugin lists every installed app for each lookup. Each logo stays in
/// memory until the app closes, so this is for a few logos, like the routing page's apps row, not for whole lists.
@Riverpod(keepAlive: true)
Future<Uint8List?> appLogo(Ref ref, String packageName) async =>
    (await InstalledApps.getAppInfo(packageName, BuiltWith.flutter))?.icon;

@riverpod
class AppList extends _$AppList with AppLogger {
  @override
  Stream<Map<String, int>> build(AppProxyMode? mode) {
    if (mode == null) return Stream.value({});
    final appsInfo = InstalledApps.getInstalledApps(false);
    return Stream.fromFuture(appsInfo).asyncExpand((appsInfo) {
      final phonePkgs = appsInfo.map((e) => e.packageName).toSet();
      return ref.watch(appProxyDataSourceProvider).watchFilterForDisplay(phonePkgs: phonePkgs, mode: mode).map((
        entryList,
      ) {
        return {for (final entry in entryList) entry.pkgName: entry.flags};
      });
    });
  }

  Future<void> updatePkg(String pkg) async {
    loggy.info('Updationg $pkg status');
    await ref.read(appProxyDataSourceProvider).updatePkg(pkg: pkg, mode: mode!);
  }

  Future<void> clearAll() async {
    loggy.info('Clearing all items');
    await ref.read(appProxyDataSourceProvider).clearAll(mode: mode!);
    await ref.read(Preferences.autoAppsSelectionRegion.notifier).update(null);
    ref.read(autoSelectionIssueProvider.notifier).update(null);
  }

  Future<bool> importClipboard() async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final input = await Clipboard.getData(Clipboard.kTextPlain).then((value) => value?.text);
      await _importJson(input!);
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.import.success);
      return true;
    } catch (e, st) {
      loggy.warning("error importing from clipboard", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.import.failure);
      return false;
    }
  }

  Future<bool> importFile() async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      final file = File(result!.files.single.path!);
      if (!await file.exists()) throw Exception('File does not exist: path = ${file.path}');
      final bytes = await file.readAsBytes();
      await _importJson(jsonDecode(utf8.decode(bytes)).toString());
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.import.success);
      return true;
    } catch (e, st) {
      loggy.warning("error importing config options from json file", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.import.failure);
      return false;
    }
  }

  Future<bool> exportClipboard() async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final json = await _exportJson();
      await Clipboard.setData(ClipboardData(text: json));
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.export.clipboard.success);
      return true;
    } on PlatformException {
      ref.read(inAppNotificationControllerProvider).showInfoToast(t.common.msg.export.clipboard.contentTooLarge);
      return false;
    } catch (e, st) {
      loggy.warning("error exporting to clipboard", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.export.clipboard.failure);
      return false;
    }
  }

  Future<bool> exportFile() async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final json = await _exportJson();
      final bytes = utf8.encode(jsonEncode(json));
      final outputFile = await FilePicker.platform.saveFile(
        fileName: 'app-based routing.json',
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

  /// Opens a new issue for the region's list, filled with the apps you added to it and the auto picks
  /// you removed. The share sheet has already shown both lists, so nothing asks again here.
  Future<void> shareOnGithub({required List<String> added, required List<String> removed}) async {
    final t = ref.read(translationsProvider).requireValue;
    final region = ref.read(ConfigOptions.region);
    final mode = ref.read(Preferences.perAppProxyMode);
    final title = '${region.name} | ${mode.present(t)}';
    final body =
        '```\n${const JsonEncoder.withIndent('  ').convert({'addedPkgs': added, 'removedPkgs': removed})}\n```';
    await UriUtils.tryLaunch(
      Uri.https('github.com', '/hiddify/Android-GFW-Apps/issues/new', {'title': title, 'body': body}),
    );
  }

  Future<void> _importJson(String input) async {
    final backup = PerAppProxyBackup.fromJson((jsonDecode(input) as Map).cast());
    await ref.read(appProxyDataSourceProvider).importPkgs(backup: backup);
  }

  Future<String> _exportJson() async {
    final ds = ref.read(appProxyDataSourceProvider);
    final backup = PerAppProxyBackup(
      include: PerAppProxyBackupMode(
        selected: await ds.getPkgsByFlag(mode: AppProxyMode.include, flag: PkgFlag.userSelection),
        deselected: await ds.getPkgsByFlag(mode: AppProxyMode.include, flag: PkgFlag.forceDeselection),
      ),
      exclude: PerAppProxyBackupMode(
        selected: await ds.getPkgsByFlag(mode: AppProxyMode.exclude, flag: PkgFlag.userSelection),
        deselected: await ds.getPkgsByFlag(mode: AppProxyMode.exclude, flag: PkgFlag.forceDeselection),
      ),
    );
    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }
}
