import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hiddify/core/logger/log_viewer_page.dart';
import 'package:hiddify/features/settings/model/core_preferences.dart';
import 'package:hiddify/features/system/data/system_optimization_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final coreMode = ref.watch(CorePreferences.coreMode);
    final routingRule = ref.watch(CorePreferences.routingRule);
    final enableLogging = ref.watch(CorePreferences.enableLogging);
    final logLevel = ref.watch(CorePreferences.logLevel);
    // final assetPath = ref.watch(CorePreferences.assetPath); // Unused
    final enableMux = ref.watch(CorePreferences.enableMux);
    final muxConcurrency = ref.watch(CorePreferences.muxConcurrency);
    final allowInsecure = ref.watch(CorePreferences.allowInsecure);
    final domainStrategy = ref.watch(CorePreferences.domainStrategy);
    final socksPort = ref.watch(CorePreferences.sockPort);
    final httpPort = ref.watch(CorePreferences.httpPort);
    final remoteDns = ref.watch(CorePreferences.remoteDns);
    final fingerPrint = ref.watch(CorePreferences.fingerPrint);

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
                      icon: Icons.route_rounded,
                      title: 'Routing Rule',
                      subtitle: _getRoutingSubtitle(routingRule),
                      trailing: _ModernDropdown<String>(
                        value: routingRule,
                        items: const {'global': 'Global', 'geo_iran': 'Geo Iran', 'bypass_lan': 'Bypass LAN'},
                        onChanged: (val) {
                          if (val != null) unawaited(ref.read(CorePreferences.routingRule.notifier).update(val));
                        },
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
                          onSubmitted: (v) => ref.read(CorePreferences.sockPort.notifier).update(int.tryParse(v) ?? 2334),
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
                          onSubmitted: (v) => ref.read(CorePreferences.httpPort.notifier).update(int.tryParse(v) ?? 2335),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Network & Security
                _SectionHeader(title: 'Network & Security', icon: Icons.security_rounded, colorScheme: colorScheme),
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
                        onChanged: (v) => ref.read(CorePreferences.allowInsecure.notifier).update(v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'TLS Fingerprint',
                      trailing: _ModernDropdown<String>(
                        value: fingerPrint,
                        items: const {'chrome': 'Chrome', 'firefox': 'Firefox', 'ios': 'iOS', 'random': 'Random'},
                        onChanged: (v) => ref.read(CorePreferences.fingerPrint.notifier).update(v!),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.merge_rounded,
                      title: 'Enable Mux',
                      subtitle: 'Multiplex connections',
                      trailing: Switch(
                        value: enableMux,
                        onChanged: (v) => ref.read(CorePreferences.enableMux.notifier).update(v),
                      ),
                    ),
                    if (enableMux) ...[
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.tune_rounded,
                        title: 'Mux Concurrency',
                        trailing: _ModernDropdown<int>(
                          value: muxConcurrency,
                          items: const {4: '4', 8: '8', 16: '16'},
                          onChanged: (v) => ref.read(CorePreferences.muxConcurrency.notifier).update(v ?? 8),
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.domain_rounded,
                      title: 'Domain Strategy',
                      trailing: _ModernDropdown<String>(
                        value: domainStrategy,
                        items: const {'IPIfNonMatch': 'IPIfNonMatch', 'IPOnDemand': 'IPOnDemand', 'AsIs': 'AsIs'},
                        onChanged: (v) => ref.read(CorePreferences.domainStrategy.notifier).update(v!),
                      ),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.dns_outlined,
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
                          onSubmitted: (v) => ref.read(CorePreferences.remoteDns.notifier).update(v),
                        ),
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

  static String _getRoutingSubtitle(String rule) {
    switch (rule) {
      case 'global': return 'Proxy everything';
      case 'geo_iran': return 'Direct Iran / Block Ads';
      case 'bypass_lan': return 'Bypass Local Network';
      default: return rule;
    }
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
