import 'package:flutter/material.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/settings/settings.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PrivacySettingsPage extends HookConsumerWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Privacy Settings'),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const AppSectionHeader(
                  title: 'Privacy Level',
                  icon: Icons.shield_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Minimal',
                      subtitle: 'Basic functionality, all features enabled',
                      icon: Icons.lock_open_rounded,
                      iconColor: Colors.grey,
                      trailing: Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onTap: () => _applyPreset(ref, 'minimal'),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Balanced',
                      subtitle: 'Recommended for most users',
                      icon: Icons.lock_rounded,
                      iconColor: Colors.blue,
                      trailing: Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.primary,
                      ),
                      onTap: () => _applyPreset(ref, 'balanced'),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Strict',
                      subtitle: 'Enhanced privacy, some features limited',
                      icon: Icons.enhanced_encryption_rounded,
                      iconColor: Colors.orange,
                      trailing: Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onTap: () => _applyPreset(ref, 'strict'),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Maximum',
                      subtitle: 'Paranoid mode, maximum anonymity',
                      icon: Icons.security_rounded,
                      iconColor: Colors.red,
                      trailing: Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.primary,
                      ),
                      onTap: () => _applyPreset(ref, 'maximum'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Network Privacy',
                  icon: Icons.wifi_protected_setup_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Block WebRTC Leaks',
                      subtitle: 'Prevent IP exposure through WebRTC',
                      icon: Icons.videocam_off_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.blockWebRtcLeaks),
                        onChanged: (v) => ref
                            .read(PrivacySettings.blockWebRtcLeaks.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Block IPv6 Leaks',
                      subtitle: 'Prevent IPv6 traffic leaks',
                      icon: Icons.six_k_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.blockIpv6Leaks),
                        onChanged: (v) => ref
                            .read(PrivacySettings.blockIpv6Leaks.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Block DNS Leaks',
                      subtitle: 'Force all DNS through VPN',
                      icon: Icons.dns_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.blockDnsLeaks),
                        onChanged: (v) => ref
                            .read(PrivacySettings.blockDnsLeaks.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'DNS over HTTPS',
                      subtitle: 'Encrypt DNS queries',
                      icon: Icons.https_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.enableDoh),
                        onChanged: (v) => ref
                            .read(PrivacySettings.enableDoh.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Identity Protection',
                  icon: Icons.fingerprint_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Randomize TLS Fingerprint',
                      subtitle: 'Make traffic less identifiable',
                      icon: Icons.shuffle_rounded,
                      trailing: Switch(
                        value: ref.watch(
                          PrivacySettings.randomizeTlsFingerprint,
                        ),
                        onChanged: (v) => ref
                            .read(
                              PrivacySettings.randomizeTlsFingerprint.notifier,
                            )
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Stealth Mode',
                      subtitle: 'Hide VPN signatures',
                      icon: Icons.visibility_off_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.stealthMode),
                        onChanged: (v) => ref
                            .read(PrivacySettings.stealthMode.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Rotate Connection',
                      subtitle: 'Change connection periodically',
                      icon: Icons.autorenew_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.rotateConnection),
                        onChanged: (v) => ref
                            .read(PrivacySettings.rotateConnection.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Randomize Ports',
                      subtitle: 'Use random local ports',
                      icon: Icons.swap_horiz_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.randomizePorts),
                        onChanged: (v) => ref
                            .read(PrivacySettings.randomizePorts.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Data Collection',
                  icon: Icons.analytics_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Analytics',
                      subtitle: 'Help improve the app (anonymous)',
                      icon: Icons.bar_chart_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.enableAnalytics),
                        onChanged: (v) => ref
                            .read(PrivacySettings.enableAnalytics.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Crash Reporting',
                      subtitle: 'Send crash reports',
                      icon: Icons.bug_report_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.enableCrashReporting),
                        onChanged: (v) => ref
                            .read(PrivacySettings.enableCrashReporting.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Local Statistics',
                      subtitle: 'Track usage locally only',
                      icon: Icons.insert_chart_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.enableLocalStats),
                        onChanged: (v) => ref
                            .read(PrivacySettings.enableLocalStats.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Storage Privacy',
                  icon: Icons.storage_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Encrypt Local Storage',
                      subtitle: 'Secure app data at rest',
                      icon: Icons.lock_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.encryptLocalStorage),
                        onChanged: (v) => ref
                            .read(PrivacySettings.encryptLocalStorage.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Auto-Clear Logs',
                      subtitle: 'Clear logs after disconnect',
                      icon: Icons.delete_sweep_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.autoClearLogs),
                        onChanged: (v) => ref
                            .read(PrivacySettings.autoClearLogs.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Clear Data on Exit',
                      subtitle: 'Remove sensitive data when closing',
                      icon: Icons.cleaning_services_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.clearDataOnExit),
                        onChanged: (v) => ref
                            .read(PrivacySettings.clearDataOnExit.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Redact Sensitive Data in Logs',
                      subtitle: 'Hide passwords, tokens, etc.',
                      icon: Icons.visibility_off_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.redactSensitiveData),
                        onChanged: (v) => ref
                            .read(PrivacySettings.redactSensitiveData.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'App Behavior',
                  icon: Icons.app_settings_alt_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Hide from Recent Apps',
                      subtitle: "Don't show in app switcher",
                      icon: Icons.visibility_off_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.hideFromRecents),
                        onChanged: (v) => ref
                            .read(PrivacySettings.hideFromRecents.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Secure Keyboard',
                      subtitle: 'Disable keyboard learning',
                      icon: Icons.keyboard_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.secureKeyboard),
                        onChanged: (v) => ref
                            .read(PrivacySettings.secureKeyboard.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Blur in App Switcher',
                      subtitle: 'Hide content in task switcher',
                      icon: Icons.blur_on_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.blurInSwitcher),
                        onChanged: (v) => ref
                            .read(PrivacySettings.blurInSwitcher.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Disable Screenshots',
                      subtitle: 'Block screenshot capture',
                      icon: Icons.screenshot_rounded,
                      trailing: Switch(
                        value: ref.watch(PrivacySettings.disableScreenshots),
                        onChanged: (v) => ref
                            .read(PrivacySettings.disableScreenshots.notifier)
                            .update(v),
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

  void _applyPreset(WidgetRef ref, String level) {
    final preset = PrivacySettings.getPrivacyPreset(level);

    if (preset['blockWebRtc'] != null) {
      ref
          .read(PrivacySettings.blockWebRtcLeaks.notifier)
          .update(preset['blockWebRtc']!);
    }
    if (preset['blockDnsLeaks'] != null) {
      ref
          .read(PrivacySettings.blockDnsLeaks.notifier)
          .update(preset['blockDnsLeaks']!);
    }
    if (preset['blockIpv6Leaks'] != null) {
      ref
          .read(PrivacySettings.blockIpv6Leaks.notifier)
          .update(preset['blockIpv6Leaks']!);
    }
    if (preset['stealthMode'] != null) {
      ref
          .read(PrivacySettings.stealthMode.notifier)
          .update(preset['stealthMode']!);
    }
    if (preset['encryptStorage'] != null) {
      ref
          .read(PrivacySettings.encryptLocalStorage.notifier)
          .update(preset['encryptStorage']!);
    }
    if (preset['redactLogs'] != null) {
      ref
          .read(PrivacySettings.redactSensitiveData.notifier)
          .update(preset['redactLogs']!);
    }
    if (preset['randomizePorts'] != null) {
      ref
          .read(PrivacySettings.randomizePorts.notifier)
          .update(preset['randomizePorts']!);
    }
    if (preset['rotateConnection'] != null) {
      ref
          .read(PrivacySettings.rotateConnection.notifier)
          .update(preset['rotateConnection']!);
    }
    if (preset['autoClearLogs'] != null) {
      ref
          .read(PrivacySettings.autoClearLogs.notifier)
          .update(preset['autoClearLogs']!);
    }
  }
}
