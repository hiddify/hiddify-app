// ignore: unused_import
import 'package:dio/dio.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hiddify/features/route_rules/notifier/rule_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'android_apps_notifier.g.dart';

@riverpod
Future<List<AppInfo>> apps(Ref ref) async {
  if (!PlatformUtils.isAndroid) return [];
  return await InstalledApps.getInstalledApps(false, true);
}

@riverpod
Future<List<AppInfo>> appsHideSystem(Ref ref) async {
  if (!PlatformUtils.isAndroid) return [];
  return await InstalledApps.getInstalledApps(true, true);
}

@riverpod
Future<List<String>> appPackages(Ref ref) async {
  if (!PlatformUtils.isAndroid) return [];
  return (await InstalledApps.getInstalledApps(false)).map((e) => e.packageName).toList();
}

@riverpod
Future<List<AppInfo>> filteredByHideSystem(Ref ref) async {
  final hideSystem = ref.watch(hideSystemNotifierProvider);
  return hideSystem ? await ref.watch(appsHideSystemProvider.future) : await ref.watch(appsProvider.future);
}

@riverpod
Future<List<String>> uninstalledPackages(Ref ref, int? ruleListOrder) async {
  final allPackages = await ref.watch(appPackagesProvider.future);
  final selectedPackages = ref.read(SelectedPackagesNotifierProvider(ruleListOrder));
  return selectedPackages.toSet().difference(allPackages.toSet()).toList();
}

@riverpod
Future<List<dynamic>> filterBySearch(Ref ref, int? ruleListOrder) async {
  final searchQuery = ref.watch(searchQueryNotifierProvider);
  final filteredByHideSystem = await ref.watch(filteredByHideSystemProvider.future);

  if (searchQuery.isEmpty) {
    final selected = ref.read(SelectedPackagesNotifierProvider(ruleListOrder));
    final uninstalledPackages = await ref.read(UninstalledPackagesProvider(ruleListOrder).future);
    final fullList = [...uninstalledPackages, ...filteredByHideSystem];
    fullList.sort((a, b) {
      final aValue = (a is String) ? a : (a as AppInfo).packageName;
      final bValue = (b is String) ? b : (b as AppInfo).packageName;

      final aIndex = selected.indexOf(aValue);
      final bIndex = selected.indexOf(bValue);

      if (aIndex == -1 && bIndex == -1) return 0;
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;

      return aIndex.compareTo(bIndex);
    });
    return fullList;
  } else {
    return filteredByHideSystem.where((app) => app.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }
}

@riverpod
class HideSystemNotifier extends _$HideSystemNotifier {
  @override
  bool build() {
    return false;
  }

  void show() => state = false;

  void hide() => state = true;
}

@riverpod
class SearchQueryNotifier extends _$SearchQueryNotifier {
  @override
  String build() => '';

  void setQuery(String query) => state = query.trim();

  void clear() => state = '';
}

@riverpod
class SelectedPackagesNotifier extends _$SelectedPackagesNotifier {
  late int? _ruleListOrder;
  final _ruleEnum = RuleEnum.packageName;

  @override
  List<String> build(int? ruleListOrder) {
    _ruleListOrder = ruleListOrder;
    final value = ref.read(ruleNotifierProvider(ruleListOrder)).writeToJsonMap()['${_ruleEnum.getIndex()}'];
    if (value is List) return value.cast<String>();
    return [];
  }

  void onChanged(String packageName) {
    if (state.contains(packageName)) {
      state = List.from(state)..removeWhere((element) => element == packageName);
    } else {
      state = [...state, packageName];
    }
    _save();
  }

  void clearSelection() {
    state = [];
    _save();
  }

  void _save() => ref.read(ruleNotifierProvider(_ruleListOrder).notifier).update<List<dynamic>>(_ruleEnum, state);
}
