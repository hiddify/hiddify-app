import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class CorePreferences {
  static final configContent = PreferencesNotifier.create<String, String>(
    'core_config_content',
    '''
{
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
}''',
  );

  static final assetPath = PreferencesNotifier.create<String, String>(
    'core_asset_path',
    '',
  );

  static final coreMode = PreferencesNotifier.create<String, String>(
    'core_mode',
    'proxy', // vpn, proxy
  );

  static final routingRule = PreferencesNotifier.create<String, String>(
    'routing_rule',
    'global', // global, geo_iran, bypass_lan
  );

  static final enableLogging = PreferencesNotifier.create<bool, bool>(
    'enable_logging',
    false,
  );

  static final logLevel = PreferencesNotifier.create<String, String>(
    'log_level',
    'warning', // none, error, warning, info, debug
  );

  // Inbound Settings
  static final sockPort = PreferencesNotifier.create<int, int>('inbound_socks_port', 2334);
  static final httpPort = PreferencesNotifier.create<int, int>('inbound_http_port', 2335);

  // Outbound/Mux Settings
  static final enableMux = PreferencesNotifier.create<bool, bool>('mux_enable', false);
  static final muxConcurrency = PreferencesNotifier.create<int, int>('mux_concurrency', 8);
  static final muxPadding = PreferencesNotifier.create<bool, bool>('mux_padding', true);

  // Connection Settings
  static final allowInsecure = PreferencesNotifier.create<bool, bool>('allow_insecure', false);
  static final fingerPrint = PreferencesNotifier.create<String, String>('tls_fingerprint', 'chrome'); // chrome, firefox, ios...

  // DNS Settings
  static final remoteDns = PreferencesNotifier.create<String, String>('remote_dns', '8.8.8.8');
  static final localDns = PreferencesNotifier.create<String, String>('local_dns', '1.1.1.1');
  static final domainStrategy = PreferencesNotifier.create<String, String>('domain_strategy', 'IPIfNonMatch');
}
