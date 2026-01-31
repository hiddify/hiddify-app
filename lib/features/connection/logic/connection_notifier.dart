import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hiddify/core/logger/log_bus_bridge.dart';
import 'package:hiddify/core/logger/log_service.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/service/core_service.dart';
import 'package:hiddify/core/service/hysteria_service.dart';
import 'package:hiddify/core/service/naive_service.dart';
import 'package:hiddify/core/service/shadowsocksr_service.dart';
import 'package:hiddify/core/service/tuic_service.dart';
import 'package:hiddify/core/service/tun_service.dart';
import 'package:hiddify/features/config/logic/hysteria_parser.dart';
import 'package:hiddify/features/config/logic/naive_parser.dart';
import 'package:hiddify/features/config/logic/protocol_parser.dart';
import 'package:hiddify/features/config/logic/shadowsocks_parser.dart';
import 'package:hiddify/features/config/logic/shadowsocksr_parser.dart';
import 'package:hiddify/features/config/logic/trojan_parser.dart';
import 'package:hiddify/features/config/logic/tuic_parser.dart';
import 'package:hiddify/features/config/logic/vless_parser.dart';
import 'package:hiddify/features/config/logic/vmess_parser.dart';
import 'package:hiddify/features/config/logic/wireguard_parser.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hiddify/features/connection/logic/core_configurator.dart';
import 'package:hiddify/features/settings/model/core_preferences.dart';
import 'package:hiddify/features/settings/model/dns_settings.dart';
import 'package:hiddify/features/settings/model/fragment_settings.dart';
import 'package:hiddify/features/settings/model/inbound_settings.dart';
import 'package:hiddify/features/settings/model/mux_settings.dart';
import 'package:hiddify/features/settings/model/routing_settings.dart';
import 'package:hiddify/features/settings/model/sockopt_settings.dart';
import 'package:hiddify/features/settings/model/tls_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connection_notifier.g.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }


@riverpod
class LastConnectionError extends _$LastConnectionError {
  @override
  String? build() => null;

  String? get error => state;
  set error(String? value) => state = value;
  void clear() => state = null;
}

@riverpod
class ConnectionNotifier extends _$ConnectionNotifier {
  late final CoreService _coreService;
  late final TunService _tunService;
  late final HysteriaService _hysteriaService;
  late final TuicService _tuicService;
  late final ShadowsocksRService _ssrService;
  late final NaiveService _naiveService;
  bool _isHysteriaMode = false;
  bool _isTuicMode = false;
  bool _isSsrMode = false;
  bool _isNaiveMode = false;

  @override
  ConnectionStatus build() {
    ref.keepAlive();
    _coreService = CoreService();
    _tunService = TunService();
    _hysteriaService = HysteriaService();
    _tuicService = TuicService();
    _ssrService = ShadowsocksRService();
    _naiveService = NaiveService();
    unawaited(_tunService.stop());
    return ConnectionStatus.disconnected;
  }

  
  bool _isHysteriaProtocol(String content) {
    final trimmed = content.trim().toLowerCase();
    return trimmed.startsWith('hy2://') ||
        trimmed.startsWith('hysteria2://') ||
        trimmed.startsWith('hysteria://');
  }

  
  bool _isTuicProtocol(String content) {
    final trimmed = content.trim().toLowerCase();
    return trimmed.startsWith('tuic://');
  }

  
  bool _isSsrProtocol(String content) {
    final trimmed = content.trim().toLowerCase();
    return trimmed.startsWith('ssr://');
  }

  
  bool _isNaiveProtocol(String content) {
    final trimmed = content.trim().toLowerCase();
    return trimmed.startsWith('naive+https://') ||
        trimmed.startsWith('naive+quic://') ||
        trimmed.startsWith('naive://');
  }

