import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/analytics/analytics_controller.dart';
import 'package:hiddify/core/localization/locale_extensions.dart';
import 'package:hiddify/core/localization/locale_preferences.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/actions_at_closing.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LocalePrefTile extends ConsumerWidget {
  const LocalePrefTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final locale = ref.watch(localePreferencesProvider);

    return ListTile(
      title: Text(t.settings.general.locale),
      subtitle: Text(locale.localeName),
      leading: const Icon(FluentIcons.local_language_24_regular),
      onTap: () async {
        final selectedLocale = await showDialog<AppLocale>(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Text(t.settings.general.locale),
              children: AppLocale.values
                  .map(
                    (e) => RadioListTile(
                      title: Text(e.localeName),
                      value: e,
                      groupValue: locale,
                      onChanged: Navigator.of(context).maybePop,
                    ),
                  )
                  .toList(),
            );
          },
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
    final t = ref.watch(translationsProvider);

    final region = ref.watch(ConfigOptions.region);

    return ListTile(
      title: Text(t.settings.general.region),
      subtitle: Text(region.present(t)),
      leading: const Icon(FluentIcons.globe_location_24_regular),
      onTap: () async {
        final selectedRegion = await showDialog<Region>(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Text(t.settings.general.region),
              children: Region.values
                  .map(
                    (e) => RadioListTile(
                      title: Text(e.present(t)),
                      value: e,
                      groupValue: region,
                      onChanged: Navigator.of(context).maybePop,
                    ),
                  )
                  .toList(),
            );
          },
        );
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
  const EnableAnalyticsPrefTile({
    super.key,
    this.onChanged,
  });

  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final enabled = ref.watch(analyticsControllerProvider).requireValue;

    return SwitchListTile(
      title: Text(t.settings.general.enableAnalytics),
      subtitle: Text(
        t.settings.general.enableAnalyticsMsg,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      secondary: const Icon(FluentIcons.bug_24_regular),
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
    final t = ref.watch(translationsProvider);

    final themeMode = ref.watch(themePreferencesProvider);

    return ListTile(
      title: Text(t.settings.general.themeMode),
      subtitle: Text(themeMode.present(t)),
      leading: const Icon(FluentIcons.weather_moon_20_regular),
      onTap: () async {
        final selectedThemeMode = await showDialog<AppThemeMode>(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Text(t.settings.general.themeMode),
              children: AppThemeMode.values
                  .map(
                    (e) => RadioListTile(
                      title: Text(e.present(t)),
                      value: e,
                      groupValue: themeMode,
                      onChanged: Navigator.of(context).maybePop,
                    ),
                  )
                  .toList(),
            );
          },
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
    final t = ref.watch(translationsProvider);

    final action = ref.watch(Preferences.actionAtClose);

    return ListTile(
      title: Text(t.settings.general.actionAtClosing),
      subtitle: Text(action.present(t)),
      leading: const Icon(FluentIcons.arrow_exit_20_regular),
      onTap: () async {
        final selectedAction = await showDialog<ActionsAtClosing>(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: Text(t.settings.general.actionAtClosing),
              children: ActionsAtClosing.values
                  .map(
                    (e) => RadioListTile(
                      title: Text(e.present(t)),
                      value: e,
                      groupValue: action,
                      onChanged: Navigator.of(context).maybePop,
                    ),
                  )
                  .toList(),
            );
          },
        );
        if (selectedAction != null) {
          await ref.read(Preferences.actionAtClose.notifier).update(selectedAction);
        }
      },
    );
  }
}
