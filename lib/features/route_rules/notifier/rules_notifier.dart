import 'dart:convert';
import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/directories/directories_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/generated/v2/config/route_rule.pb.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rules_notifier.g.dart';

const _geoUrl = 'https://raw.githubusercontent.com/hiddify/hiddify-geo/rule-set';

/// Rules the app ships with, in the order a new list starts with. They are always in the list: the user can
/// only switch and move them, and their content comes from here, so an update can change it.
enum BuiltinRule {
  bypassLan(enabledByDefault: true),
  blockAds(enabledByDefault: false),
  bypassRegion(enabledByDefault: true);

  const BuiltinRule({required this.enabledByDefault});

  final bool enabledByDefault;

  /// Saved as the rule's name; the list shows [present] instead.
  String get key => 'builtin:$name';

  static BuiltinRule? of(Rule rule) => values.where((builtin) => builtin.key == rule.name).firstOrNull;

  String present(Translations t, Region region) => switch (this) {
    bypassLan => t.pages.settings.routing.builtinRules.bypassLan,
    blockAds => t.pages.settings.routing.builtinRules.blockAds,
    bypassRegion => t.pages.settings.routing.builtinRules.bypassRegion(region: region.presentName(t)),
  };

  Rule get rule => switch (this) {
    bypassLan => Rule(
      outbound: Outbound.direct,
      // the ranges sing-box treats as private (ip_is_private)
      ipCidrs: [
        '10.0.0.0/8',
        '172.16.0.0/12',
        '192.168.0.0/16',
        '127.0.0.0/8',
        '169.254.0.0/16',
        '224.0.0.0/4',
        '0.0.0.0/32',
        'fc00::/7',
        'fe80::/10',
        '::1/128',
        'ff00::/8',
        '::/128',
      ],
    ),
    blockAds => Rule(
      outbound: Outbound.block,
      ruleSets: [
        '$_geoUrl/block/geosite-category-ads-all.srs',
        '$_geoUrl/block/geosite-malware.srs',
        '$_geoUrl/block/geosite-phishing.srs',
        '$_geoUrl/block/geosite-cryptominers.srs',
        '$_geoUrl/block/geoip-malware.srs',
        '$_geoUrl/block/geoip-phishing.srs',
      ],
    ),
    bypassRegion => Rule(
      outbound: Outbound.direct,
      ruleSets: ['$_geoUrl/country/geosite-{region}.srs', '$_geoUrl/country/geoip-{region}.srs'],
    ),
  }..name = key;
}

@riverpod
class RulesNotifier extends _$RulesNotifier with AppLogger {
  late File file;

  @override
  List<Rule> build() {
    final directories = ref.watch(appDirectoriesProvider).requireValue;
    file = File('${directories.baseDir.path}/route_rule.proto');
    // the region rule goes with Other and comes back with any other region; a list never saved is still the
    // default one, so it keeps the default order (the intro sets the region on a new install)
    ref.listen(ConfigOptions.region, (_, _) async {
      state = _withBuiltins(file.existsSync() ? state : []);
      await _updateFile();
    });
    return _withBuiltins(file.existsSync() ? RouteRule.fromBuffer(file.readAsBytesSync()).rules : []);
  }

  /// Every built-in rule once, with the app's content and the user's switch and place; the ones missing go
  /// first, as in a new list. The region rule does nothing while the region is Other, so it's left out then.
  List<Rule> _withBuiltins(List<Rule> saved) {
    final region = ref.read(ConfigOptions.region);
    // the built-ins the list needs, in their own order; each one found in the saved list is crossed off
    final missing = {
      for (final builtin in BuiltinRule.values)
        if (builtin != BuiltinRule.bypassRegion || region != Region.other) builtin,
    };
    final rules = <Rule>[];
    for (final rule in saved) {
      final builtin = BuiltinRule.of(rule);
      if (builtin == null) {
        rules.add(rule);
      } else if (missing.remove(builtin)) {
        rules.add(builtin.rule..enabled = rule.enabled);
      }
    }
    return _updateListOrder([
      for (final builtin in missing) builtin.rule..enabled = builtin.enabledByDefault,
      ...rules,
    ]);
  }

  /// A new rule goes first, so it's checked before every other rule.
  Future<void> addRule(Rule rule) async {
    assert(rule.hasName() && rule.hasOutbound());
    rule.enabled = true;
    state = _updateListOrder([rule, ...state]);
    await _updateFile();
  }