  Future<void> _stopAllPluginsSafely() async {
    try {
      await _hysteriaService.stop();
    } catch (e, stackTrace) {
      Logger.connection.warning('Failed to stop Hysteria: $e', e, stackTrace);
    }

    try {
      await _tuicService.stop();
    } catch (e, stackTrace) {
      Logger.connection.warning('Failed to stop TUIC: $e', e, stackTrace);
    }

    try {
      await _ssrService.stop();
    } catch (e, stackTrace) {
      Logger.connection.warning(
        'Failed to stop ShadowsocksR: $e',
        e,
        stackTrace,
      );
    }

    try {
      await _naiveService.stop();
    } catch (e, stackTrace) {
      Logger.connection.warning(
        'Failed to stop NativeProxy: $e',
        e,
        stackTrace,
      );
    }

    _isHysteriaMode = false;
    _isTuicMode = false;
    _isSsrMode = false;
    _isNaiveMode = false;
  }

  Future<void> _cleanupAfterFailedConnect({
    required bool coreStartInvoked,
  }) async {
    try {
      await _tunService.stop();
    } catch (e, stackTrace) {
      Logger.connection.warning('Failed to stop TUN: $e', e, stackTrace);
    }

    if (coreStartInvoked) {
      try {
        await _coreService.stop();
      } catch (e, stackTrace) {
        Logger.connection.warning('Failed to stop core: $e', e, stackTrace);
      }
    }

    await _stopAllPluginsSafely();
  }

