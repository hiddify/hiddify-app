import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoPage extends HookConsumerWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final appInfoAsync = ref.watch(appInfoProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.about.pageTitle), centerTitle: true),
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Gap(40),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Assets.images.logo.svg(
                      colorFilter: ColorFilter.mode(
                        colors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const Gap(24),
                  Text(
                    t.general.appTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const Gap(8),
                  appInfoAsync.when(
                    data: (info) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'v${info.version}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, s) => const SizedBox.shrink(),
                  ),
                  const Gap(60),
                  AppSettingsCard(
                    children: [
                      AppSettingsTile(
                        icon: Icons.update_rounded,
                        title: 'Check for Updates',
                        subtitle: 'Check for latest version',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are using the latest version'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      const AppSettingsTile(
                        icon: Icons.autorenew_rounded,
                        title: 'Auto Update',
                        subtitle: 'Coming Soon',
                        trailing: Switch(
                          value: false,
                          onChanged: null, 
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),
                  AppSettingsCard(
                    children: [
                      AppSettingsTile(
                        icon: Icons.code_rounded,
                        title: 'GitHub Repository',
                        subtitle: 'https://github.com/TGIR0/Hiddify-Reworked',
                        trailing: Icon(
                          Icons.open_in_new_rounded,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                        onTap: () => launchUrl(
                          Uri.parse(
                            'https://github.com/TGIR0/Hiddify-Reworked',
                          ),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    ' 2025 Hiddify Contributors',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  const Gap(16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
