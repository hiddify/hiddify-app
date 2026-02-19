import 'package:flutter/material.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LocalePrefTile extends ConsumerWidget {
  const LocalePrefTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final locale = ref.watch(localePreferencesProvider);
    return ListTile(
      title: Text(t.pages.settings.general.locale),
      subtitle: Text(locale.localeName),
      leading: const Icon(Icons.translate_rounded),
      onTap: () async {
        final selectedLocale = await ref
            .read(dialogNotifierProvider.notifier)
            .showSettingPicker<AppLocale>(
              title: t.pages.settings.general.locale,
              selected: locale,
              onReset: () => ref.read(localePreferencesProvider.notifier).changeLocale(AppLocale.en),
              options: AppLocale.values,
              getTitle: (e) => e.localeName,
            );
        if (selectedLocale != null) {
          await ref.read(localePreferencesProvider.notifier).changeLocale(selectedLocale);
        }
      },
    );
  }
}

class RegionPrefTile extends ConsumerWidget {
  const RegionPrefTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final region = ref.watch(ConfigOptions.region);

    return ListTile(
      title: Text(t.pages.settings.routing.region),
      subtitle: Text(region.present(t), style: Theme.of(context).textTheme.bodySmall),
      leading: const Icon(Icons.place_rounded),
      onTap: () async {
        final selectedRegion = await ref.read(dialogNotifierProvider.notifier).showRegion(selected: region);
        if (selectedRegion != null) {
          // await ref.read(Preferences.region.notifier).update(selectedRegion);

          await ref.watch(ConfigOptions.region.notifier).update(selectedRegion);

          await ref.watch(ConfigOptions.directDnsAddress.notifier).reset();

          // await ref.read(configOptionNotifierProvider.notifier).build();
          // await ref.watch(ConfigOptions.resolveDestination.notifier).update(!ref.watch(ConfigOptions.resolveDestination.notifier).raw());
          //for reload config
          // final tmp = ref.watch(ConfigOptions.resolveDestination.notifier).raw();
          // await ref.watch(ConfigOptions.resolveDestination.notifier).update(!tmp);
          // await ref.watch(ConfigOptions.resolveDestination.notifier).update(tmp);
          //TODO: fix it
        }
      },
    );
  }
}

class EnableAnalyticsPrefTile extends ConsumerWidget {
  const EnableAnalyticsPrefTile({super.key, this.onChanged});

  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final enabled = ref.watch(analyticsControllerProvider).requireValue;

    return SwitchListTile.adaptive(
      title: Text(t.pages.settings.general.enableAnalytics),
      subtitle: Text(t.pages.settings.general.enableAnalyticsMsg, style: Theme.of(context).textTheme.bodySmall),
      secondary: const Icon(Icons.analytics_rounded),
      value: enabled,
      onChanged: (value) async {
        if (onChanged != null) {
          return onChanged!(value);
        }
        if (enabled) {
          await ref.read(analyticsControllerProvider.notifier).disableAnalytics();
        } else {
          await ref.read(analyticsControllerProvider.notifier).enableAnalytics();
        }
      },
    );
  }
}

class ThemeModePrefTile extends ConsumerWidget {
  const ThemeModePrefTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final themeMode = ref.watch(themePreferencesProvider);

    return ListTile(
      title: Text(t.pages.settings.general.themeMode),
      subtitle: Text(themeMode.present(t)),
      leading: Icon(switch (ref.watch(themePreferencesProvider)) {
        AppThemeMode.system => Icons.auto_awesome_rounded,
        AppThemeMode.light => Icons.light_mode_rounded,
        AppThemeMode.dark => Icons.dark_mode_rounded,
        AppThemeMode.black => Icons.contrast_rounded,
      }),
      onTap: () async {
        final selectedThemeMode = await ref
            .read(dialogNotifierProvider.notifier)
            .showSettingPicker<AppThemeMode>(
              title: t.pages.settings.general.themeMode,
              selected: themeMode,
              onReset: () => ref.read(themePreferencesProvider.notifier).changeThemeMode(AppThemeMode.system),
              options: AppThemeMode.values,
              getTitle: (e) => e.present(t),
            );
        if (selectedThemeMode != null) {
          await ref.read(themePreferencesProvider.notifier).changeThemeMode(selectedThemeMode);
        }
      },
    );
  }
}

class ClosingPrefTile extends ConsumerWidget {
  const ClosingPrefTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final action = ref.watch(Preferences.actionAtClose);

    return ListTile(
      title: Text(t.pages.settings.general.actionAtClosing),
      subtitle: Text(action.present(t)),
      leading: const Icon(Icons.logout_rounded),
      onTap: () async {
        final selectedAction = await ref.read(dialogNotifierProvider.notifier).showActionAtClosing(selected: action);
        if (selectedAction != null) {
          await ref.read(Preferences.actionAtClose.notifier).update(selectedAction);
        }
      },
    );
  }
}