  Future<void> connect(Config config) async {
    state = ConnectionStatus.connecting;
    ref.read(lastConnectionErrorProvider.notifier).clear();

    Logger.connection.info('Connecting to ${config.name}...');
    final validationError = _validateConfig(config);
    if (validationError != null) {
      Logger.connection.error('Config validation failed: $validationError');
      ref.read(lastConnectionErrorProvider.notifier).error = validationError;
      state = ConnectionStatus.error;
      return;
    }

    var coreStartInvoked = false;

    try {
      final coreMode = ref.read(CorePreferences.coreMode);
      final logLevel = ref.read(CorePreferences.logLevel);
      final enableLogging = ref.read(CorePreferences.enableLogging);

      final socksPort = ref.read(InboundSettings.socksPort);
      final socksListen = ref.read(InboundSettings.socksListen);
      final socksUdp = ref.read(InboundSettings.socksUdp);
      final socksAuth = ref.read(InboundSettings.socksAuth);

      final httpPort = ref.read(InboundSettings.httpPort);
      final httpListen = ref.read(InboundSettings.httpListen);
      final httpAllowTransparent = ref.read(
        InboundSettings.httpAllowTransparent,
      );

      final enableSniffing = ref.read(InboundSettings.sniffingEnabled);
      final sniffingDestOverride = ref.read(
        InboundSettings.sniffingDestOverride,
      );
      final sniffingRouteOnly = ref.read(InboundSettings.sniffingRouteOnly);
      final sniffingFakeDns = ref.read(InboundSettings.sniffingFakeDns);
      final sniffingExcludeRaw = ref.read(
        InboundSettings.sniffingExcludeDomains,
      );
      final sniffingExcludeDomains = sniffingExcludeRaw.isNotEmpty
          ? sniffingExcludeRaw.split(',').map((e) => e.trim()).toList()
          : null;

      final allowInsecure = ref.read(TlsSettings.allowInsecure);
      final fingerPrint = ref.read(TlsSettings.fingerprint);
      final alpn = ref.read(TlsSettings.alpn);

      final enableMux = ref.read(MuxSettings.enabled);
      final muxConcurrency = ref.read(MuxSettings.concurrency);
      final muxPadding = ref.read(MuxSettings.padding);
      final xudpConcurrency = ref.read(MuxSettings.xudpConcurrency);
      final xudpProxyUDP443 = ref.read(MuxSettings.xudpProxyUDP443);

      final remoteDns = ref.read(DnsSettings.remoteDns);
      final remoteDnsType = ref.read(DnsSettings.remoteDnsType);
      final directDns = ref.read(DnsSettings.directDns);
      final directDnsType = ref.read(DnsSettings.directDnsType);
      final dnsQueryStrategy = ref.read(DnsSettings.queryStrategy);
      final enableDnsRouting = ref.read(DnsSettings.enableDnsRouting);
      final dnsDisableCache = ref.read(DnsSettings.disableCache);
      final dnsDisableFallback = ref.read(DnsSettings.disableFallback);
      final dnsClientIp = ref.read(DnsSettings.clientIp);

      final enableFakeDns = ref.read(DnsSettings.enableFakeDns);
      final fakeDnsIpv4Pool = ref.read(DnsSettings.fakeDnsIpv4Pool);
      final fakeDnsIpv6Pool = ref.read(DnsSettings.fakeDnsIpv6Pool);
      final fakeDnsPoolSize = ref.read(DnsSettings.fakeDnsPoolSize);

      Map<String, dynamic>? dnsHosts;
      try {
        final hostsStr = ref.read(DnsSettings.customHosts);
        if (hostsStr.isNotEmpty) {
          dnsHosts = jsonDecode(hostsStr) as Map<String, dynamic>;
        }
      } catch (e) {
        Logger.dns.warning('Failed to parse DNS custom hosts: $e');
      }

      final domainStrategy = ref.read(RoutingSettings.domainStrategy);
      final bypassLan = ref.read(RoutingSettings.bypassLan);
      final bypassIran = ref.read(RoutingSettings.bypassIran);
      final bypassChina = ref.read(RoutingSettings.bypassChina);
      final blockAds = ref.read(RoutingSettings.blockAds);
      final blockPorn = ref.read(RoutingSettings.blockPorn);
      final blockQuic = ref.read(RoutingSettings.blockQuic);
      final blockMalware = ref.read(RoutingSettings.blockMalware);
      final blockPhishing = ref.read(RoutingSettings.blockPhishing);
      final directYoutube = ref.read(RoutingSettings.directYoutube);
      final directNetflix = ref.read(RoutingSettings.directNetflix);

      final customDirectDomains = RoutingSettings.parseCustomRules(
        ref.read(RoutingSettings.customDirectDomains),
      );
      final customProxyDomains = RoutingSettings.parseCustomRules(
        ref.read(RoutingSettings.customProxyDomains),
      );
      final customBlockDomains = RoutingSettings.parseCustomRules(
        ref.read(RoutingSettings.customBlockDomains),
      );
      final customDirectIps = RoutingSettings.parseCustomRules(
        ref.read(RoutingSettings.customDirectIps),
      );
      final customProxyIps = RoutingSettings.parseCustomRules(
        ref.read(RoutingSettings.customProxyIps),
      );
      final customBlockIps = RoutingSettings.parseCustomRules(
        ref.read(RoutingSettings.customBlockIps),
      );

      final enableFragment = ref.read(FragmentSettings.enabled);
      final fragmentPackets = ref.read(FragmentSettings.packets);
      final fragmentLength = ref.read(FragmentSettings.length);
      final fragmentInterval = ref.read(FragmentSettings.interval);

      final enableNoise = ref.read(FragmentSettings.noiseEnabled);
      final noiseType = ref.read(FragmentSettings.noiseType);
      final noisePacket = ref.read(FragmentSettings.noisePacket);
      final noiseDelay = ref.read(FragmentSettings.noiseDelay);

      final tcpFastOpen = ref.read(SockoptSettings.tcpFastOpen);
      final tcpCongestion = ref.read(SockoptSettings.tcpCongestion);
      final tcpKeepAliveInterval = ref.read(
        SockoptSettings.tcpKeepAliveInterval,
      );
      final tcpKeepAliveIdle = ref.read(SockoptSettings.tcpKeepAliveIdle);
      final tcpUserTimeout = ref.read(SockoptSettings.tcpUserTimeout);
      final tcpNoDelay = ref.read(SockoptSettings.tcpNoDelay);
      final tcpMaxSeg = ref.read(SockoptSettings.tcpMaxSeg);
      final tcpWindowClamp = ref.read(SockoptSettings.tcpWindowClamp);
      final tcpMptcp = ref.read(SockoptSettings.tcpMptcp);
      final sockoptTproxy = ref.read(SockoptSettings.tproxy);
      final sockoptDomainStrategy = ref.read(SockoptSettings.domainStrategy);
      final accessLogPath = await ref
          .read(logServiceProvider)
          .getAccessLogPath();
      final errorLogPath = await ref.read(logServiceProvider).getCoreLogPath();

      if (enableLogging) {
        try {
          await LogBusBridge.instance.ensureStarted(
            coreLogPath: errorLogPath,
            accessLogPath: accessLogPath,
          );
        } catch (e) {
          Logger.connection.warning('Failed to start LogBusBridge: $e');
        }
      }
      _isHysteriaMode = _isHysteriaProtocol(config.content);
      _isTuicMode = _isTuicProtocol(config.content);
      _isSsrMode = _isSsrProtocol(config.content);
      _isNaiveMode = _isNaiveProtocol(config.content);

      var effectiveConfig = config;
      if (_isHysteriaMode) {
        Logger.hysteria.info('Detected Hysteria protocol, starting plugin...');

        final hysteriaConfig = HysteriaService.parseUri(config.content);
        if (hysteriaConfig == null) {
          throw Exception('Failed to parse Hysteria URI');
        }
        final serverSocket = await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        final hysteriaLocalPort = serverSocket.port;
        await serverSocket.close();

        final hysteriaError = await _hysteriaService.start(
          server: hysteriaConfig['server'] as String,
          port: hysteriaConfig['port'] as int,
          auth: hysteriaConfig['auth'] as String,
          sni: hysteriaConfig['sni'] as String?,
          insecure: hysteriaConfig['insecure'] as bool? ?? false,
          upMbps: hysteriaConfig['up'] as int? ?? 100,
          downMbps: hysteriaConfig['down'] as int? ?? 100,
          obfs: hysteriaConfig['obfs'] as String?,
          obfsPassword: hysteriaConfig['obfsPassword'] as String?,
          localPort: hysteriaLocalPort,
        );

        if (hysteriaError != null) {
          Logger.hysteria.error('Hysteria error: $hysteriaError');
          ref.read(lastConnectionErrorProvider.notifier).error =
              'Hysteria: $hysteriaError';
          state = ConnectionStatus.error;
          return;
        }

        Logger.hysteria.info('Hysteria started on port $hysteriaLocalPort');
        effectiveConfig = Config(
          id: config.id,
          name: config.name,
          content: 'socks://127.0.0.1:$hysteriaLocalPort#${config.name}',
          type: 'socks',
          addedAt: config.addedAt,
        );
      }
      if (_isTuicMode) {
        Logger.tuic.info('Detected TUIC protocol, starting plugin...');

        final tuicConfig = TuicService.parseUri(config.content);
        if (tuicConfig == null) {
          throw Exception('Failed to parse TUIC URI');
        }
        final serverSocket = await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        final tuicLocalPort = serverSocket.port;
        await serverSocket.close();

        final tuicError = await _tuicService.start(
          server: tuicConfig['server'] as String,
          port: tuicConfig['port'] as int,
          uuid: tuicConfig['uuid'] as String,
          password: tuicConfig['password'] as String? ?? '',
          sni: tuicConfig['sni'] as String?,
          insecure: tuicConfig['insecure'] as bool? ?? false,
          alpn: (tuicConfig['alpn'] as List?)?.cast<String>(),
          congestionControl:
              tuicConfig['congestionControl'] as String? ?? 'bbr',
          udpRelayMode: tuicConfig['udpRelayMode'] as String? ?? 'native',
          disableSni: tuicConfig['disableSni'] as bool? ?? false,
          localPort: tuicLocalPort,
        );

        if (tuicError != null) {
          Logger.tuic.error('TUIC error: $tuicError');
          ref.read(lastConnectionErrorProvider.notifier).error =
              'TUIC: $tuicError';
          state = ConnectionStatus.error;
          return;
        }

        Logger.tuic.info('TUIC started on port $tuicLocalPort');

        effectiveConfig = Config(
          id: config.id,
          name: config.name,
          content: 'socks://127.0.0.1:$tuicLocalPort#${config.name}',
          type: 'socks',
          addedAt: config.addedAt,
        );
      }
      if (_isSsrMode) {
        Logger.ssr.info('Detected ShadowsocksR protocol, starting plugin...');

        final ssrConfig = ShadowsocksRService.parseUri(config.content);
        if (ssrConfig == null) {
          throw Exception('Failed to parse SSR URI');
        }
        final serverSocket = await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        final ssrLocalPort = serverSocket.port;
        await serverSocket.close();

        final ssrError = await _ssrService.start(
          server: ssrConfig['server'] as String,
          port: ssrConfig['port'] as int,
          password: ssrConfig['password'] as String,
          method: ssrConfig['method'] as String,
          protocol: ssrConfig['protocol'] as String? ?? 'origin',
          protocolParam: ssrConfig['protocolParam'] as String? ?? '',
          obfs: ssrConfig['obfs'] as String? ?? 'plain',
          obfsParam: ssrConfig['obfsParam'] as String? ?? '',
          localPort: ssrLocalPort,
        );

        if (ssrError != null) {
          Logger.ssr.error('SSR error: $ssrError');
          ref.read(lastConnectionErrorProvider.notifier).error =
              'SSR: $ssrError';
          state = ConnectionStatus.error;
          return;
        }

        Logger.ssr.info('SSR started on port $ssrLocalPort');

        effectiveConfig = Config(
          id: config.id,
          name: config.name,
          content: 'socks://127.0.0.1:$ssrLocalPort#${config.name}',
          type: 'socks',
          addedAt: config.addedAt,
        );
      }
      if (_isNaiveMode) {
        Logger.naive.info('Detected NaïveProxy protocol, starting plugin...');

        final naiveConfig = NaiveService.parseUri(config.content);
        if (naiveConfig == null) {
          throw Exception('Failed to parse Naive URI');
        }
        final serverSocket = await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        final naiveLocalPort = serverSocket.port;
        await serverSocket.close();

        final naiveError = await _naiveService.start(
          host: naiveConfig['host'] as String,
          port: naiveConfig['port'] as int,
          username: naiveConfig['username'] as String,
          password: naiveConfig['password'] as String,
          scheme: naiveConfig['scheme'] as String? ?? 'https',
          sni: naiveConfig['sni'] as String?,
          insecure: naiveConfig['insecure'] as bool? ?? false,
          localPort: naiveLocalPort,
        );

        if (naiveError != null) {
          Logger.naive.error('Naive error: $naiveError');
          ref.read(lastConnectionErrorProvider.notifier).error =
              'Naive: $naiveError';
          state = ConnectionStatus.error;
          return;
        }

        Logger.naive.info('Naive started on port $naiveLocalPort');

        effectiveConfig = Config(
          id: config.id,
          name: config.name,
          content: 'socks://127.0.0.1:$naiveLocalPort#${config.name}',
          type: 'socks',
          addedAt: config.addedAt,
        );
      }
      final fullConfig = await compute(
        _generateFullConfig,
        <String, dynamic>{
          'activeConfig': effectiveConfig.toJson(),
          'coreMode': coreMode,
          'logLevel': logLevel,
          'enableLogging': enableLogging,
          'accessLogPath': accessLogPath,
          'errorLogPath': errorLogPath,
          'socksPort': socksPort,
          'httpPort': httpPort,
          'domainStrategy': domainStrategy,
          'allowInsecure': allowInsecure,
          'fingerPrint': fingerPrint,
          'alpn': alpn,
          'enableMux': enableMux,
          'muxConcurrency': muxConcurrency,
          'muxPadding': muxPadding,
          'xudpConcurrency': xudpConcurrency,
          'xudpProxyUDP443': xudpProxyUDP443,
          'remoteDns': remoteDns,
          'remoteDnsType': remoteDnsType,
          'directDns': directDns,
          'directDnsType': directDnsType,
          'dnsQueryStrategy': dnsQueryStrategy,
          'enableDnsRouting': enableDnsRouting,
          'dnsDisableCache': dnsDisableCache,
          'dnsDisableFallback': dnsDisableFallback,
          'dnsClientIp': dnsClientIp,
          'enableFakeDns': enableFakeDns,
          'fakeDnsIpv4Pool': fakeDnsIpv4Pool,
          'fakeDnsIpv6Pool': fakeDnsIpv6Pool,
          'fakeDnsPoolSize': fakeDnsPoolSize,
          'dnsHosts': dnsHosts,
          'socksListen': socksListen,
          'socksUdp': socksUdp,
          'socksAuth': socksAuth,
          'httpListen': httpListen,
          'httpAllowTransparent': httpAllowTransparent,
          'bypassLan': bypassLan,
          'bypassIran': bypassIran,
          'bypassChina': bypassChina,
          'blockAds': blockAds,
          'blockPorn': blockPorn,
          'blockQuic': blockQuic,
          'blockMalware': blockMalware,
          'blockPhishing': blockPhishing,
          'directYoutube': directYoutube,
          'directNetflix': directNetflix,
          'enableFragment': enableFragment,
          'fragmentPackets': fragmentPackets,
          'fragmentLength': fragmentLength,
          'fragmentInterval': fragmentInterval,
          'enableNoise': enableNoise,
          'noiseType': noiseType,
          'noisePacket': noisePacket,
          'noiseDelay': noiseDelay,
          'enableSniffing': enableSniffing,
          'sniffingDestOverride': sniffingDestOverride,
          'sniffingRouteOnly': sniffingRouteOnly,
          'sniffingFakeDns': sniffingFakeDns,
          'sniffingExcludeDomains': sniffingExcludeDomains,
          'tcpFastOpen': tcpFastOpen,
          'tcpCongestion': tcpCongestion,
          'tcpKeepAliveInterval': tcpKeepAliveInterval,
          'tcpKeepAliveIdle': tcpKeepAliveIdle,
          'tcpUserTimeout': tcpUserTimeout,
          'tcpNoDelay': tcpNoDelay,
          'tcpMaxSeg': tcpMaxSeg,
          'tcpWindowClamp': tcpWindowClamp,
          'tcpMptcp': tcpMptcp,
          'sockoptTproxy': sockoptTproxy,
          'sockoptDomainStrategy': sockoptDomainStrategy,
          'customDirectDomains': customDirectDomains,
          'customProxyDomains': customProxyDomains,
          'customBlockDomains': customBlockDomains,
          'customDirectIps': customDirectIps,
          'customProxyIps': customProxyIps,
          'customBlockIps': customBlockIps,
        },
      );

      coreStartInvoked = true;
      final error = await _coreService.start(fullConfig);
      
      // Check if disconnected while starting
      if (state == ConnectionStatus.disconnected) {
        Logger.connection.info('Connection cancelled during start');
        return;
      }

      if (error != null) {
        Logger.core.error('Core error: $error');
        ref.read(lastConnectionErrorProvider.notifier).error = error;
        state = ConnectionStatus.error;
        return;
      }
      if (coreMode == 'vpn') {
        Logger.tun.info('Starting TUN for VPN mode...');
        if (!await _tunService.isAvailable()) {
          Logger.tun.info('Downloading TUN assets...');
          try {
            await _tunService.ensureAssets();
          } catch (e) {
            Logger.tun.error('Failed to download TUN assets: $e');
            ref.read(lastConnectionErrorProvider.notifier).error =
                'TUN assets not available: $e';
            state = ConnectionStatus.error;
            return;
          }
        }

        // Check if disconnected while downloading assets
        if (state == ConnectionStatus.disconnected) {
          return;
        }

        final tunError = await _tunService.start(
          socksAddr: '127.0.0.1:$socksPort',
        );

        if (tunError != null) {
          Logger.tun.error('TUN error: $tunError');
          ref.read(lastConnectionErrorProvider.notifier).error =
              'TUN: $tunError';
          state = ConnectionStatus.error;
          return;
        }

        Logger.tun.info('TUN started successfully');
      }

      Logger.connection.info('Connected successfully to ${config.name}');
      state = ConnectionStatus.connected;
    } catch (e, stackTrace) {
      final errorMsg = e.toString();
      Logger.connection.error('Connection failed: $errorMsg', e, stackTrace);
      ref.read(lastConnectionErrorProvider.notifier).error = errorMsg;
      state = ConnectionStatus.error;
    } finally {
      if (state != ConnectionStatus.connected) {
        await _cleanupAfterFailedConnect(coreStartInvoked: coreStartInvoked);
      }
    }
  }

