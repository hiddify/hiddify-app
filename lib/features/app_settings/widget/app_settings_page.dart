import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/settings/model/core_preferences.dart';
import 'package:hiddify/features/settings/model/dns_settings.dart';
import 'package:hiddify/features/settings/model/fragment_settings.dart';
import 'package:hiddify/features/settings/model/inbound_settings.dart';
import 'package:hiddify/features/settings/model/mux_settings.dart';
import 'package:hiddify/features/settings/model/routing_settings.dart';
import 'package:hiddify/features/settings/model/sockopt_settings.dart';
import 'package:hiddify/gen/translations.g.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final locale = ref.watch(localePreferencesProvider);
    final themeMode = ref.watch(themePreferencesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(t.settings.pageTitle),
            centerTitle: false,
          ),
          const SliverStatusBarPlaceholder(),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // General Section
                      _SectionHeader(title: t.settings.general.sectionTitle),
                      const Gap(8),
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: Icons.language_rounded,
                            title: t.settings.general.locale,
                            subtitle: locale.localeName,
                            onTap: () => _showLocaleSheet(context, ref, locale),
                          ),
                          const Divider(height: 1, indent: 56),
                          _SettingsTile(
                            icon: Icons.palette_rounded,
                            title: t.settings.general.themeMode,
                            subtitle: _getThemeModeLabel(themeMode, t),
                            onTap: () =>
                                _showThemeModeSheet(context, ref, themeMode),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: 0.1),

                      const Gap(24),

                      // Routing & Privacy Section
                      _SectionHeader(title: 'Routing & Privacy'),
                      const Gap(8),
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: Icons.route_rounded,
                            title: 'Routing Rules',
                            subtitle: 'Bypass LAN, Iran, China, Block Ads...',
                            onTap: () => _showRoutingSheet(context, ref),
                          ),
                          const Divider(height: 1, indent: 56),
                          _SettingsTile(
                            icon: Icons.dns_rounded,
                            title: 'DNS Settings',
                            subtitle: 'Remote/Direct DNS, FakeDNS...',
                            onTap: () => _showDnsSheet(context, ref),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                      const Gap(24),

                      // Evasion Section (GFW-knocker)
                      _SectionHeader(title: 'Evasion & Network'),
                      const Gap(8),
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: Icons.shield_rounded,
                            title: 'Evasion Capabilities',
                            subtitle: 'Fragment, Noise, Padding...',
                            onTap: () => _showEvasionSheet(context, ref),
                          ),
                          const Divider(height: 1, indent: 56),
                          _SettingsTile(
                            icon: Icons.hub_rounded,
                            title: 'Multiplexing (Mux)',
                            subtitle: 'Concurrency, XUDP...',
                            onTap: () => _showMuxSheet(context, ref),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                      const Gap(24),

                      // Advanced Section
                      _SectionHeader(title: 'Advanced Core'),
                      const Gap(8),
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: Icons.input_rounded,
                            title: 'Inbounds',
                            subtitle: 'SOCKS/HTTP Ports, Sniffing...',
                            onTap: () => _showInboundSheet(context, ref),
                          ),
                          const Divider(height: 1, indent: 56),
                          _SettingsTile(
                            icon: Icons.settings_ethernet_rounded,
                            title: 'Protocol Settings',
                            subtitle: 'TCP/TLS options, Micromanagement...',
                            onTap: () => _showSockoptSheet(context, ref),
                          ),
                          const Divider(height: 1, indent: 56),
                          _SettingsTile(
                            icon: Icons.developer_mode_rounded,
                            title: 'Core Options',
                            subtitle: 'Logging, Core Mode, Assets...',
                            onTap: () => _showCoreOptionsSheet(context, ref),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                      const Gap(32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(AppThemeMode mode, Translations t) {
    switch (mode) {
      case AppThemeMode.system:
        return t.settings.general.themeModes.system;
      case AppThemeMode.light:
        return t.settings.general.themeModes.light;
      case AppThemeMode.dark:
        return t.settings.general.themeModes.dark;
      case AppThemeMode.black:
        return t.settings.general.themeModes.black;
    }
  }

  void _showLocaleSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocale current,
  ) {
    unawaited(WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: Text(Translations.of(context).settings.general.locale),
          isTopBarLayerAlwaysVisible: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: AppLocale.values.map((locale) {
                final isSelected = locale == current;
                return ListTile(
                  leading: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : const Icon(Icons.circle_outlined),
                  title: Text(locale.localeName),
                  onTap: () {
                    unawaited(ref
                        .read(localePreferencesProvider.notifier)
                        .changeLocale(locale));
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ));
  }

  void _showThemeModeSheet(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode current,
  ) {
    final t = Translations.of(context);
    final modes = [
      (
        AppThemeMode.system,
        t.settings.general.themeModes.system,
        Icons.brightness_auto_rounded,
      ),
      (
        AppThemeMode.light,
        t.settings.general.themeModes.light,
        Icons.light_mode_rounded,
      ),
      (
        AppThemeMode.dark,
        t.settings.general.themeModes.dark,
        Icons.dark_mode_rounded,
      ),
      (
        AppThemeMode.black,
        t.settings.general.themeModes.black,
        Icons.contrast_rounded,
      ),
    ];

    unawaited(WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: Text(t.settings.general.themeMode),
          isTopBarLayerAlwaysVisible: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: modes.map((m) {
                final isSelected = m.$1 == current;
                return ListTile(
                  leading: Icon(
                    m.$3,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(m.$2),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    unawaited(ref
                        .read(themePreferencesProvider.notifier)
                        .changeThemeMode(m.$1));
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ));
  }

  void _showRoutingSheet(BuildContext context, WidgetRef ref) {
    unawaited(WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: const Text('Routing Rules'),
          isTopBarLayerAlwaysVisible: true,
          child: Consumer(
            builder: (context, ref, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  _SwitchListTile(
                    title: 'Bypass LAN',
                    subtitle: 'Direct connection for local network',
                    provider: RoutingSettings.bypassLan,
                  ),
                  _SwitchListTile(
                    title: 'Bypass Iran',
                    subtitle: 'Direct connection for Iranian sites',
                    provider: RoutingSettings.bypassIran,
                  ),
                  _SwitchListTile(
                    title: 'Bypass China',
                    subtitle: 'Direct connection for Chinese sites',
                    provider: RoutingSettings.bypassChina,
                  ),
                  const Divider(),
                  _SwitchListTile(
                    title: 'Block Ads',
                    subtitle: 'Block common ad domains',
                    provider: RoutingSettings.blockAds,
                  ),
                  _SwitchListTile(
                    title: 'Block Porn',
                    subtitle: 'Block adult content',
                    provider: RoutingSettings.blockPorn,
                  ),
                  _SwitchListTile(
                    title: 'Block QUIC',
                    subtitle: 'Force TCP/TLS (Recommended)',
                    provider: RoutingSettings.blockQuic,
                  ),
                  _SwitchListTile(
                    title: 'Block Malware/Phishing',
                    subtitle: 'Enhanced security',
                    provider: RoutingSettings.blockMalware,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _showDnsSheet(BuildContext context, WidgetRef ref) {
    unawaited(WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: const Text('DNS Settings'),
          isTopBarLayerAlwaysVisible: true,
          child: Consumer(
            builder: (context, ref, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  _TextPreferenceTile(
                    title: 'Remote DNS',
                    provider: DnsSettings.remoteDns,
                  ),
                  _TextPreferenceTile(
                    title: 'Direct DNS',
                    provider: DnsSettings.directDns,
                  ),
                  const Divider(),
                  _SwitchListTile(
                    title: 'Enable FakeDNS',
                    subtitle: 'Return fake IPs for better routing',
                    provider: DnsSettings.enableFakeDns,
                  ),
                  _SwitchListTile(
                    title: 'Enable DNS Routing',
                    subtitle: 'Route DNS traffic through core',
                    provider: DnsSettings.enableDnsRouting,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _showEvasionSheet(BuildContext context, WidgetRef ref) {
    unawaited(WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: const Text('Evasion Capabilities'),
          isTopBarLayerAlwaysVisible: true,
          child: Consumer(
            builder: (context, ref, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Fragment (GFW-knocker)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _SwitchListTile(
                    title: 'Enable Fragment',
                    subtitle: 'Split TLS Hello packets',
                    provider: FragmentSettings.enabled,
                  ),
                  _TextPreferenceTile(
                    title: 'Packets',
                    provider: FragmentSettings.packets,
                  ),
                  _TextPreferenceTile(
                    title: 'Length',
                    provider: FragmentSettings.length,
                  ),
                  _TextPreferenceTile(
                    title: 'Interval',
                    provider: FragmentSettings.interval,
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Noise (Padding)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _SwitchListTile(
                    title: 'Enable Noise',
                    subtitle: 'Add random garbage packets',
                    provider: FragmentSettings.noiseEnabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _showMuxSheet(BuildContext context, WidgetRef ref) {
    unawaited(WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: const Text('Multiplexing'),
          isTopBarLayerAlwaysVisible: true,
          child: Consumer(
            builder: (context, ref, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  _SwitchListTile(
                    title: 'Enable Mux',
                    subtitle: 'Multiplex multiple streams',
                    provider: MuxSettings.enabled,
                  ),
                  _SwitchListTile(
                    title: 'Mux Padding',
                    subtitle: 'Anti-DPI traffic padding',
                    provider: MuxSettings.padding,
                  ),
                  const Divider(),
                  _IntPreferenceTile(
                    title: 'Concurrency',
                    provider: MuxSettings.concurrency,
                  ),
                  _IntPreferenceTile(
                    title: 'XUDP Concurrency',
                    provider: MuxSettings.xudpConcurrency,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _showInboundSheet(BuildContext context, WidgetRef ref) {
    unawaited(WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: const Text('Inbounds'),
          isTopBarLayerAlwaysVisible: true,
          child: Consumer(
            builder: (context, ref, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  _IntPreferenceTile(
                    title: 'SOCKS Port',
                    provider: InboundSettings.socksPort,
                  ),
                  _IntPreferenceTile(
                    title: 'HTTP Port',
                    provider: InboundSettings.httpPort,
                  ),
                  const Divider(),
                  _SwitchListTile(
                    title: 'Enable Sniffing',
                    subtitle: 'Detect traffic content',
                    provider: InboundSettings.sniffingEnabled,
                  ),
                  _SwitchListTile(
                    title: 'Route Only Strategy',
                    subtitle: 'Only route if sniffed',
                    provider: InboundSettings.sniffingRouteOnly,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _showSockoptSheet(BuildContext context, WidgetRef ref) {
    unawaited(WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: const Text('Sockopt & TCP'),
          isTopBarLayerAlwaysVisible: true,
          child: Consumer(
            builder: (context, ref, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  _SwitchListTile(
                    title: 'TCP Fast Open',
                    subtitle: 'Reduce handshake latency',
                    provider: SockoptSettings.tcpFastOpen,
                  ),
                  _SwitchListTile(
                    title: 'TCP No Delay',
                    subtitle: 'Disable Nagle algorithm',
                    provider: SockoptSettings.tcpNoDelay,
                  ),
                  _SwitchListTile(
                    title: 'TCP MPTCP',
                    subtitle: 'Multipath TCP (if supported)',
                    provider: SockoptSettings.tcpMptcp,
                  ),
                  const Divider(),
                  _TextPreferenceTile(
                    title: 'TCP Congestion',
                    provider: SockoptSettings.tcpCongestion,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _showCoreOptionsSheet(BuildContext context, WidgetRef ref) {
    unawaited(WoltModalSheet.show(
      context: context,
      pageListBuilder: (context) => [
        WoltModalSheetPage(
          topBarTitle: const Text('Core Options'),
          isTopBarLayerAlwaysVisible: true,
          child: Consumer(
            builder: (context, ref, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  _TextPreferenceTile(
                    title: 'Core Mode',
                    provider: CorePreferences.coreMode,
                  ),
                  _SwitchListTile(
                    title: 'Enable Logging',
                    subtitle: 'Write logs to file',
                    provider: CorePreferences.enableLogging,
                  ),
                  _TextPreferenceTile(
                    title: 'Log Level',
                    provider: CorePreferences.logLevel,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }
}

class _SwitchListTile extends ConsumerWidget {
  const _SwitchListTile({
    required this.title,
    required this.provider,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final NotifierProvider<PreferencesNotifier<bool, bool>, bool> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      value: value,
      onChanged: (v) => ref.read(provider.notifier).update(v),
    );
  }
}

class _TextPreferenceTile extends ConsumerWidget {
  const _TextPreferenceTile({
    required this.title,
    required this.provider,
  });

  final String title;
  final NotifierProvider<PreferencesNotifier<String, String>, String> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        value.isEmpty ? 'Not Set' : value,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () async {
        final controller = TextEditingController(text: value);
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Edit $title'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        if (result != null) {
          await ref.read(provider.notifier).update(result);
        }
      },
    );
  }
}

class _IntPreferenceTile extends ConsumerWidget {
  const _IntPreferenceTile({
    required this.title,
    required this.provider,
  });

  final String title;
  final NotifierProvider<PreferencesNotifier<int, int>, int> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        value.toString(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () async {
        final controller = TextEditingController(text: value.toString());
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Edit $title'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Save'),
              ),
            ],
          ),
        );
        if (result != null) {
          final intVal = int.tryParse(result);
          if (intVal != null) await ref.read(provider.notifier).update(intVal);
        }
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: children,
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
}

class SliverStatusBarPlaceholder extends StatelessWidget {
  const SliverStatusBarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => SliverPadding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      );
}
