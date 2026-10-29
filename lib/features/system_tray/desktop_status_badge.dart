import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hiddify/utils/platform_utils.dart';

/// Dock / taskbar status mark for desktop.
///
/// - [none]: disconnected — no mark
/// - [error]: connected but no usable ping — error (red) mark
/// - [ok]: connected with a valid ping — green mark
///
/// Linux: no-op (no standard taskbar badge API).
enum DesktopBadgeStatus { none, error, ok }

class DesktopStatusBadge {
  DesktopStatusBadge._();

  static const _channel = MethodChannel('com.hiddify.app/desktop_status');

  static Future<void> setStatus(DesktopBadgeStatus status) async {
    if (!PlatformUtils.isDesktop || Platform.isLinux) return;
    try {
      await _channel.invokeMethod<void>('setStatus', {'status': status.name});
    } on MissingPluginException {
      // Hot-restart / older builds without the native handler.
    } catch (_) {
      // Best-effort UI hint; never fail tray updates on badge errors.
    }
  }
}
