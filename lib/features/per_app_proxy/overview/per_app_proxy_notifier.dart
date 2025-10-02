import 'package:flutter/material.dart';
import 'package:hiddify/features/per_app_proxy/data/per_app_proxy_data_providers.dart';
import 'package:hiddify/features/per_app_proxy/model/installed_package_info.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'per_app_proxy_notifier.g.dart';

@riverpod
Future<List<InstalledPackageInfo>> installedPackagesInfo(Ref ref) {
  return ref.watch(perAppProxyRepositoryProvider).getInstalledPackages().getOrElse((err) {
    // _logger.error("error getting installed packages", err);
    throw err;
  }).run();
}

@riverpod
Future<ImageProvider<Object>> packageIcon(Ref ref, String packageName) async {
  ref.disposeDelay(const Duration(seconds: 10));
  final bytes = await ref.watch(perAppProxyRepositoryProvider).getPackageIcon(packageName).getOrElse((err) {
    // _logger.warning("error getting package icon", err);
    throw err;
  }).run();
  return MemoryImage(bytes);
}
