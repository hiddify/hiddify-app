import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hiddify/core/core.dart' hide AppInfo;
import 'package:hiddify/features/per_app_proxy/model/app_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'per_app_proxy_service.g.dart';

@Riverpod(keepAlive: true)
PerAppProxyService perAppProxyService(Ref ref) => PerAppProxyService();

class PerAppProxyService {
  static const _channel = MethodChannel('com.hiddify.app/platform');

  Future<List<AppInfo>> getInstalledPackages() async {
    if (!Platform.isAndroid) return [];

    try {
      final String? jsonString = await _channel.invokeMethod<String>(
        'get_installed_packages',
      );
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((e) => AppInfo.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, stack) {
      Logger.system.error('Failed to get installed packages', e, stack);
      return [];
    }
  }

  Future<Uint8List?> getPackageIcon(String packageName) async {
    if (!Platform.isAndroid) return null;

    try {
      final String? base64Icon = await _channel.invokeMethod<String>(
        'get_package_icon',
        {'packageName': packageName},
      );
      if (base64Icon == null) return null;

      return base64Decode(base64Icon);
    } catch (e) {
      Logger.system.warning('Failed to get icon for $packageName: $e');
      return null;
    }
  }
}
