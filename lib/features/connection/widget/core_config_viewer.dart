import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/features/connection/logic/core_configurator.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hiddify/features/settings/model/core_preferences.dart';
import 'package:hiddify/features/settings/model/dns_settings.dart';
import 'package:hiddify/features/settings/model/fragment_settings.dart';
import 'package:hiddify/features/settings/model/inbound_settings.dart';
import 'package:hiddify/features/settings/model/mux_settings.dart';
import 'package:hiddify/features/settings/model/routing_settings.dart';
import 'package:hiddify/features/settings/model/sockopt_settings.dart';
import 'package:hiddify/features/settings/model/tls_settings.dart';
import 'package:hiddify/core/logger/log_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CoreConfigViewer extends HookConsumerWidget {
  const CoreConfigViewer({
    required this.config,
    super.key,
  });

  final Config config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Core Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
               final jsonString = await _generateConfig(ref);
               if (context.mounted) {
                 await Clipboard.setData(ClipboardData(text: jsonString));
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Config copied to clipboard')),
                 );
               }
            },
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _generateConfig(ref),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              // Simple JSON formatting
              _prettyPrintJson(snapshot.data!),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  Future<String> _generateConfig(WidgetRef ref) async {
      // Re-read all providers to generate the exact config that would be used
      // This duplicates the logic in ConnectionNotifier.connect somewhat, 
      // but ensures we see the current state of settings + config
      
      final coreMode = ref.read(CorePreferences.coreMode);
      final logLevel = ref.read(CorePreferences.logLevel);
      final enableLogging = ref.read(CorePreferences.enableLogging);

      final socksPort = ref.read(InboundSettings.socksPort);
      final httpPort = ref.read(InboundSettings.httpPort);
      final enableSniffing = ref.read(InboundSettings.sniffingEnabled);
      final sniffingDestOverride = ref.read(InboundSettings.sniffingDestOverride);

      final allowInsecure = ref.read(TlsSettings.allowInsecure);
      final fingerPrint = ref.read(TlsSettings.fingerprint);
      final alpn = ref.read(TlsSettings.alpn);

      final enableMux = ref.read(MuxSettings.enabled);
      final muxConcurrency = ref.read(MuxSettings.concurrency);
      final muxPadding = ref.read(MuxSettings.padding);
      final xudpConcurrency = ref.read(MuxSettings.xudpConcurrency);
      final xudpProxyUDP443 = ref.read(MuxSettings.xudpProxyUDP443);

      final remoteDns = ref.read(DnsSettings.remoteDns);
      final directDns = ref.read(DnsSettings.directDns);
      final dnsQueryStrategy = ref.read(DnsSettings.queryStrategy);
      final enableFakeDns = ref.read(DnsSettings.enableFakeDns);

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

      final enableFragment = ref.read(FragmentSettings.enabled);
      final fragmentPackets = ref.read(FragmentSettings.packets);
      final fragmentLength = ref.read(FragmentSettings.length);
      final fragmentInterval = ref.read(FragmentSettings.interval);

      final enableNoise = ref.read(FragmentSettings.noiseEnabled);
      final noiseType = ref.read(FragmentSettings.noiseType);
      final noisePacket = ref.read(FragmentSettings.noisePacket);
      final noiseDelay = ref.read(FragmentSettings.noiseDelay);

      final blockMalware = ref.read(RoutingSettings.blockMalware);
      final blockPhishing = ref.read(RoutingSettings.blockPhishing);

      final tcpFastOpen = ref.read(SockoptSettings.tcpFastOpen);
      final tcpCongestion = ref.read(SockoptSettings.tcpCongestion);
      
      final accessLogPath = await ref.read(logServiceProvider).getAccessLogPath();
      final errorLogPath = await ref.read(logServiceProvider).getCoreLogPath();

      return CoreConfigurator.generateConfig(
        activeConfig: config,
        coreMode: coreMode,
        logLevel: logLevel,
        enableLogging: enableLogging,
        accessLogPath: accessLogPath,
        errorLogPath: errorLogPath,
        socksPort: socksPort,
        httpPort: httpPort,
        domainStrategy: domainStrategy,
        allowInsecure: allowInsecure,
        fingerPrint: fingerPrint,
        alpn: alpn,
        enableMux: enableMux,
        muxConcurrency: muxConcurrency,
        muxPadding: muxPadding,
        xudpConcurrency: xudpConcurrency,
        xudpProxyUDP443: xudpProxyUDP443,
        remoteDns: remoteDns,
        directDns: directDns,
        dnsQueryStrategy: dnsQueryStrategy,
        enableFakeDns: enableFakeDns,
        bypassLan: bypassLan,
        bypassIran: bypassIran,
        bypassChina: bypassChina,
        blockAds: blockAds,
        blockQuic: blockQuic,
        enableFragment: enableFragment,
        fragmentPackets: fragmentPackets,
        fragmentLength: fragmentLength,
        fragmentInterval: fragmentInterval,
        enableNoise: enableNoise,
        noiseType: noiseType,
        noisePacket: noisePacket,
        noiseDelay: noiseDelay,
        enableSniffing: enableSniffing,
        sniffingDestOverride: sniffingDestOverride,
        tcpFastOpen: tcpFastOpen,
        tcpCongestion: tcpCongestion,
        blockMalware: blockMalware,
        blockPhishing: blockPhishing,
        customDirectDomains: customDirectDomains.isNotEmpty ? customDirectDomains : null,
        customProxyDomains: customProxyDomains.isNotEmpty ? customProxyDomains : null,
        customBlockDomains: customBlockDomains.isNotEmpty ? customBlockDomains : null,
      );
  }

  String _prettyPrintJson(String jsonString) {
    try {
      final jsonObject = jsonDecode(jsonString);
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObject);
    } catch (e) {
      return jsonString;
    }
  }
}
