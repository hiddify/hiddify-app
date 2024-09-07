import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class GeneralSettingTiles extends HookConsumerWidget {
  const GeneralSettingTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final themeMode = ref.watch(themePreferencesProvider);

    return Column(
      children: [
        const LocalePrefTile(),
        ListTile(
          title: PlatformText(t.settings.general.themeMode),
          subtitle: PlatformText(themeMode.present(t)),
          leading: const Icon(FluentIcons.weather_moon_20_regular),
          onTap: () async {
            final selectedThemeMode = await showPlatformDialog<AppThemeMode>(
              context: context,
              builder: (context) {
                return SimpleDialog(
                  title: PlatformText(t.settings.general.themeMode),
                  children: AppThemeMode.values
                      .map(
                        (e) => RadioListTile(
                          title: PlatformText(e.present(t)),
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
        ),
        const EnableAnalyticsPrefTile(),
        SwitchListTile.adaptive(
          title: PlatformText(t.settings.general.autoIpCheck),
          secondary: const Icon(FluentIcons.globe_search_24_regular),
          value: ref.watch(Preferences.autoCheckIp),
          onChanged: ref.read(Preferences.autoCheckIp.notifier).update,
        ),
        if (Platform.isAndroid) ...[
          SwitchListTile.adaptive(
            title: PlatformText(t.settings.general.dynamicNotification),
            secondary: const Icon(FluentIcons.top_speed_24_regular),
            value: ref.watch(Preferences.dynamicNotification),
            onChanged: (value) async {
              await ref.read(Preferences.dynamicNotification.notifier).update(value);
            },
          ),
          SwitchListTile.adaptive(
            title: PlatformText(t.settings.general.hapticFeedback),
            secondary: const Icon(FluentIcons.phone_vibrate_24_regular),
            value: ref.watch(hapticServiceProvider),
            onChanged: ref.read(hapticServiceProvider.notifier).updatePreference,
          ),
        ],
        if (PlatformUtils.isDesktop) ...[
          SwitchListTile.adaptive(
            title: PlatformText(t.settings.general.autoStart),
            value: ref.watch(autoStartNotifierProvider).asData!.value,
            onChanged: (value) async {
              if (value) {
                await ref.read(autoStartNotifierProvider.notifier).enable();
              } else {
                await ref.read(autoStartNotifierProvider.notifier).disable();
              }
            },
          ),
          SwitchListTile.adaptive(
            title: PlatformText(t.settings.general.silentStart),
            value: ref.watch(Preferences.silentStart),
            onChanged: (value) async {
              await ref.read(Preferences.silentStart.notifier).update(value);
            },
          ),
        ],
      ],
    );
  }
}
