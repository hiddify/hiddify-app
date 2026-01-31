import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/settings/settings.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(t.settings.pageTitle), floating: true),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const AppSectionHeader(
                  title: 'Connectivity',
                  icon: Icons.wifi_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Connection',
                      subtitle: 'VPN mode, protocols, network settings',
                      icon: Icons.wifi_rounded,
                      iconColor: Colors.blue,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => const CoreSettingsRoute().push<void>(context),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Subscriptions',
                      subtitle: 'Manage subscription links and updates',
                      icon: Icons.subscriptions_rounded,
                      iconColor: Colors.teal,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings/subscriptions'),
                    ),
                    if (Platform.isAndroid) ...[
                      const Divider(height: 1, indent: 56),
                      AppSettingsTile(
                        title: 'Per-App Proxy',
                        subtitle: 'Select apps to proxy or bypass',
                        icon: Icons.apps_rounded,
                        iconColor: Colors.orange,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/settings/per-app-proxy'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Security & Privacy',
                  icon: Icons.security_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Security & Protection',
                      subtitle: 'Firewall, content filtering, threat protection',
                      icon: Icons.shield_rounded,
                      iconColor: Colors.green,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => const CoreSettingsRoute().push<void>(context),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Privacy',
                      subtitle: 'Leak protection, anonymity, data collection',
                      icon: Icons.privacy_tip_rounded,
                      iconColor: Colors.purple,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings/privacy'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Maintenance',
                  icon: Icons.build_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Resources',
                      subtitle: 'GeoIP, GeoSite, core updates',
                      icon: Icons.download_rounded,
                      iconColor: Colors.indigo,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings/resources'),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'System Health',
                      subtitle: 'Process monitor, debug, health checks',
                      icon: Icons.health_and_safety_rounded,
                      iconColor: Colors.red,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/settings/health'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Quick Settings',
                  icon: Icons.flash_on_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Block Advertisements',
                      subtitle: 'Block ads and trackers',
                      icon: Icons.block_rounded,
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockAds),
                        onChanged: (bool v) => ref
                            .read(RoutingSettings.blockAds.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Block Adult Content',
                      subtitle: 'Family-safe browsing',
                      icon: Icons.no_adult_content_rounded,
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockPorn),
                        onChanged: (bool v) => ref
                            .read(RoutingSettings.blockPorn.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Block Malware',
                      subtitle: 'Virus and threat protection',
                      icon: Icons.bug_report_rounded,
                      trailing: Switch(
                        value: ref.watch(RoutingSettings.blockMalware),
                        onChanged: (bool v) => ref
                            .read(RoutingSettings.blockMalware.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Block DNS Leaks',
                      subtitle: 'Prevent DNS exposure',
                      icon: Icons.security_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.blockDnsLeaks),
                        onChanged: (bool v) => ref
                            .read(PrivacySettings.blockDnsLeaks.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Appearance',
                  icon: Icons.palette_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      icon: Icons.language_rounded,
                      title: t.settings.general.locale,
                      subtitle: 'English / فارسی',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showLanguageSelector(context),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      icon: Icons.dark_mode_rounded,
                      title: t.settings.general.themeMode,
                      subtitle: 'System',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showThemeSelector(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'About',
                  icon: Icons.info_rounded,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      AppSettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: t.about.pageTitle,
                        subtitle: 'Version info, licenses',
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => const AppInfoRoute().push<void>(context),
                      ),
                      const Divider(height: 1, indent: 56),
                      AppSettingsTile(
                        icon: Icons.code_rounded,
                        title: t.about.sourceCode,
                        subtitle: 'github.com/TGIR0/Hiddify-Reworked',
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () async {
                          final uri = Uri.parse(
                            'https://github.com/TGIR0/Hiddify-Reworked',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      AppSettingsTile(
                        icon: Icons.update_rounded,
                        title: t.about.checkForUpdate,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are using the latest version'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Language',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () {
                LocaleSettings.setLocale(AppLocale.en);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Text('🇮🇷', style: TextStyle(fontSize: 24)),
              title: const Text('فارسی'),
              onTap: () {
                LocaleSettings.setLocale(AppLocale.fa);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.brightness_auto_rounded),
              title: const Text('System'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_rounded),
              title: const Text('Light'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded),
              title: const Text('Dark'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
