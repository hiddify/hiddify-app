import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/core/theme/font_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class GeneralSettingsPage extends ConsumerWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final locale = ref.watch(localePreferencesProvider);
    final themeMode = ref.watch(themePreferencesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('General Settings'),
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
                      AppSectionHeader(title: t.settings.general.sectionTitle),
                      const Gap(8),
                      AppSettingsCard(
                        children: [
                          AppSettingsTile(
                            icon: Icons.language_rounded,
                            title: t.settings.general.locale,
                            subtitle: locale.localeName,
                            onTap: () => _showLocaleSheet(context, ref, locale),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                          const Divider(height: 1, indent: 56),
                          AppSettingsTile(
                            icon: Icons.palette_rounded,
                            title: t.settings.general.themeMode,
                            subtitle: _getThemeModeLabel(themeMode, t),
                            onTap: () =>
                                _showThemeModeSheet(context, ref, themeMode),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                          const Divider(height: 1, indent: 56),
                          AppSettingsTile(
                            icon: Icons.font_download_rounded,
                            title: t.settings.general.fonts,
                            subtitle:
                                '${t.settings.general.fontSize} / ${t.settings.general.fontFamily}',
                            onTap: () => _showFontSheet(context, ref),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: 0.1),
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
    unawaited(
      WoltModalSheet.show<void>(
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
                      unawaited(
                        ref
                            .read(localePreferencesProvider.notifier)
                            .changeLocale(locale),
                      );
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
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

    unawaited(
      WoltModalSheet.show<void>(
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
                      unawaited(
                        ref
                            .read(themePreferencesProvider.notifier)
                            .changeThemeMode(m.$1),
                      );
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFontSheet(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final font = ref.watch(fontPreferencesProvider);

    unawaited(
      WoltModalSheet.show<void>(
        context: context,
        pageListBuilder: (context) => [
          WoltModalSheetPage(
            topBarTitle: Text(t.settings.general.fonts),
            isTopBarLayerAlwaysVisible: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      t.settings.general.fontFamily,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    title: const Text('System (Default)'),
                    leading: font.fontFamily.isEmpty
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : const Icon(Icons.circle_outlined),
                    onTap: () {
                      ref
                          .read(fontPreferencesProvider.notifier)
                          .setFontFamily('');
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    title: const Text('Shabnam (Persian/English)'),
                    leading: font.fontFamily == 'Shabnam'
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : const Icon(Icons.circle_outlined),
                    onTap: () {
                      ref
                          .read(fontPreferencesProvider.notifier)
                          .setFontFamily('Shabnam');
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      t.settings.general.fontSize,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.text_fields, size: 16),
                        Expanded(
                          child: Slider(
                            value: font.scaleFactor,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            label: font.scaleFactor.toStringAsFixed(1),
                            onChanged: (value) {
                              ref
                                  .read(fontPreferencesProvider.notifier)
                                  .setScaleFactor(value);
                            },
                          ),
                        ),
                        const Icon(Icons.text_fields, size: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class SliverStatusBarPlaceholder extends StatelessWidget {
  const SliverStatusBarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
  );
}