  Future<void> disconnect() async {
    Logger.connection.info('Disconnecting...');

    await _tunService.stop();

    await _coreService.stop();

    if (_hysteriaService.isRunning) {
      Logger.hysteria.info('Stopping Hysteria...');
      await _hysteriaService.stop();
    }
    _isHysteriaMode = false;

    if (_tuicService.isRunning) {
      Logger.tuic.info('Stopping TUIC...');
      await _tuicService.stop();
    }
    _isTuicMode = false;

    if (_ssrService.isRunning) {
      Logger.ssr.info('Stopping ShadowsocksR...');
      await _ssrService.stop();
    }
    _isSsrMode = false;

    if (_naiveService.isRunning) {
      Logger.naive.info('Stopping NaïveProxy...');
      await _naiveService.stop();
    }
    _isNaiveMode = false;

    ref.read(lastConnectionErrorProvider.notifier).clear();
    state = ConnectionStatus.disconnected;
    Logger.connection.info('Disconnected');
  }

  
  void clearError() {
    if (state == ConnectionStatus.error) {
      ref.read(lastConnectionErrorProvider.notifier).clear();
      state = ConnectionStatus.disconnected;
    }
  }

  
  Future<bool> isVpnAvailable() => _tunService.isAvailable();

  
  Future<void> downloadTunAssets({
    void Function(double progress, String status)? onProgress,
  }) => _tunService.ensureAssets(onProgress: onProgress);

  
  String? _validateConfig(Config config) {
    final content = config.content.trim();

    if (content.isEmpty) {
      return 'Config is empty';
    }
    if (content.startsWith('{')) {
      return null;
    }
    final protocol = ProtocolParser.detectProtocol(content);
    if (protocol == 'unknown') {
      return 'Unknown config format. Supported: vless, vmess, trojan, ss, wg, hy2';
    }
    final parsed = ProtocolParser.parse(content);
    if (parsed == null) {
      return 'Failed to parse config. Please check the format.';
    }
    String? error;
    switch (protocol) {
      case 'wireguard':
        error = WireguardParser.validate(parsed);
      case 'vless':
        error = VlessParser.validate(parsed);
      case 'vmess':
        error = VmessParser.validate(parsed);
      case 'trojan':
        error = TrojanParser.validate(parsed);
      case 'shadowsocks':
        error = ShadowsocksParser.validate(parsed);
      case 'hysteria':
      case 'hysteria2':
        error = HysteriaParser.validate(parsed);
      case 'tuic':
        error = TuicParser.validate(parsed);
      case 'shadowsocksr':
        error = ShadowsocksRParser.validate(parsed);
      case 'naive':
        error = NaiveParser.validate(parsed);
    }

    if (error != null) {
      return '${protocol.toUpperCase()}: $error';
    }

    return null; 
  }
}