  Future<void> updateRule(Rule rule) async {
    final current = state;
    final index = current.indexWhere((element) => element.listOrder == rule.listOrder);
    if (index == -1) return;
    current[index] = rule;
    state = current.toList();
    await _updateFile();
  }

  Future<void> deleteRule(int listOrder) async {
    final current = state;
    state = _updateListOrder(current.where((element) => element.listOrder != listOrder).toList());
    await _updateFile();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state;
    final rule = current.removeAt(oldIndex);
    current.insert(oldIndex < newIndex ? newIndex - 1 : newIndex, rule);
    state = _updateListOrder(current).toList();
    await _updateFile();
  }

  Future<void> updateEnabled(bool enabled, int listOrder) async {
    final current = state;
    current.firstWhere((rule) => rule.listOrder == listOrder).enabled = enabled;
    state = current.toList();
    await _updateFile();
  }

  //export Clipboard
  Future<bool> exportJsonToClipboard() async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final routeRules = RouteRule(rules: state);
      final base64Data = base64.encode(utf8.encode(jsonEncode(routeRules.writeToJson())));
      await Clipboard.setData(ClipboardData(text: 'hiddify:///settings/routing-options?routeRule=$base64Data'));
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.export.clipboard.success);
      return true;
    } on PlatformException {
      ref.read(inAppNotificationControllerProvider).showInfoToast(t.common.msg.export.clipboard.contentTooLarge);
      return false;
    } catch (e, st) {
      loggy.warning("error exporting route rules to clipboard", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.export.clipboard.failure);
      return false;
    }
  }

  //import clipboard
  Future<bool> importRulesFromClipboard() async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain).then((value) => value?.text);
      if (clipboardData == null) return false;
      final encodedBase64 = Uri.parse(clipboardData).queryParameters['routeRule'];
      if (encodedBase64 == null) return false;
      return await importRules(encodedBase64);
    } catch (e, st) {
      loggy.warning("error importing route rules from clipboard", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.import.failure);
      return false;
    }
  }

  //import deep link
  Future<bool> importRulesFromDeepLink(String encodedBase64) async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final isConfirmed = await ref
          .read(dialogNotifierProvider.notifier)
          .showConfirmation(
            title: t.dialogs.confirmation.importRouteRuleByDeepLinkWarning.title,
            message: t.dialogs.confirmation.importRouteRuleByDeepLinkWarning.message,
          );
      if (isConfirmed) {
        return await importRules(encodedBase64);
      }
      return false;
    } catch (e, st) {
      loggy.warning("error importing route rules from deep link", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.import.failure);
      return false;
    }
  }

  //import
  Future<bool> importRules(String encodedBase64) async {
    final t = ref.read(translationsProvider).requireValue;
    final base64Content = base64.decode(encodedBase64);
    final routeRules = RouteRule.fromJson(jsonDecode(utf8.decode(base64Content)) as String);
    state = _withBuiltins(routeRules.rules);
    await _updateFile();
    ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.import.success);
    return true;
  }

  //export JSON
  Future<bool> saveRulesAsJsonFile() async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final bytes = utf8.encode(RouteRule(rules: state).writeToJson());
      final outputFile = await FilePicker.platform.saveFile(
        fileName: 'route_rules.json',
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
      loggy.warning("error exporting route rules to json file", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.export.file.failure);
      return false;
    }
  }

  //import JSON
  Future<bool> importRulesFromJsonFile() async {
    final t = ref.read(translationsProvider).requireValue;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null) return false;
      final file = File(result.files.single.path!);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      final routeRules = RouteRule.fromJson(utf8.decode(bytes));
      state = _withBuiltins(routeRules.rules);
      await _updateFile();
      ref.read(inAppNotificationControllerProvider).showSuccessToast(t.common.msg.import.success);
      return true;
    } catch (e, st) {
      loggy.warning("error importing route rules from json file", e, st);
      ref.read(inAppNotificationControllerProvider).showErrorToast(t.common.msg.import.failure);
      return false;
    }
  }

  Future<void> resetRules() async {
    if (await file.exists()) {
      await file.delete(recursive: true);
      state = _withBuiltins([]);
    }
  }

  /// The list is always in its order: every change renumbers it or keeps each rule's place.
  Future<void> _updateFile() async {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(RouteRule(rules: state).writeToBuffer());
  }

  List<Rule> _updateListOrder(List<Rule> rules) {
    for (var i = 0; i < rules.length; i++) {
      rules[i].listOrder = i;
    }
    return rules;
  }
}
