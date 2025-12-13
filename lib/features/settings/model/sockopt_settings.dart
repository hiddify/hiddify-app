import 'package:hiddify/core/utils/preferences_utils.dart';

/// Socket options settings for Xray-core low-level network tuning
abstract class SockoptSettings {
  // ============ TCP Options ============

  /// Enable TCP Fast Open
  static final tcpFastOpen = PreferencesNotifier.create<bool, bool>(
    'sockopt_tcp_fast_open',
    false,
  );

  /// TCP Keep Alive Interval (seconds)
  static final tcpKeepAliveInterval = PreferencesNotifier.create<int, int>(
    'sockopt_tcp_keepalive_interval',
    0,
  );

  /// TCP Keep Alive Idle (seconds)
  static final tcpKeepAliveIdle = PreferencesNotifier.create<int, int>(
    'sockopt_tcp_keepalive_idle',
    300,
  );

  /// TCP User Timeout (milliseconds)
  static final tcpUserTimeout = PreferencesNotifier.create<int, int>(
    'sockopt_tcp_user_timeout',
    10000,
  );

  /// TCP Congestion control algorithm: bbr, cubic, reno
  static final tcpCongestion = PreferencesNotifier.create<String, String>(
    'sockopt_tcp_congestion',
    '',
  );

  /// TCP No Delay (disable Nagle's algorithm)
  static final tcpNoDelay = PreferencesNotifier.create<bool, bool>(
    'sockopt_tcp_no_delay',
    false,
  );

  /// TCP Max Segment Size
  static final tcpMaxSeg = PreferencesNotifier.create<int, int>(
    'sockopt_tcp_max_seg',
    0,
  );

  /// TCP Window Clamp
  static final tcpWindowClamp = PreferencesNotifier.create<int, int>(
    'sockopt_tcp_window_clamp',
    0,
  );

  /// Enable TCP MPTCP (Multi-Path TCP)
  static final tcpMptcp = PreferencesNotifier.create<bool, bool>(
    'sockopt_tcp_mptcp',
    false,
  );

  // ============ General Options ============

  /// SO_MARK for routing (Linux only)
  static final mark = PreferencesNotifier.create<int, int>(
    'sockopt_mark',
    0,
  );

  /// Bind to specific interface
  static final bindInterface = PreferencesNotifier.create<String, String>(
    'sockopt_interface',
    '',
  );

  /// Transparent proxy mode: off, redirect, tproxy
  static final tproxy = PreferencesNotifier.create<String, String>(
    'sockopt_tproxy',
    'off',
  );

  /// Domain strategy for sockopt: AsIs, UseIP, UseIPv4, UseIPv6
  static final domainStrategy = PreferencesNotifier.create<String, String>(
    'sockopt_domain_strategy',
    'AsIs',
  );

  /// Dialer proxy tag
  static final dialerProxy = PreferencesNotifier.create<String, String>(
    'sockopt_dialer_proxy',
    '',
  );

  /// Accept PROXY protocol
  static final acceptProxyProtocol = PreferencesNotifier.create<bool, bool>(
    'sockopt_accept_proxy_protocol',
    false,
  );

  /// IPv6 only
  static final v6Only = PreferencesNotifier.create<bool, bool>(
    'sockopt_v6_only',
    false,
  );

  // ============ Available Options ============

  static const List<String> availableTcpCongestion = [
    '',
    'bbr',
    'cubic',
    'reno',
  ];

  static const List<String> availableTproxy = [
    'off',
    'redirect',
    'tproxy',
  ];

  static const List<String> availableDomainStrategies = [
    'AsIs',
    'UseIP',
    'UseIPv4',
    'UseIPv6',
    'UseIPv4v6',
    'UseIPv6v4',
    'ForceIP',
    'ForceIPv4',
    'ForceIPv6',
    'ForceIPv4v6',
    'ForceIPv6v4',
  ];

  /// Generate sockopt config for Xray-core
  static Map<String, dynamic>? generateSockoptConfig({
    bool? tcpFastOpenValue,
    int? tcpKeepAliveIntervalValue,
    int? tcpKeepAliveIdleValue,
    int? tcpUserTimeoutValue,
    String? tcpCongestionValue,
    bool? tcpNoDelayValue,
    int? tcpMaxSegValue,
    int? tcpWindowClampValue,
    bool? tcpMptcpValue,
    int? markValue,
    String? bindInterfaceValue,
    String? tproxyValue,
    String? domainStrategyValue,
    String? dialerProxyValue,
    bool? acceptProxyProtocolValue,
    bool? v6OnlyValue,
  }) {
    final config = <String, dynamic>{};

    if (tcpFastOpenValue ?? false) {
      config['tcpFastOpen'] = true;
    }

    if (tcpKeepAliveIntervalValue != null && tcpKeepAliveIntervalValue > 0) {
      config['tcpKeepAliveInterval'] = tcpKeepAliveIntervalValue;
    }

    if (tcpKeepAliveIdleValue != null && tcpKeepAliveIdleValue > 0) {
      config['tcpKeepAliveIdle'] = tcpKeepAliveIdleValue;
    }

    if (tcpUserTimeoutValue != null && tcpUserTimeoutValue > 0) {
      config['tcpUserTimeout'] = tcpUserTimeoutValue;
    }

    if (tcpCongestionValue != null && tcpCongestionValue.isNotEmpty) {
      config['tcpCongestion'] = tcpCongestionValue;
    }

    if (tcpNoDelayValue ?? false) {
      config['tcpNoDelay'] = true;
    }

    if (tcpMaxSegValue != null && tcpMaxSegValue > 0) {
      config['tcpMaxSeg'] = tcpMaxSegValue;
    }

    if (tcpWindowClampValue != null && tcpWindowClampValue > 0) {
      config['tcpWindowClamp'] = tcpWindowClampValue;
    }

    if (tcpMptcpValue ?? false) {
      config['tcpMptcp'] = true;
    }

    if (markValue != null && markValue > 0) {
      config['mark'] = markValue;
    }

    if (bindInterfaceValue != null && bindInterfaceValue.isNotEmpty) {
      config['interface'] = bindInterfaceValue;
    }

    if (tproxyValue != null && tproxyValue != 'off') {
      config['tproxy'] = tproxyValue;
    }

    if (domainStrategyValue != null && domainStrategyValue != 'AsIs') {
      config['domainStrategy'] = domainStrategyValue;
    }

    if (dialerProxyValue != null && dialerProxyValue.isNotEmpty) {
      config['dialerProxy'] = dialerProxyValue;
    }

    if (acceptProxyProtocolValue ?? false) {
      config['acceptProxyProtocol'] = true;
    }

    if (v6OnlyValue ?? false) {
      config['v6only'] = true;
    }

    if (config.isEmpty) return null;
    return config;
  }
}