String _generateFullConfig(Map<String, dynamic> params) {
  final activeConfigJson =
      Map<String, dynamic>.from(params['activeConfig'] as Map);
  final activeConfig = Config.fromJson(activeConfigJson);

  List<String>? toStringList(Object? value) {
    if (value == null) return null;
    return (value as List).cast<String>();
  }

  Map<String, dynamic>? toMap(Object? value) {
    if (value == null) return null;
    return Map<String, dynamic>.from(value as Map);
  }

  return CoreConfigurator.generateConfig(
    activeConfig: activeConfig,
    coreMode: params['coreMode'] as String,
    logLevel: params['logLevel'] as String,
    enableLogging: params['enableLogging'] as bool,
    accessLogPath: params['accessLogPath'] as String,
    errorLogPath: params['errorLogPath'] as String,
    socksPort: params['socksPort'] as int,
    httpPort: params['httpPort'] as int,
    domainStrategy: params['domainStrategy'] as String,
    allowInsecure: params['allowInsecure'] as bool,
    fingerPrint: params['fingerPrint'] as String,
    alpn: params['alpn'] as String?,
    enableMux: params['enableMux'] as bool,
    muxConcurrency: params['muxConcurrency'] as int,
    muxPadding: params['muxPadding'] as bool,
    xudpConcurrency: params['xudpConcurrency'] as int?,
    xudpProxyUDP443: params['xudpProxyUDP443'] as String?,
    remoteDns: params['remoteDns'] as String,
    remoteDnsType: params['remoteDnsType'] as String,
    directDns: params['directDns'] as String?,
    directDnsType: params['directDnsType'] as String,
    dnsQueryStrategy: params['dnsQueryStrategy'] as String?,
    enableDnsRouting: params['enableDnsRouting'] as bool,
    dnsDisableCache: params['dnsDisableCache'] as bool,
    dnsDisableFallback: params['dnsDisableFallback'] as bool,
    dnsClientIp: params['dnsClientIp'] as String?,
    enableFakeDns: params['enableFakeDns'] as bool,
    fakeDnsIpv4Pool: params['fakeDnsIpv4Pool'] as String?,
    fakeDnsIpv6Pool: params['fakeDnsIpv6Pool'] as String?,
    fakeDnsPoolSize: params['fakeDnsPoolSize'] as int?,
    dnsHosts: toMap(params['dnsHosts']),
    socksListen: params['socksListen'] as String,
    socksUdp: params['socksUdp'] as bool,
    socksAuth: params['socksAuth'] as String,
    httpListen: params['httpListen'] as String,
    httpAllowTransparent: params['httpAllowTransparent'] as bool,
    bypassLan: params['bypassLan'] as bool,
    bypassIran: params['bypassIran'] as bool,
    bypassChina: params['bypassChina'] as bool,
    blockAds: params['blockAds'] as bool,
    blockPorn: params['blockPorn'] as bool,
    blockQuic: params['blockQuic'] as bool,
    blockMalware: params['blockMalware'] as bool,
    blockPhishing: params['blockPhishing'] as bool,
    directYoutube: params['directYoutube'] as bool,
    directNetflix: params['directNetflix'] as bool,
    enableFragment: params['enableFragment'] as bool,
    fragmentPackets: params['fragmentPackets'] as String?,
    fragmentLength: params['fragmentLength'] as String?,
    fragmentInterval: params['fragmentInterval'] as String?,
    enableNoise: params['enableNoise'] as bool,
    noiseType: params['noiseType'] as String?,
    noisePacket: params['noisePacket'] as String?,
    noiseDelay: params['noiseDelay'] as String?,
    enableSniffing: params['enableSniffing'] as bool,
    sniffingDestOverride: params['sniffingDestOverride'] as String?,
    sniffingRouteOnly: params['sniffingRouteOnly'] as bool,
    sniffingFakeDns: params['sniffingFakeDns'] as bool,
    sniffingExcludeDomains: toStringList(params['sniffingExcludeDomains']),
    tcpFastOpen: params['tcpFastOpen'] as bool,
    tcpCongestion: params['tcpCongestion'] as String?,
    tcpKeepAliveInterval: params['tcpKeepAliveInterval'] as int?,
    tcpKeepAliveIdle: params['tcpKeepAliveIdle'] as int?,
    tcpUserTimeout: params['tcpUserTimeout'] as int?,
    tcpNoDelay: params['tcpNoDelay'] as bool,
    tcpMaxSeg: params['tcpMaxSeg'] as int?,
    tcpWindowClamp: params['tcpWindowClamp'] as int?,
    tcpMptcp: params['tcpMptcp'] as bool,
    sockoptTproxy: params['sockoptTproxy'] as String?,
    sockoptDomainStrategy: params['sockoptDomainStrategy'] as String?,
    customDirectDomains: toStringList(params['customDirectDomains']),
    customProxyDomains: toStringList(params['customProxyDomains']),
    customBlockDomains: toStringList(params['customBlockDomains']),
    customDirectIps: toStringList(params['customDirectIps']),
    customProxyIps: toStringList(params['customProxyIps']),
    customBlockIps: toStringList(params['customBlockIps']),
  );
}
