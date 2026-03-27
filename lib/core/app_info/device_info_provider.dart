import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Returns device model string for use in x-device-model header.
/// Returns empty string on unsupported platforms or on error.
final deviceModelProvider = FutureProvider<String>((ref) async {
  if (kIsWeb) return '';
  final info = DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      final d = await info.androidInfo;
      return d.model;
    } else if (Platform.isIOS) {
      final d = await info.iosInfo;
      return d.utsname.machine;
    } else if (Platform.isWindows) {
      final d = await info.windowsInfo;
      return d.productName;
    } else if (Platform.isMacOS) {
      final d = await info.macOsInfo;
      return d.model;
    }
  } catch (_) {}
  return '';
});
