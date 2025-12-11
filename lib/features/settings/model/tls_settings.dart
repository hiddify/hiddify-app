import 'package:hiddify/core/utils/preferences_utils.dart';

/// TLS and REALITY settings for Xray-core
abstract class TlsSettings {
  // ============ Basic TLS ============

  /// Allow insecure TLS connections (skip verification)
  static final allowInsecure = PreferencesNotifier.create<bool, bool>(
    'tls_allow_insecure',
    false,
  );

  /// Server name (SNI)
  static final serverName = PreferencesNotifier.create<String, String>(
    'tls_server_name',
    '',
  );

  /// TLS Fingerprint (uTLS) - 🇮🇷 Randomized for Iran
  /// Options: chrome, firefox, safari, ios, android, edge, 360, qq, random, randomized
  static final fingerprint = PreferencesNotifier.create<String, String>(
    'tls_fingerprint',
    'randomized', // 🇮🇷 Randomized to bypass fingerprint detection
  );

  /// ALPN protocols
  static final alpn = PreferencesNotifier.create<String, String>(
    'tls_alpn',
    'h2,http/1.1',
  );

  /// Enable ECH (Encrypted Client Hello) - Future anti-censorship
  static final enableEch = PreferencesNotifier.create<bool, bool>(
    'tls_enable_ech',
    false,
  );

  /// ECH config (base64 encoded)
  static final echConfig = PreferencesNotifier.create<String, String>(
    'tls_ech_config',
    '',
  );

  /// Minimum TLS version
  static final minVersion = PreferencesNotifier.create<String, String>(
    'tls_min_version',
    '1.2',
  );

  /// Maximum TLS version
  static final maxVersion = PreferencesNotifier.create<String, String>(
    'tls_max_version',
    '1.3',
  );

  /// Disable system root CA
  static final disableSystemRoot = PreferencesNotifier.create<bool, bool>(
    'tls_disable_system_root',
    false,
  );

  /// Enable session resumption
  static final enableSessionResumption = PreferencesNotifier.create<bool, bool>(
    'tls_enable_session_resumption',
    false,
  );

  /// Pinned certificate chain SHA256
  static final pinnedCertChainSha256 = PreferencesNotifier.create<String, String>(
    'tls_pinned_cert_sha256',
    '',
  );

  // ============ REALITY Settings ============

  /// REALITY public key
  static final realityPublicKey = PreferencesNotifier.create<String, String>(
    'reality_public_key',
    '',
  );

  /// REALITY short ID
  static final realityShortId = PreferencesNotifier.create<String, String>(
    'reality_short_id',
    '',
  );

  /// REALITY spider X
  static final realitySpiderX = PreferencesNotifier.create<String, String>(
    'reality_spider_x',
    '',
  );

  // ============ Available Fingerprints ============

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

  static const List<String> availableTlsVersions = [
    '1.0',
    '1.1',
    '1.2',
    '1.3',
  ];

  /// Generate TLS settings for Xray-core
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
    final config = <String, dynamic>{
      'allowInsecure': allowInsecureValue,
    };

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

  /// Generate REALITY settings for Xray-core
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
