import 'package:hiddify/core/utils/preferences_utils.dart';

abstract class TlsSettings {
  static final allowInsecure = PreferencesNotifier.create<bool, bool>(
    'tls_allow_insecure',
    false,
  );

  static final serverName = PreferencesNotifier.create<String, String>(
    'tls_server_name',
    '',
  );

  static final fingerprint = PreferencesNotifier.create<String, String>(
    'tls_fingerprint',
    'randomized',
  );

  static final alpn = PreferencesNotifier.create<String, String>(
    'tls_alpn',
    'h2,http/1.1',
  );

  static final enableEch = PreferencesNotifier.create<bool, bool>(
    'tls_enable_ech',
    false,
  );

  static final echConfig = PreferencesNotifier.create<String, String>(
    'tls_ech_config',
    '',
  );

  static final minVersion = PreferencesNotifier.create<String, String>(
    'tls_min_version',
    '1.2',
  );

  static final maxVersion = PreferencesNotifier.create<String, String>(
    'tls_max_version',
    '1.3',
  );

  static final disableSystemRoot = PreferencesNotifier.create<bool, bool>(
    'tls_disable_system_root',
    false,
  );

  static final enableSessionResumption = PreferencesNotifier.create<bool, bool>(
    'tls_enable_session_resumption',
    false,
  );

  static final pinnedCertChainSha256 =
      PreferencesNotifier.create<String, String>('tls_pinned_cert_sha256', '');

  static final realityPublicKey = PreferencesNotifier.create<String, String>(
    'reality_public_key',
    '',
  );

  static final realityShortId = PreferencesNotifier.create<String, String>(
    'reality_short_id',
    '',
  );

  static final realitySpiderX = PreferencesNotifier.create<String, String>(
    'reality_spider_x',
    '',
  );

  static const List<String> availableFingerprints = [
    'chrome',
    'firefox',
    'safari',
    'ios',
    'android',
    'edge',
    '360',
    'qq',
    'random',
    'randomized',
  ];

  static const List<String> availableAlpn = [
    'h2,http/1.1',
    'h2',
    'http/1.1',
    'h3',
  ];

  static const List<String> availableTlsVersions = ['1.0', '1.1', '1.2', '1.3'];

  static Map<String, dynamic> generateTlsSettings({
    required bool allowInsecureValue,
    required String fingerprintValue,
    String? serverNameValue,
    String? alpnValue,
    String? minVersionValue,
    String? maxVersionValue,
    bool disableSystemRootValue = false,
    bool enableSessionResumptionValue = false,
    String? pinnedCertSha256,
  }) {
    final config = <String, dynamic>{'allowInsecure': allowInsecureValue};

    if (serverNameValue != null && serverNameValue.isNotEmpty) {
      config['serverName'] = serverNameValue;
    }

    if (fingerprintValue.isNotEmpty) {
      config['fingerprint'] = fingerprintValue;
    }

    if (alpnValue != null && alpnValue.isNotEmpty) {
      config['alpn'] = alpnValue.split(',').map((e) => e.trim()).toList();
    }

    if (minVersionValue != null && minVersionValue.isNotEmpty) {
      config['minVersion'] = minVersionValue;
    }

    if (maxVersionValue != null && maxVersionValue.isNotEmpty) {
      config['maxVersion'] = maxVersionValue;
    }

    config['disableSystemRoot'] = disableSystemRootValue;
    config['enableSessionResumption'] = enableSessionResumptionValue;

    if (pinnedCertSha256 != null && pinnedCertSha256.isNotEmpty) {
      config['pinnedPeerCertificateChainSha256'] = [pinnedCertSha256];
    }

    return config;
  }

  static Map<String, dynamic> generateRealitySettings({
    required String serverNameValue,
    required String fingerprintValue,
    required String publicKeyValue,
    String? shortIdValue,
    String? spiderXValue,
  }) {
    final config = <String, dynamic>{
      'serverName': serverNameValue,
      'fingerprint': fingerprintValue,
      'publicKey': publicKeyValue,
    };

    if (shortIdValue != null && shortIdValue.isNotEmpty) {
      config['shortId'] = shortIdValue;
    }

    if (spiderXValue != null && spiderXValue.isNotEmpty) {
      config['spiderX'] = spiderXValue;
    }

    return config;
  }
}
