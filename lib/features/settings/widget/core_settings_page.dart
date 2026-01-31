import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/config/config.dart';
import 'package:hiddify/features/connection/connection.dart';
import 'package:hiddify/features/settings/settings.dart';
import 'package:hiddify/features/system/system.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CoreSettingsPage extends HookConsumerWidget {
  const CoreSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = ref.watch(translationsProvider);
    final appInfo = ref.watch(appInfoProvider);
    final coreMode = ref.watch(CorePreferences.coreMode);
    final enableLogging = ref.watch(CorePreferences.enableLogging);
    final logLevel = ref.watch(CorePreferences.logLevel);

    final debugMode = ref.watch(debugModeProvider);
    final socksPort = ref.watch(InboundSettings.socksPort);
    final httpPort = ref.watch(InboundSettings.httpPort);
    final enableSniffing = ref.watch(InboundSettings.sniffingEnabled);
    final allowInsecure = ref.watch(TlsSettings.allowInsecure);
    final fingerPrint = ref.watch(TlsSettings.fingerprint);
    final alpn = ref.watch(TlsSettings.alpn);
    final enableMux = ref.watch(MuxSettings.enabled);
    final muxConcurrency = ref.watch(MuxSettings.concurrency);
    final muxPadding = ref.watch(MuxSettings.padding);
    final remoteDns = ref.watch(DnsSettings.remoteDns);
    final directDns = ref.watch(DnsSettings.directDns);
    final dnsQueryStrategy = ref.watch(DnsSettings.queryStrategy);
    final enableFakeDns = ref.watch(DnsSettings.enableFakeDns);
    final domainStrategy = ref.watch(RoutingSettings.domainStrategy);
    final bypassLan = ref.watch(RoutingSettings.bypassLan);
    final bypassIran = ref.watch(RoutingSettings.bypassIran);
    final bypassChina = ref.watch(RoutingSettings.bypassChina);
    final blockAds = ref.watch(RoutingSettings.blockAds);
    final blockQuic = ref.watch(RoutingSettings.blockQuic);
    final enableFragment = ref.watch(FragmentSettings.enabled);
    final fragmentPackets = ref.watch(FragmentSettings.packets);
    final fragmentLength = ref.watch(FragmentSettings.length);
    final fragmentInterval = ref.watch(FragmentSettings.interval);
    final enableNoise = ref.watch(FragmentSettings.noiseEnabled);
    final noiseType = ref.watch(FragmentSettings.noiseType);
    final noisePacket = ref.watch(FragmentSettings.noisePacket);
    final noiseDelay = ref.watch(FragmentSettings.noiseDelay);
    final blockMalware = ref.watch(RoutingSettings.blockMalware);
    final blockPhishing = ref.watch(RoutingSettings.blockPhishing);
    final tcpFastOpen = ref.watch(SockoptSettings.tcpFastOpen);
    final tcpCongestion = ref.watch(SockoptSettings.tcpCongestion);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Core Settings'),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                const AppSectionHeader(
                  title: 'Connectivity',
                  icon: Icons.wifi_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.dns_rounded,
                      title: 'Core Mode',
                      subtitle: coreMode == 'vpn'
                          ? 'VPN (Tunnel)'
                          : 'Proxy Mode',
                      trailing: AppDropdown<String>(
                        value: coreMode,
                        items: const {'proxy': 'Proxy', 'vpn': 'VPN'},
                        onChanged: (val) {
                          if (val != null) {
                            unawaited(
                              ref
                                  .read(CorePreferences.coreMode.notifier)
                                  .update(val),
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.domain_rounded,
                      title: 'Domain Strategy',
                      trailing: AppDropdown<String>(
                        value: domainStrategy,
                        items: const {
                          'IPIfNonMatch': 'IPIfNonMatch',
                          'IPOnDemand': 'IPOnDemand',
                          'AsIs': 'AsIs',
                        },
                        onChanged: (v) => unawaited(
                          ref
                              .read(RoutingSettings.domainStrategy.notifier)
                              .update(v!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Routing',
                  icon: Icons.route_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.home_rounded,
                      title: 'Bypass LAN',
                      subtitle: 'Direct local network',
                      trailing: Switch(
                        value: bypassLan,
                        onChanged: (v) => ref
                            .read(RoutingSettings.bypassLan.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.flag_rounded,
                      title: 'Bypass Iran',
                      subtitle: 'Direct Iran websites',
                      trailing: Switch(
                        value: bypassIran,
                        onChanged: (v) => ref
                            .read(RoutingSettings.bypassIran.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.public_rounded,
                      title: 'Bypass China',
                      subtitle: 'Direct China websites',
                      trailing: Switch(
                        value: bypassChina,
                        onChanged: (v) => ref
                            .read(RoutingSettings.bypassChina.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.block_rounded,
                      title: 'Block Ads',
                      subtitle: 'Block advertisements',
                      trailing: Switch(
                        value: blockAds,
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockAds.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.speed_rounded,
                      title: 'Block QUIC',
                      subtitle: 'Force TLS for better XTLS',
                      trailing: Switch(
                        value: blockQuic,
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockQuic.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Inbound Settings',
                  icon: Icons.input_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppTextFieldTile(
                      icon: Icons.numbers_rounded,
                      title: 'SOCKS Port',
                      value: socksPort.toString(),
                      keyboardType: TextInputType.number,
                      onSubmitted: (v) => ref
                          .read(InboundSettings.socksPort.notifier)
                          .update(int.tryParse(v) ?? 2334),
                    ),
                    const Divider(height: 1),
                    AppTextFieldTile(
                      icon: Icons.http_rounded,
                      title: 'HTTP Port',
                      value: httpPort.toString(),
                      keyboardType: TextInputType.number,
                      onSubmitted: (v) => ref
                          .read(InboundSettings.httpPort.notifier)
                          .update(int.tryParse(v) ?? 2335),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.search_rounded,
                      title: 'Enable Sniffing',
                      subtitle: 'Detect protocol type',
                      trailing: Switch(
                        value: enableSniffing,
                        onChanged: (v) => ref
                            .read(InboundSettings.sniffingEnabled.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'TLS & Security',
                  icon: Icons.security_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.warning_amber_rounded,
                      title: 'Allow Insecure',
                      subtitle: 'Skip TLS verification',
                      isDanger: true,
                      trailing: Switch(
                        value: allowInsecure,
                        onChanged: (v) => ref
                            .read(TlsSettings.allowInsecure.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'TLS Fingerprint',
                      trailing: AppDropdown<String>(
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
                        onChanged: (v) => ref
                            .read(TlsSettings.fingerprint.notifier)
                            .update(v!),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.text_fields_rounded,
                      title: 'ALPN',
                      trailing: AppDropdown<String>(
                        value: alpn,
                        items: const {
                          'h2,http/1.1': 'H2, HTTP/1.1',
                          'h2': 'H2 Only',
                          'http/1.1': 'HTTP/1.1 Only',
                        },
                        onChanged: (v) =>
                            ref.read(TlsSettings.alpn.notifier).update(v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'MUX',
                  icon: Icons.merge_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.merge_rounded,
                      title: 'Enable MUX',
                      subtitle: 'Multiplex connections',
                      trailing: Switch(
                        value: enableMux,
                        onChanged: (v) =>
                            ref.read(MuxSettings.enabled.notifier).update(v),
                      ),
                    ),
                    if (enableMux) ...[
                      const Divider(height: 1),
                      AppSettingsTile(
                        icon: Icons.tune_rounded,
                        title: 'Concurrency',
                        trailing: AppDropdown<int>(
                          value: muxConcurrency,
                          items: const {
                            1: '1',
                            2: '2',
                            4: '4',
                            8: '8',
                            16: '16',
                            32: '32',
                          },
                          onChanged: (v) => ref
                              .read(MuxSettings.concurrency.notifier)
                              .update(v ?? 8),
                        ),
                      ),
                      const Divider(height: 1),
                      AppSettingsTile(
                        icon: Icons.padding_rounded,
                        title: 'Enable Padding',
                        subtitle: 'Add padding to packets',
                        trailing: Switch(
                          value: muxPadding,
                          onChanged: (v) =>
                              ref.read(MuxSettings.padding.notifier).update(v),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'DNS',
                  icon: Icons.dns_outlined,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppTextFieldTile(
                      icon: Icons.cloud_rounded,
                      title: 'Remote DNS',
                      value: remoteDns,
                      width: 140,
                      hintText: '8.8.8.8',
                      textAlign: TextAlign.end,
                      onSubmitted: (v) =>
                          ref.read(DnsSettings.remoteDns.notifier).update(v),
                    ),
                    const Divider(height: 1),
                    AppTextFieldTile(
                      icon: Icons.computer_rounded,
                      title: 'Direct DNS',
                      value: directDns,
                      width: 140,
                      hintText: '1.1.1.1',
                      textAlign: TextAlign.end,
                      onSubmitted: (v) =>
                          ref.read(DnsSettings.directDns.notifier).update(v),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Query Strategy',
                      trailing: AppDropdown<String>(
                        value: dnsQueryStrategy,
                        items: const {
                          'UseIP': 'UseIP',
                          'UseIPv4': 'UseIPv4',
                          'UseIPv6': 'UseIPv6',
                        },
                        onChanged: (v) => ref
                            .read(DnsSettings.queryStrategy.notifier)
                            .update(v!),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.masks_rounded,
                      title: 'Enable FakeDNS',
                      subtitle: 'Virtual DNS for sniffing',
                      trailing: Switch(
                        value: enableFakeDns,
                        onChanged: (v) => ref
                            .read(DnsSettings.enableFakeDns.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Fragment (Anti-Censorship)',
                  icon: Icons.broken_image_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.broken_image_rounded,
                      title: 'Enable Fragment',
                      subtitle: 'TLS fragmentation for bypass',
                      trailing: Switch(
                        value: enableFragment,
                        onChanged: (v) => ref
                            .read(FragmentSettings.enabled.notifier)
                            .update(v),
                      ),
                    ),
                    if (enableFragment) ...[
                      const Divider(height: 1),
                      AppSettingsTile(
                        icon: Icons.category_rounded,
                        title: 'Packets Type',
                        trailing: AppDropdown<String>(
                          value: fragmentPackets,
                          items: const {
                            'tlshello': 'TLS Hello',
                            '1-3': 'TCP 1-3',
                          },
                          onChanged: (v) => ref
                              .read(FragmentSettings.packets.notifier)
                              .update(v!),
                        ),
                      ),
                      const Divider(height: 1),
                      AppTextFieldTile(
                        icon: Icons.straighten_rounded,
                        title: 'Length',
                        value: fragmentLength,
                        width: 100,
                        hintText: '100-200',
                        onSubmitted: (v) => ref
                            .read(FragmentSettings.length.notifier)
                            .update(v),
                      ),
                      const Divider(height: 1),
                      AppTextFieldTile(
                        icon: Icons.timer_rounded,
                        title: 'Interval (ms)',
                        value: fragmentInterval,
                        width: 100,
                        hintText: '10-20',
                        onSubmitted: (v) => ref
                            .read(FragmentSettings.interval.notifier)
                            .update(v),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Noise (Anti-DPI)',
                  icon: Icons.waves_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.waves_rounded,
                      title: 'Enable Noise',
                      subtitle: 'UDP noise injection',
                      trailing: Switch(
                        value: enableNoise,
                        onChanged: (v) => ref
                            .read(FragmentSettings.noiseEnabled.notifier)
                            .update(v),
                      ),
                    ),
                    if (enableNoise) ...[
                      const Divider(height: 1),
                      AppSettingsTile(
                        icon: Icons.shuffle_rounded,
                        title: 'Noise Type',
                        trailing: AppDropdown<String>(
                          value: noiseType,
                          items: const {
                            'rand': 'Random',
                            'str': 'String',
                            'base64': 'Base64',
                          },
                          onChanged: (v) => ref
                              .read(FragmentSettings.noiseType.notifier)
                              .update(v!),
                        ),
                      ),
                      const Divider(height: 1),
                      AppTextFieldTile(
                        icon: Icons.data_array_rounded,
                        title: 'Packet Size',
                        value: noisePacket,
                        width: 100,
                        hintText: '10-20',
                        onSubmitted: (v) => ref
                            .read(FragmentSettings.noisePacket.notifier)
                            .update(v),
                      ),
                      const Divider(height: 1),
                      AppTextFieldTile(
                        icon: Icons.timer_outlined,
                        title: 'Delay (ms)',
                        value: noiseDelay,
                        width: 100,
                        hintText: '10-16',
                        onSubmitted: (v) => ref
                            .read(FragmentSettings.noiseDelay.notifier)
                            .update(v),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Security & Protection',
                  icon: Icons.shield_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.bug_report_outlined,
                      title: 'Block Malware/Viruses',
                      subtitle: 'Internet virus protection',
                      trailing: Switch(
                        value: blockMalware,
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockMalware.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.phishing_outlined,
                      title: 'Block Phishing',
                      subtitle: 'Network attack protection',
                      trailing: Switch(
                        value: blockPhishing,
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockPhishing.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.memory_rounded,
                      title: 'Block Cryptominers',
                      subtitle: 'Prevent unauthorized mining',
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockCryptominers),
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockCryptominers.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.psychology_rounded,
                      title: 'Block Botnet C&C',
                      subtitle: 'Block command & control servers',
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockBotnet),
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockBotnet.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Block Ransomware',
                      subtitle: 'Block ransomware domains',
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockRansomware),
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockRansomware.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.mail_outline_rounded,
                      title: 'Block Spam',
                      subtitle: 'Block spam domains',
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockSpam),
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockSpam.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Content Filtering',
                  icon: Icons.filter_alt_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.no_adult_content_rounded,
                      title: 'Block Adult Content',
                      subtitle: 'Family-safe browsing',
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockPorn),
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockPorn.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.casino_outlined,
                      title: 'Block Gambling',
                      subtitle: 'Block gambling sites',
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockGambling),
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockGambling.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.favorite_outline_rounded,
                      title: 'Block Dating Sites',
                      subtitle: 'Block dating platforms',
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockDating),
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockDating.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.people_outline_rounded,
                      title: 'Block Social Media',
                      subtitle: 'Parental control',
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockSocialMedia),
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockSocialMedia.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Ads & Tracking',
                  icon: Icons.block_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.block_rounded,
                      title: 'Block Advertisements',
                      subtitle: 'Block all ads',
                      trailing: Switch(
                        value: blockAds,
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockAds.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.visibility_off_rounded,
                      title: 'Block Trackers',
                      subtitle: 'Protect your privacy',
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockTrackers),
                        onChanged: (v) => ref
                            .read(RoutingSettings.blockTrackers.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Advanced',
                  icon: Icons.settings_applications_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.flash_on_rounded,
                      title: 'TCP Fast Open',
                      subtitle: 'Reduce connection latency',
                      trailing: Switch(
                        value: tcpFastOpen,
                        onChanged: (v) => ref
                            .read(SockoptSettings.tcpFastOpen.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.speed_rounded,
                      title: 'TCP Congestion',
                      trailing: AppDropdown<String>(
                        value: tcpCongestion.isEmpty ? '' : tcpCongestion,
                        items: const {
                          '': 'Default',
                          'bbr': 'BBR',
                          'cubic': 'Cubic',
                        },
                        onChanged: (v) => ref
                            .read(SockoptSettings.tcpCongestion.notifier)
                            .update(v ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (Platform.isAndroid) ...[
                  const AppSectionHeader(
                    title: 'System',
                    icon: Icons.phone_android_rounded,
                  ),
                  const SizedBox(height: 12),
                  AppSettingsCard(
                    children: [
                      AppSettingsTile(
                        icon: Icons.battery_saver_rounded,
                        title: 'Battery Optimization',
                        subtitle: 'Disable for stable background',
                        trailing: FilledButton.tonal(
                          onPressed: () async {
                            await ref
                                .read(systemOptimizationServiceProvider)
                                .requestDisableBatteryOptimization();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Requested battery exemption',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
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
                const AppSectionHeader(
                  title: 'Logging & Debug',
                  icon: Icons.bug_report_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.article_rounded,
                      title: 'Enable Core Logs',
                      subtitle: 'Log engine activity',
                      trailing: Switch(
                        value: enableLogging,
                        onChanged: (val) => ref
                            .read(CorePreferences.enableLogging.notifier)
                            .update(val),
                      ),
                    ),
                    if (enableLogging) ...[
                      const Divider(height: 1),
                      AppSettingsTile(
                        icon: Icons.tune_rounded,
                        title: 'Log Level',
                        trailing: AppDropdown<String>(
                          value: logLevel,
                          items: const {
                            'none': 'None',
                            'error': 'Error',
                            'warning': 'Warning',
                            'info': 'Info',
                            'debug': 'Debug',
                          },
                          onChanged: (val) {
                            if (val != null) {
                              unawaited(
                                ref
                                    .read(CorePreferences.logLevel.notifier)
                                    .update(val),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.code_rounded,
                      title: 'Debug Mode',
                      subtitle: 'Restart the app for applying this change',
                      trailing: Switch(
                        value: debugMode,
                        onChanged: (val) => unawaited(
                          ref
                              .read(debugModeProvider.notifier)
                              .update(value: val),
                        ),
                      ),
                    ),
                    if (debugMode) ...[
                      const Divider(height: 1),
                      AppSettingsTile(
                        icon: Icons.speed_rounded,
                        title: 'Connection Stress Test',
                        subtitle: 'Run repeated connect/disconnect cycles',
                        trailing: Icon(
                          Icons.play_arrow_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: () =>
                            unawaited(_runConnectionStressTest(context, ref)),
                      ),
                    ],
                    const Divider(height: 1),
                    AppSettingsTile(
                      icon: Icons.visibility_rounded,
                      title: 'View Logs',
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LogViewerPage(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'About',
                  icon: Icons.info_outline_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    InkWell(
                      onTap: () => const AppInfoRoute().push<void>(context),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.shield_rounded,
                                color: colorScheme.onPrimaryContainer,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.general.appTitle,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  appInfo.when(
                                    data: (info) => Text(
                                      '${t.about.version} ${info.version}',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    loading: () => Text(
                                      '${t.about.version} ...',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    error: (_, s) => Text(
                                      t.about.version,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
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

Future<void> _runConnectionStressTest(
  BuildContext context,
  WidgetRef ref,
) async {
  const cycles = 20;
  const connectHold = Duration(milliseconds: 800);
  const betweenCycles = Duration(milliseconds: 300);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Starting connection stress test...'),
      behavior: SnackBarBehavior.floating,
    ),
  );

  final configs = await ref.read(configControllerProvider.future);
  if (configs.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No configuration found. Please add one first.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final activeConfig = configs.first;
  String? failure;

  for (var i = 1; i <= cycles; i++) {
    if (!context.mounted) return;

    Logger.settings.info('Stress test: cycle $i/$cycles - connect');
    await ref.read(connectionProvider.notifier).connect(activeConfig);

    final afterConnect = ref.read(connectionProvider);
    if (afterConnect != ConnectionStatus.connected) {
      final err = ref.read(lastConnectionErrorProvider);
      failure = 'Connect failed at cycle $i: ${err ?? afterConnect.name}';
      unawaited(ref.read(connectionProvider.notifier).disconnect());
      break;
    }

    await Future<void>.delayed(connectHold);

    Logger.settings.info('Stress test: cycle $i/$cycles - disconnect');
    await ref.read(connectionProvider.notifier).disconnect();

    final afterDisconnect = ref.read(connectionProvider);
    if (afterDisconnect != ConnectionStatus.disconnected) {
      failure = 'Disconnect failed at cycle $i: ${afterDisconnect.name}';
      break;
    }

    if (Platform.isWindows) {
      await TunService().stop();
    }

    await Future<void>.delayed(betweenCycles);
  }

  if (!context.mounted) return;

  if (failure != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Stress test completed'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
