import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class CorePreferences {
  static final configContent = PreferencesNotifier.create<String, String>(
    "core_config_content",
    """{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10808,
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}""",
  );

  static final assetPath = PreferencesNotifier.create<String, String>(
    "core_asset_path",
    "",
  );

  static final coreMode = PreferencesNotifier.create<String, String>(
    "core_mode",
    "proxy", // vpn, proxy
  );

  static final routingRule = PreferencesNotifier.create<String, String>(
    "routing_rule",
    "global", // global, geo_iran, bypass_lan
  );

  static final enableLogging = PreferencesNotifier.create<bool, bool>(
    "enable_logging",
    false,
  );

  static final logLevel = PreferencesNotifier.create<String, String>(
    "log_level",
    "warning", // none, error, warning, info, debug
  );
}
