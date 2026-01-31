import 'package:hiddify/core/utils/preferences_utils.dart';


abstract class TransportSettings {
  
  static final network = PreferencesNotifier.create<String, String>(
    'transport_network',
    'raw',
  );

  
  static final wsPath = PreferencesNotifier.create<String, String>(
    'transport_ws_path',
    '/',
  );

  
  static final wsHost = PreferencesNotifier.create<String, String>(
    'transport_ws_host',
    '',
  );

  
  static final wsMaxEarlyData = PreferencesNotifier.create<int, int>(
    'transport_ws_max_early_data',
    0,
  );

  
  static final wsEarlyDataHeader = PreferencesNotifier.create<String, String>(
    'transport_ws_early_data_header',
    'Sec-WebSocket-Protocol',
  );

  
  static final grpcServiceName = PreferencesNotifier.create<String, String>(
    'transport_grpc_service_name',
    '',
  );

  
  static final grpcMode = PreferencesNotifier.create<String, String>(
    'transport_grpc_mode',
    'gun',
  );

  
  static final grpcAuthority = PreferencesNotifier.create<String, String>(
    'transport_grpc_authority',
    '',
  );

  
  static final httpHost = PreferencesNotifier.create<String, String>(
    'transport_http_host',
    '',
  );

  
  static final httpPath = PreferencesNotifier.create<String, String>(
    'transport_http_path',
    '/',
  );

  
  static final httpMethod = PreferencesNotifier.create<String, String>(
    'transport_http_method',
    'PUT',
  );

  
  static final httpUpgradePath = PreferencesNotifier.create<String, String>(
    'transport_httpupgrade_path',
    '/',
  );

  
  static final httpUpgradeHost = PreferencesNotifier.create<String, String>(
    'transport_httpupgrade_host',
    '',
  );

  
  static final kcpHeaderType = PreferencesNotifier.create<String, String>(
    'transport_kcp_header',
    'none',
  );

  
  static final kcpSeed = PreferencesNotifier.create<String, String>(
    'transport_kcp_seed',
    '',
  );

  
  static final kcpCongestion = PreferencesNotifier.create<bool, bool>(
    'transport_kcp_congestion',
    false,
  );

  
  static final kcpUplinkCapacity = PreferencesNotifier.create<int, int>(
    'transport_kcp_uplink',
    5,
  );

  
  static final kcpDownlinkCapacity = PreferencesNotifier.create<int, int>(
    'transport_kcp_downlink',
    20,
  );

  
  static final quicSecurity = PreferencesNotifier.create<String, String>(
    'transport_quic_security',
    'none',
  );

  
  static final quicKey = PreferencesNotifier.create<String, String>(
    'transport_quic_key',
    '',
  );

  
  static final quicHeaderType = PreferencesNotifier.create<String, String>(
    'transport_quic_header',
    'none',
  );

  
  static final tcpHeaderType = PreferencesNotifier.create<String, String>(
    'transport_tcp_header',
    'none',
  );

  
  static final tcpHost = PreferencesNotifier.create<String, String>(
    'transport_tcp_host',
    '',
  );

  
  static final tcpPath = PreferencesNotifier.create<String, String>(
    'transport_tcp_path',
    '/',
  );

  static const List<String> availableNetworks = [
    'raw',
    'tcp',
    'ws',
    'grpc',
    'kcp',
    'http',
    'httpupgrade',
    'quic',
    'xhttp',
  ];

  static const List<String> availableKcpHeaders = [
    'none',
    'srtp',
    'utp',
    'wechat-video',
    'dtls',
    'wireguard',
  ];

  static const List<String> availableQuicSecurities = [
    'none',
    'aes-128-gcm',
    'chacha20-poly1305',
  ];

  static const List<String> availableGrpcModes = ['gun', 'multi', 'raw'];

  
  static Map<String, dynamic> generateWsSettings({
    required String path,
    String? host,
    int maxEarlyData = 0,
    String? earlyDataHeader,
    Map<String, String>? headers,
  }) {
    final config = <String, dynamic>{'path': path};

    final headersMap = <String, String>{};
    if (host != null && host.isNotEmpty) {
      headersMap['Host'] = host;
    }
    if (headers != null) {
      headersMap.addAll(headers);
    }
    if (headersMap.isNotEmpty) {
      config['headers'] = headersMap;
    }

    if (maxEarlyData > 0) {
      config['maxEarlyData'] = maxEarlyData;
      if (earlyDataHeader != null && earlyDataHeader.isNotEmpty) {
        config['earlyDataHeaderName'] = earlyDataHeader;
      }
    }

    return config;
  }

  
  static Map<String, dynamic> generateGrpcSettings({
    required String serviceName,
    String mode = 'gun',
    String? authority,
  }) {
    final config = <String, dynamic>{
      'serviceName': serviceName,
      'multiMode': mode == 'multi',
    };

    if (authority != null && authority.isNotEmpty) {
      config['authority'] = authority;
    }

    return config;
  }

  
  static Map<String, dynamic> generateHttpSettings({
    required String path,
    String? host,
    String method = 'PUT',
  }) {
    final config = <String, dynamic>{'path': path, 'method': method};

    if (host != null && host.isNotEmpty) {
      config['host'] = [host];
    }

    return config;
  }

  
  static Map<String, dynamic> generateHttpUpgradeSettings({
    required String path,
    String? host,
  }) {
    final config = <String, dynamic>{'path': path};

    if (host != null && host.isNotEmpty) {
      config['host'] = host;
    }

    return config;
  }

  
  static Map<String, dynamic> generateKcpSettings({
    String headerType = 'none',
    String? seed,
    bool congestion = false,
    int uplinkCapacity = 5,
    int downlinkCapacity = 20,
  }) {
    final config = <String, dynamic>{
      'header': {'type': headerType},
      'congestion': congestion,
      'uplinkCapacity': uplinkCapacity,
      'downlinkCapacity': downlinkCapacity,
    };

    if (seed != null && seed.isNotEmpty) {
      config['seed'] = seed;
    }

    return config;
  }

  
  static Map<String, dynamic> generateQuicSettings({
    String security = 'none',
    String? key,
    String headerType = 'none',
  }) {
    final config = <String, dynamic>{
      'security': security,
      'header': {'type': headerType},
    };

    if (key != null && key.isNotEmpty) {
      config['key'] = key;
    }

    return config;
  }

  
  static Map<String, dynamic>? generateTcpSettings({
    String headerType = 'none',
    String? host,
    String? path,
  }) {
    if (headerType == 'none') return null;

    return {
      'header': {
        'type': 'http',
        'request': {
          'version': '1.1',
          'method': 'GET',
          'path': [path ?? '/'],
          'headers': {
            'Host': [host ?? ''],
            'User-Agent': [
              'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36',
              'Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46',
            ],
            'Accept-Encoding': ['gzip, deflate'],
            'Connection': ['keep-alive'],
            'Pragma': 'no-cache',
          },
        },
      },
    };
  }
}
