import 'package:flutter/foundation.dart';
import 'package:loggy/loggy.dart';

class Logger {
  static final app = Loggy('app');
  static final bootstrap = Loggy('bootstrap');
  static final connection = Loggy('connection');
  static final core = Loggy('core');
  static final tun = Loggy('tun');
  static final dns = Loggy('dns');
  static final routing = Loggy('routing');
  static final hysteria = Loggy('hysteria');
  static final tuic = Loggy('tuic');
  static final ssr = Loggy('ssr');
  static final naive = Loggy('naive');
  static final vless = Loggy('vless');
  static final vmess = Loggy('vmess');
  static final trojan = Loggy('trojan');
  static final shadowsocks = Loggy('shadowsocks');
  static final wireguard = Loggy('wireguard');
  static final config = Loggy('config');
  static final parser = Loggy('parser');
  static final subscription = Loggy('subscription');
  static final geoAsset = Loggy('geo_asset');
  static final stats = Loggy('stats');
  static final notification = Loggy('notification');
  static final ui = Loggy('ui');
  static final router = Loggy('router');
  static final settings = Loggy('settings');
  static final storage = Loggy('storage');
  static final preferences = Loggy('preferences');
  static final database = Loggy('database');
  static final system = Loggy('system');
  static final platform = Loggy('platform');
  static final permission = Loggy('permission');
  static final security = Loggy('security');
  static final firewall = Loggy('firewall');

  static void logFlutterError(FlutterErrorDetails details) {
    if (_isKnownViewportHitTestBug(details)) {
      return;
    }

    if (details.silent) {
      return;
    }

    final description = details.exceptionAsString();

    ui.error('Flutter Error: $description', details.exception, details.stack);
  }

  static bool _isKnownViewportHitTestBug(FlutterErrorDetails details) {
    final description = details.exceptionAsString();
    if (!description.contains('Null check operator used on a null value')) {
      return false;
    }

    final stack = details.stack?.toString() ?? '';
    return stack.contains('RenderViewportBase.hitTestChildren');
  }

  static bool logPlatformDispatcherError(Object error, StackTrace stackTrace) {
    platform.error('PlatformDispatcherError: $error', error, stackTrace);
    return true;
  }
}
