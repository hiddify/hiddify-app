import 'package:hiddify/core/logger/log_service.dart';
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

  void setError(String? error) => state = error;
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
      final socksPort = ref.read(InboundSettings.socksPort);
      final httpPort = ref.read(InboundSettings.httpPort);
      final enableSniffing = ref.read(InboundSettings.sniffingEnabled);
      final sniffingDestOverride = ref.read(InboundSettings.sniffingDestOverride);

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
      final remoteDns = ref.read(DnsSettings.remoteDns);
      final directDns = ref.read(DnsSettings.directDns);
      final dnsQueryStrategy = ref.read(DnsSettings.queryStrategy);
      final enableFakeDns = ref.read(DnsSettings.enableFakeDns);

      // Routing Settings
      final domainStrategy = ref.read(RoutingSettings.domainStrategy);
      final bypassLan = ref.read(RoutingSettings.bypassLan);
      final bypassIran = ref.read(RoutingSettings.bypassIran);
      final bypassChina = ref.read(RoutingSettings.bypassChina);
      final blockAds = ref.read(RoutingSettings.blockAds);
      final blockQuic = ref.read(RoutingSettings.blockQuic);
      final customDirectDomains = RoutingSettings.parseCustomRules(
        ref.read(RoutingSettings.customDirectDomains),
      );
      final customProxyDomains = RoutingSettings.parseCustomRules(
        ref.read(RoutingSettings.customProxyDomains),
      );
      final customBlockDomains = RoutingSettings.parseCustomRules(
        ref.read(RoutingSettings.customBlockDomains),
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
      final blockMalware = ref.read(RoutingSettings.blockMalware);
      final blockPhishing = ref.read(RoutingSettings.blockPhishing);

      // Sockopt Settings
      final tcpFastOpen = ref.read(SockoptSettings.tcpFastOpen);
      final tcpCongestion = ref.read(SockoptSettings.tcpCongestion);

      // Log paths
      final accessLogPath = await ref.read(logServiceProvider).getAccessLogPath();
      final errorLogPath = await ref.read(logServiceProvider).getCoreLogPath();

      // Check if this is a Hysteria config
      _isHysteriaMode = _isHysteriaProtocol(config.content);
      
      Config effectiveConfig = config;
      
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
          localPort: hysteriaLocalPort,
        );
        
        if (hysteriaError != null) {
          Logger.app.error('Hysteria error: $hysteriaError');
          ref.read(lastConnectionErrorProvider.notifier).setError('Hysteria: $hysteriaError');
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
        remoteDns: remoteDns,
        directDns: directDns,
        dnsQueryStrategy: dnsQueryStrategy,
        enableFakeDns: enableFakeDns,
        // Routing
        bypassLan: bypassLan,
        bypassIran: bypassIran,
        bypassChina: bypassChina,
        blockAds: blockAds,
        blockQuic: blockQuic,
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
        // Sockopt
        tcpFastOpen: tcpFastOpen,
        tcpCongestion: tcpCongestion,
        // Security
        blockMalware: blockMalware,
        blockPhishing: blockPhishing,
        // Custom rules
        customDirectDomains: customDirectDomains.isNotEmpty ? customDirectDomains : null,
        customProxyDomains: customProxyDomains.isNotEmpty ? customProxyDomains : null,
        customBlockDomains: customBlockDomains.isNotEmpty ? customBlockDomains : null,
      );

      final error = await _coreService.start(fullConfig);
      if (error != null) {
        Logger.app.error('Core error: $error');
        ref.read(lastConnectionErrorProvider.notifier).setError(error);
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
            ref.read(lastConnectionErrorProvider.notifier).setError('TUN assets not available: $e');
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
          ref.read(lastConnectionErrorProvider.notifier).setError('TUN: $tunError');
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
      ref.read(lastConnectionErrorProvider.notifier).setError(errorMsg);
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
