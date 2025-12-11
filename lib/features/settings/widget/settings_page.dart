import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hiddify/core/logger/log_viewer_page.dart';
import 'package:hiddify/features/settings/model/core_preferences.dart';
import 'package:hiddify/features/settings/model/dns_settings.dart';
import 'package:hiddify/features/settings/model/fragment_settings.dart';
import 'package:hiddify/features/settings/model/inbound_settings.dart';
import 'package:hiddify/features/settings/model/mux_settings.dart';
import 'package:hiddify/features/settings/model/routing_settings.dart';
import 'package:hiddify/features/settings/model/sockopt_settings.dart';
import 'package:hiddify/features/settings/model/tls_settings.dart';
import 'package:hiddify/features/system/data/system_optimization_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Core Settings
    final coreMode = ref.watch(CorePreferences.coreMode);
    final enableLogging = ref.watch(CorePreferences.enableLogging);
    final logLevel = ref.watch(CorePreferences.logLevel);

    // Inbound Settings
    final socksPort = ref.watch(InboundSettings.socksPort);
    final httpPort = ref.watch(InboundSettings.httpPort);
    final enableSniffing = ref.watch(InboundSettings.sniffingEnabled);

    // TLS Settings
    final allowInsecure = ref.watch(TlsSettings.allowInsecure);
    final fingerPrint = ref.watch(TlsSettings.fingerprint);
    final alpn = ref.watch(TlsSettings.alpn);

    // MUX Settings
    final enableMux = ref.watch(MuxSettings.enabled);
    final muxConcurrency = ref.watch(MuxSettings.concurrency);
    final muxPadding = ref.watch(MuxSettings.padding);

    // DNS Settings
    final remoteDns = ref.watch(DnsSettings.remoteDns);
    final directDns = ref.watch(DnsSettings.directDns);
    final dnsQueryStrategy = ref.watch(DnsSettings.queryStrategy);
    final enableFakeDns = ref.watch(DnsSettings.enableFakeDns);

    // Routing Settings
    final domainStrategy = ref.watch(RoutingSettings.domainStrategy);
    final bypassLan = ref.watch(RoutingSettings.bypassLan);
    final bypassIran = ref.watch(RoutingSettings.bypassIran);
    final bypassChina = ref.watch(RoutingSettings.bypassChina);
    final blockAds = ref.watch(RoutingSettings.blockAds);
    final blockQuic = ref.watch(RoutingSettings.blockQuic);

    // Fragment Settings (GFW-knocker)
    final enableFragment = ref.watch(FragmentSettings.enabled);
    final fragmentPackets = ref.watch(FragmentSettings.packets);
    final fragmentLength = ref.watch(FragmentSettings.length);
    final fragmentInterval = ref.watch(FragmentSettings.interval);

    // Noise Settings (GFW-knocker)
    final enableNoise = ref.watch(FragmentSettings.noiseEnabled);
    final noiseType = ref.watch(FragmentSettings.noiseType);
    final noisePacket = ref.watch(FragmentSettings.noisePacket);
    final noiseDelay = ref.watch(FragmentSettings.noiseDelay);

    // Security Settings
    final blockMalware = ref.watch(RoutingSettings.blockMalware);
    final blockPhishing = ref.watch(RoutingSettings.blockPhishing);

    // Sockopt Settings
    final tcpFastOpen = ref.watch(SockoptSettings.tcpFastOpen);
    final tcpCongestion = ref.watch(SockoptSettings.tcpCongestion);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Settings'),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // Connectivity Section
                _SectionHeader(title: 'Connectivity', icon: Icons.wifi_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.dns_rounded,
                      title: 'Core Mode',
                      subtitle: coreMode == 'vpn' ? 'VPN (Tunnel)' : 'Proxy Mode',
                      trailing: _ModernDropdown<String>(
                        value: coreMode,
                        items: const {'proxy': 'Proxy', 'vpn': 'VPN'},
                        onChanged: (val) {
                          if (val != null) unawaited(ref.read(CorePreferences.coreMode.notifier).update(val));
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.domain_rounded,
                      title: 'Domain Strategy',
                      trailing: _ModernDropdown<String>(
                        value: domainStrategy,
                        items: const {'IPIfNonMatch': 'IPIfNonMatch', 'IPOnDemand': 'IPOnDemand', 'AsIs': 'AsIs'},
                        onChanged: (v) => unawaited(ref.read(RoutingSettings.domainStrategy.notifier).update(v!)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Routing Section
                _SectionHeader(title: 'Routing', icon: Icons.route_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.home_rounded,
                      title: 'Bypass LAN',
                      subtitle: 'Direct local network',
                      trailing: Switch(
                        value: bypassLan,
                        onChanged: (v) => ref.read(RoutingSettings.bypassLan.notifier).update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.flag_rounded,
                      title: 'Bypass Iran',
                      subtitle: 'Direct Iran websites',
                      trailing: Switch(
                        value: bypassIran,
                        onChanged: (v) => ref.read(RoutingSettings.bypassIran.notifier).update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.public_rounded,
                      title: 'Bypass China',
                      subtitle: 'Direct China websites',
                      trailing: Switch(
                        value: bypassChina,
                        onChanged: (v) => ref.read(RoutingSettings.bypassChina.notifier).update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.block_rounded,
                      title: 'Block Ads',
                      subtitle: 'Block advertisements',
                      trailing: Switch(
                        value: blockAds,
                        onChanged: (v) => ref.read(RoutingSettings.blockAds.notifier).update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.speed_rounded,
                      title: 'Block QUIC',
                      subtitle: 'Force TLS for better XTLS',
                      trailing: Switch(
                        value: blockQuic,
                        onChanged: (v) => ref.read(RoutingSettings.blockQuic.notifier).update(v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Inbound Settings
                _SectionHeader(title: 'Inbound Settings', icon: Icons.input_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.numbers_rounded,
                      title: 'SOCKS Port',
                      trailing: SizedBox(
                        width: 90,
                        child: TextField(
                          controller: TextEditingController(text: socksPort.toString()),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                          onSubmitted: (v) => ref.read(InboundSettings.socksPort.notifier).update(int.tryParse(v) ?? 2334),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.http_rounded,
                      title: 'HTTP Port',
                      trailing: SizedBox(
                        width: 90,
                        child: TextField(
                          controller: TextEditingController(text: httpPort.toString()),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                          onSubmitted: (v) => ref.read(InboundSettings.httpPort.notifier).update(int.tryParse(v) ?? 2335),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.search_rounded,
                      title: 'Enable Sniffing',
                      subtitle: 'Detect protocol type',
                      trailing: Switch(
                        value: enableSniffing,
                        onChanged: (v) => ref.read(InboundSettings.sniffingEnabled.notifier).update(v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // TLS & Security
                _SectionHeader(title: 'TLS & Security', icon: Icons.security_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.warning_amber_rounded,
                      title: 'Allow Insecure',
                      subtitle: 'Skip TLS verification',
                      isDanger: true,
                      trailing: Switch(
                        value: allowInsecure,
                        onChanged: (v) => ref.read(TlsSettings.allowInsecure.notifier).update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'TLS Fingerprint',
                      trailing: _ModernDropdown<String>(
                        value: fingerPrint,
                        items: const {
                          'chrome': 'Chrome',
                          'firefox': 'Firefox',
                          'safari': 'Safari',
                          'ios': 'iOS',
                          'android': 'Android',
                          'edge': 'Edge',
                          'random': 'Random',
                          'randomized': 'Randomized',
                        },
                        onChanged: (v) => ref.read(TlsSettings.fingerprint.notifier).update(v!),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.text_fields_rounded,
                      title: 'ALPN',
                      trailing: _ModernDropdown<String>(
                        value: alpn,
                        items: const {
                          'h2,http/1.1': 'H2, HTTP/1.1',
                          'h2': 'H2 Only',
                          'http/1.1': 'HTTP/1.1 Only',
                        },
                        onChanged: (v) => ref.read(TlsSettings.alpn.notifier).update(v!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // MUX Settings
                _SectionHeader(title: 'MUX', icon: Icons.merge_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.merge_rounded,
                      title: 'Enable MUX',
                      subtitle: 'Multiplex connections',
                      trailing: Switch(
                        value: enableMux,
                        onChanged: (v) => ref.read(MuxSettings.enabled.notifier).update(v),
                      ),
                    ),
                    if (enableMux) ...[
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.tune_rounded,
                        title: 'Concurrency',
                        trailing: _ModernDropdown<int>(
                          value: muxConcurrency,
                          items: const {1: '1', 2: '2', 4: '4', 8: '8', 16: '16', 32: '32'},
                          onChanged: (v) => ref.read(MuxSettings.concurrency.notifier).update(v ?? 8),
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.padding_rounded,
                        title: 'Enable Padding',
                        subtitle: 'Add padding to packets',
                        trailing: Switch(
                          value: muxPadding,
                          onChanged: (v) => ref.read(MuxSettings.padding.notifier).update(v),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // DNS Settings
                _SectionHeader(title: 'DNS', icon: Icons.dns_outlined, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.cloud_rounded,
                      title: 'Remote DNS',
                      trailing: SizedBox(
                        width: 140,
                        child: TextField(
                          controller: TextEditingController(text: remoteDns),
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                            hintText: '8.8.8.8',
                          ),
                          onSubmitted: (v) => ref.read(DnsSettings.remoteDns.notifier).update(v),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.computer_rounded,
                      title: 'Direct DNS',
                      trailing: SizedBox(
                        width: 140,
                        child: TextField(
                          controller: TextEditingController(text: directDns),
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                            hintText: '1.1.1.1',
                          ),
                          onSubmitted: (v) => ref.read(DnsSettings.directDns.notifier).update(v),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Query Strategy',
                      trailing: _ModernDropdown<String>(
                        value: dnsQueryStrategy,
                        items: const {'UseIP': 'UseIP', 'UseIPv4': 'UseIPv4', 'UseIPv6': 'UseIPv6'},
                        onChanged: (v) => ref.read(DnsSettings.queryStrategy.notifier).update(v!),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.masks_rounded,
                      title: 'Enable FakeDNS',
                      subtitle: 'Virtual DNS for sniffing',
                      trailing: Switch(
                        value: enableFakeDns,
                        onChanged: (v) => ref.read(DnsSettings.enableFakeDns.notifier).update(v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Fragment Settings (GFW-knocker)
                _SectionHeader(title: 'Fragment (Anti-Censorship)', icon: Icons.broken_image_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.broken_image_rounded,
                      title: 'Enable Fragment',
                      subtitle: 'TLS fragmentation for bypass',
                      trailing: Switch(
                        value: enableFragment,
                        onChanged: (v) => ref.read(FragmentSettings.enabled.notifier).update(v),
                      ),
                    ),
                    if (enableFragment) ...[
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.category_rounded,
                        title: 'Packets Type',
                        trailing: _ModernDropdown<String>(
                          value: fragmentPackets,
                          items: const {'tlshello': 'TLS Hello', '1-3': 'TCP 1-3'},
                          onChanged: (v) => ref.read(FragmentSettings.packets.notifier).update(v!),
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.straighten_rounded,
                        title: 'Length',
                        trailing: SizedBox(
                          width: 100,
                          child: TextField(
                            controller: TextEditingController(text: fragmentLength),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                              hintText: '100-200',
                            ),
                            onSubmitted: (v) => ref.read(FragmentSettings.length.notifier).update(v),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.timer_rounded,
                        title: 'Interval (ms)',
                        trailing: SizedBox(
                          width: 100,
                          child: TextField(
                            controller: TextEditingController(text: fragmentInterval),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                              hintText: '10-20',
                            ),
                            onSubmitted: (v) => ref.read(FragmentSettings.interval.notifier).update(v),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // Noise Settings (GFW-knocker)
                _SectionHeader(title: 'Noise (Anti-DPI)', icon: Icons.waves_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.waves_rounded,
                      title: 'Enable Noise',
                      subtitle: 'UDP noise injection',
                      trailing: Switch(
                        value: enableNoise,
                        onChanged: (v) => ref.read(FragmentSettings.noiseEnabled.notifier).update(v),
                      ),
                    ),
                    if (enableNoise) ...[
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.shuffle_rounded,
                        title: 'Noise Type',
                        trailing: _ModernDropdown<String>(
                          value: noiseType,
                          items: const {'rand': 'Random', 'str': 'String', 'base64': 'Base64'},
                          onChanged: (v) => ref.read(FragmentSettings.noiseType.notifier).update(v!),
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.data_array_rounded,
                        title: 'Packet Size',
                        trailing: SizedBox(
                          width: 100,
                          child: TextField(
                            controller: TextEditingController(text: noisePacket),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                              hintText: '10-20',
                            ),
                            onSubmitted: (v) => ref.read(FragmentSettings.noisePacket.notifier).update(v),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.timer_outlined,
                        title: 'Delay (ms)',
                        trailing: SizedBox(
                          width: 100,
                          child: TextField(
                            controller: TextEditingController(text: noiseDelay),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                              hintText: '10-16',
                            ),
                            onSubmitted: (v) => ref.read(FragmentSettings.noiseDelay.notifier).update(v),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // Security Settings
                _SectionHeader(title: 'Security', icon: Icons.shield_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.bug_report_outlined,
                      title: 'Block Malware',
                      subtitle: 'Block malicious domains',
                      trailing: Switch(
                        value: blockMalware,
                        onChanged: (v) => ref.read(RoutingSettings.blockMalware.notifier).update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.phishing_outlined,
                      title: 'Block Phishing',
                      subtitle: 'Block phishing sites',
                      trailing: Switch(
                        value: blockPhishing,
                        onChanged: (v) => ref.read(RoutingSettings.blockPhishing.notifier).update(v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Advanced Settings
                _SectionHeader(title: 'Advanced', icon: Icons.settings_applications_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.flash_on_rounded,
                      title: 'TCP Fast Open',
                      subtitle: 'Reduce connection latency',
                      trailing: Switch(
                        value: tcpFastOpen,
                        onChanged: (v) => ref.read(SockoptSettings.tcpFastOpen.notifier).update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.speed_rounded,
                      title: 'TCP Congestion',
                      trailing: _ModernDropdown<String>(
                        value: tcpCongestion.isEmpty ? '' : tcpCongestion,
                        items: const {'': 'Default', 'bbr': 'BBR', 'cubic': 'Cubic'},
                        onChanged: (v) => ref.read(SockoptSettings.tcpCongestion.notifier).update(v ?? ''),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // System Section
                if (Platform.isAndroid) ...[
                  _SectionHeader(title: 'System', icon: Icons.phone_android_rounded, colorScheme: colorScheme),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.battery_saver_rounded,
                        title: 'Battery Optimization',
                        subtitle: 'Disable for stable background',
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            await ref.read(systemOptimizationServiceProvider).requestDisableBatteryOptimization();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Requested battery exemption'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                          child: const Text('Disable'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Logging Section
                _SectionHeader(title: 'Logging & Debug', icon: Icons.bug_report_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.article_rounded,
                      title: 'Enable Core Logs',
                      subtitle: 'Log engine activity',
                      trailing: Switch(
                        value: enableLogging,
                        onChanged: (val) => ref.read(CorePreferences.enableLogging.notifier).update(val),
                      ),
                    ),
                    if (enableLogging) ...[
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.tune_rounded,
                        title: 'Log Level',
                        trailing: _ModernDropdown<String>(
                          value: logLevel,
                          items: const {'none': 'None', 'error': 'Error', 'warning': 'Warning', 'info': 'Info', 'debug': 'Debug'},
                          onChanged: (val) {
                            if (val != null) unawaited(ref.read(CorePreferences.logLevel.notifier).update(val));
                          },
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.visibility_rounded,
                      title: 'View Logs',
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LogViewerPage())),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // About Section
                _SectionHeader(title: 'About', icon: Icons.info_outline_rounded, colorScheme: colorScheme),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.shield_rounded, color: colorScheme.onPrimaryContainer, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hiddify', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Version 3.0.0-preview.1', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon, required this.colorScheme});

  final String title;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing, this.subtitle,
    this.isDanger = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final bool isDanger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDanger ? colorScheme.errorContainer : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDanger ? colorScheme.error : colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDanger ? colorScheme.error : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ModernDropdown<T> extends StatelessWidget {
  const _ModernDropdown({required this.value, required this.items, required this.onChanged});

  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
