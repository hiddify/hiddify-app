import 'dart:convert';
import 'package:hiddify/core/logger/log_service.dart';
import 'package:hiddify/core/logger/log_bus_bridge.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/service/core_service.dart';
import 'package:hiddify/core/service/hysteria_service.dart';
import 'package:hiddify/core/service/tun_service.dart';
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

/// Provider for last connection error
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
  bool _isHysteriaMode = false;

  @override
  ConnectionStatus build() {
    _coreService = CoreService();
    _tunService = TunService();
    _hysteriaService = HysteriaService();
    return ConnectionStatus.disconnected;
  }

  /// Check if config is Hysteria protocol
  bool _isHysteriaProtocol(String content) {
    final trimmed = content.trim().toLowerCase();
    return trimmed.startsWith('hy2://') ||
        trimmed.startsWith('hysteria2://') ||
        trimmed.startsWith('hysteria://');
  }

  Future<void> connect(Config config) async {
    state = ConnectionStatus.connecting;
    ref.read(lastConnectionErrorProvider.notifier).clear();
    
    Logger.app.info('Connecting to ${config.name}...');

    try {
      // Core Settings
      final coreMode = ref.read(CorePreferences.coreMode);
      final logLevel = ref.read(CorePreferences.logLevel);
      final enableLogging = ref.read(CorePreferences.enableLogging);

      // Inbound Settings
      // Inbound Settings
      final socksPort = ref.read(InboundSettings.socksPort);
      final socksListen = ref.read(InboundSettings.socksListen);
      final socksUdp = ref.read(InboundSettings.socksUdp);
      final socksAuth = ref.read(InboundSettings.socksAuth);
      
      final httpPort = ref.read(InboundSettings.httpPort);
      final httpListen = ref.read(InboundSettings.httpListen);
      final httpAllowTransparent = ref.read(InboundSettings.httpAllowTransparent);
      
      final enableSniffing = ref.read(InboundSettings.sniffingEnabled);
      final sniffingDestOverride = ref.read(InboundSettings.sniffingDestOverride);
      final sniffingRouteOnly = ref.read(InboundSettings.sniffingRouteOnly);
      final sniffingFakeDns = ref.read(InboundSettings.sniffingFakeDns);
      final sniffingExcludeRaw = ref.read(InboundSettings.sniffingExcludeDomains);
      final sniffingExcludeDomains = sniffingExcludeRaw.isNotEmpty 
          ? sniffingExcludeRaw.split(',').map((e) => e.trim()).toList() 
          : null;

      // TLS Settings
      final allowInsecure = ref.read(TlsSettings.allowInsecure);
      final fingerPrint = ref.read(TlsSettings.fingerprint);
      final alpn = ref.read(TlsSettings.alpn);

      // MUX Settings
      final enableMux = ref.read(MuxSettings.enabled);
      final muxConcurrency = ref.read(MuxSettings.concurrency);
      final muxPadding = ref.read(MuxSettings.padding);
      final xudpConcurrency = ref.read(MuxSettings.xudpConcurrency);
      final xudpProxyUDP443 = ref.read(MuxSettings.xudpProxyUDP443);

      // DNS Settings
      // DNS Settings
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
        Logger.app.warning('Failed to parse DNS custom hosts: $e');
      }

      // Routing Settings
      // Routing Settings
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

      // Fragment Settings (GFW-knocker)
      final enableFragment = ref.read(FragmentSettings.enabled);
      final fragmentPackets = ref.read(FragmentSettings.packets);
      final fragmentLength = ref.read(FragmentSettings.length);
      final fragmentInterval = ref.read(FragmentSettings.interval);

      // Noise Settings (GFW-knocker)
      final enableNoise = ref.read(FragmentSettings.noiseEnabled);
      final noiseType = ref.read(FragmentSettings.noiseType);
      final noisePacket = ref.read(FragmentSettings.noisePacket);
      final noiseDelay = ref.read(FragmentSettings.noiseDelay);

      // Security Settings


      // Sockopt Settings
      // Sockopt Settings
      final tcpFastOpen = ref.read(SockoptSettings.tcpFastOpen);
      final tcpCongestion = ref.read(SockoptSettings.tcpCongestion);
      final tcpKeepAliveInterval = ref.read(SockoptSettings.tcpKeepAliveInterval);
      final tcpKeepAliveIdle = ref.read(SockoptSettings.tcpKeepAliveIdle);
      final tcpUserTimeout = ref.read(SockoptSettings.tcpUserTimeout);
      final tcpNoDelay = ref.read(SockoptSettings.tcpNoDelay);
      final tcpMaxSeg = ref.read(SockoptSettings.tcpMaxSeg);
      final tcpWindowClamp = ref.read(SockoptSettings.tcpWindowClamp);
      final tcpMptcp = ref.read(SockoptSettings.tcpMptcp);
      final sockoptTproxy = ref.read(SockoptSettings.tproxy);
      final sockoptDomainStrategy = ref.read(SockoptSettings.domainStrategy);

      // Log paths
      final accessLogPath = await ref.read(logServiceProvider).getAccessLogPath();
      final errorLogPath = await ref.read(logServiceProvider).getCoreLogPath();

      if (enableLogging) {
        try {
          await LogBusBridge.instance.ensureStarted(
            coreLogPath: errorLogPath,
            accessLogPath: accessLogPath,
          );
        } catch (e) {
          Logger.app.warning('Failed to start LogBusBridge: $e');
        }
      }

      // Check if this is a Hysteria config
      _isHysteriaMode = _isHysteriaProtocol(config.content);
      
      var effectiveConfig = config;
      
      if (_isHysteriaMode) {
        Logger.app.info('Detected Hysteria protocol, starting Hysteria plugin...');
        
        final hysteriaConfig = HysteriaService.parseUri(config.content);
        if (hysteriaConfig == null) {
          throw Exception('Failed to parse Hysteria URI');
        }
        
        // Start Hysteria on a dedicated port
        const hysteriaLocalPort = 10808;
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
        );
        
        if (hysteriaError != null) {
          Logger.app.error('Hysteria error: $hysteriaError');
          ref.read(lastConnectionErrorProvider.notifier).error =
              'Hysteria: $hysteriaError';
          state = ConnectionStatus.error;
          return;
        }
        
        Logger.app.info('Hysteria started on port $hysteriaLocalPort');
        
        // Create a SOCKS proxy config that points to Hysteria
        effectiveConfig = Config(
          id: config.id,
          name: config.name,
          content: 'socks://127.0.0.1:$hysteriaLocalPort#${config.name}',
          type: 'socks',
          addedAt: config.addedAt,
        );
      }

      final fullConfig = CoreConfigurator.generateConfig(
        activeConfig: effectiveConfig,
        coreMode: coreMode,
        logLevel: logLevel,
        enableLogging: enableLogging,
        accessLogPath: accessLogPath,
        errorLogPath: errorLogPath,
        socksPort: socksPort,
        httpPort: httpPort,
        domainStrategy: domainStrategy,
        // TLS
        allowInsecure: allowInsecure,
        fingerPrint: fingerPrint,
        alpn: alpn,
        // MUX
        enableMux: enableMux,
        muxConcurrency: muxConcurrency,
        muxPadding: muxPadding,
        xudpConcurrency: xudpConcurrency,
        xudpProxyUDP443: xudpProxyUDP443,
        // DNS
        // DNS
        remoteDns: remoteDns,
        remoteDnsType: remoteDnsType,
        directDns: directDns,
        directDnsType: directDnsType,
        dnsQueryStrategy: dnsQueryStrategy,
        enableDnsRouting: enableDnsRouting,
        dnsDisableCache: dnsDisableCache,
        dnsDisableFallback: dnsDisableFallback,
        dnsClientIp: dnsClientIp,
        enableFakeDns: enableFakeDns,
        fakeDnsIpv4Pool: fakeDnsIpv4Pool,
        fakeDnsIpv6Pool: fakeDnsIpv6Pool,
        fakeDnsPoolSize: fakeDnsPoolSize,
        dnsHosts: dnsHosts,
        // Inbound
        socksListen: socksListen,
        socksUdp: socksUdp,
        socksAuth: socksAuth,
        httpListen: httpListen,
        httpAllowTransparent: httpAllowTransparent,
        // Routing
        bypassLan: bypassLan,
        bypassIran: bypassIran,
        bypassChina: bypassChina,
        blockAds: blockAds,
        blockPorn: blockPorn,
        blockQuic: blockQuic,
        blockMalware: blockMalware,
        blockPhishing: blockPhishing,
        directYoutube: directYoutube,
        directNetflix: directNetflix,
        // Fragment (GFW-knocker)
        enableFragment: enableFragment,
        fragmentPackets: fragmentPackets,
        fragmentLength: fragmentLength,
        fragmentInterval: fragmentInterval,
        // Noise (GFW-knocker)
        enableNoise: enableNoise,
        noiseType: noiseType,
        noisePacket: noisePacket,
        noiseDelay: noiseDelay,
        // Sniffing
        enableSniffing: enableSniffing,
        sniffingDestOverride: sniffingDestOverride,
        sniffingRouteOnly: sniffingRouteOnly,
        sniffingFakeDns: sniffingFakeDns,
        sniffingExcludeDomains: sniffingExcludeDomains,
        // Sockopt
        tcpFastOpen: tcpFastOpen,
        tcpCongestion: tcpCongestion,
        tcpKeepAliveInterval: tcpKeepAliveInterval,
        tcpKeepAliveIdle: tcpKeepAliveIdle,
        tcpUserTimeout: tcpUserTimeout,
        tcpNoDelay: tcpNoDelay,
        tcpMaxSeg: tcpMaxSeg,
        tcpWindowClamp: tcpWindowClamp,
        tcpMptcp: tcpMptcp,
        sockoptTproxy: sockoptTproxy,
        sockoptDomainStrategy: sockoptDomainStrategy,
        // Custom rules
        customDirectDomains: customDirectDomains.isNotEmpty ? customDirectDomains : null,
        customProxyDomains: customProxyDomains.isNotEmpty ? customProxyDomains : null,
        customBlockDomains: customBlockDomains.isNotEmpty ? customBlockDomains : null,
        customDirectIps: customDirectIps.isNotEmpty ? customDirectIps : null,
        customProxyIps: customProxyIps.isNotEmpty ? customProxyIps : null,
        customBlockIps: customBlockIps.isNotEmpty ? customBlockIps : null,
      );

      final error = await _coreService.start(fullConfig);
      if (error != null) {
        Logger.app.error('Core error: $error');
        ref.read(lastConnectionErrorProvider.notifier).error = error;
        state = ConnectionStatus.error;
        return;
      }

      // If VPN mode, start TUN
      if (coreMode == 'vpn') {
        Logger.app.info('Starting TUN for VPN mode...');
        
        // Check if TUN assets are available
        if (!await _tunService.isAvailable()) {
          Logger.app.info('Downloading TUN assets...');
          try {
            await _tunService.ensureAssets();
          } catch (e) {
            Logger.app.error('Failed to download TUN assets: $e');
            await _coreService.stop();
            ref.read(lastConnectionErrorProvider.notifier).error =
                'TUN assets not available: $e';
            state = ConnectionStatus.error;
            return;
          }
        }

        final tunError = await _tunService.start(
          socksAddr: '127.0.0.1:$socksPort',
        );
        
        if (tunError != null) {
          Logger.app.error('TUN error: $tunError');
          await _coreService.stop();
          ref.read(lastConnectionErrorProvider.notifier).error =
              'TUN: $tunError';
          state = ConnectionStatus.error;
          return;
        }
        
        Logger.app.info('TUN started successfully');
      }

      Logger.app.info('Connected successfully to ${config.name}');
      state = ConnectionStatus.connected;
    } catch (e, stackTrace) {
      final errorMsg = e.toString();
      Logger.app.error('Connection failed: $errorMsg', e, stackTrace);
      ref.read(lastConnectionErrorProvider.notifier).error = errorMsg;
      state = ConnectionStatus.error;
    }
  }

  Future<void> disconnect() async {
    Logger.app.info('Disconnecting...');
    
    // Stop TUN first if running
    if (_tunService.isRunning) {
      Logger.app.info('Stopping TUN...');
      await _tunService.stop();
    }
    
    await _coreService.stop();
    
    // Stop Hysteria if running
    if (_hysteriaService.isRunning) {
      Logger.app.info('Stopping Hysteria...');
      await _hysteriaService.stop();
    }
    _isHysteriaMode = false;
    
    ref.read(lastConnectionErrorProvider.notifier).clear();
    state = ConnectionStatus.disconnected;
    Logger.app.info('Disconnected');
  }

  /// Clear error state
  void clearError() {
    if (state == ConnectionStatus.error) {
      ref.read(lastConnectionErrorProvider.notifier).clear();
      state = ConnectionStatus.disconnected;
    }
  }

  /// Check if VPN mode is available
  Future<bool> isVpnAvailable() => _tunService.isAvailable();

  /// Download TUN assets
  Future<void> downloadTunAssets({
    void Function(double progress, String status)? onProgress,
  }) => _tunService.ensureAssets(onProgress: onProgress);
}
