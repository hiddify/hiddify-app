import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/widget/help_tooltip.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GeneralSettingTiles extends HookConsumerWidget {
  const GeneralSettingTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return Column(
      children: [
        const LocalePrefTile(),
        const ThemeModePrefTile(),
        const EnableAnalyticsPrefTile(),
        SwitchListTile(
          title: Row(
            children: [
              Expanded(child: Text(t.settings.general.autoIpCheck)),
              HelpTooltip(message: t.help.settings.region),
            ],
          ),
          secondary: Icon(
            FluentIcons.globe_search_24_filled,
            size: 28,
            color: Theme.of(context).colorScheme.primary,
          ),
          value: ref.watch(Preferences.autoCheckIp),
          onChanged: ref.read(Preferences.autoCheckIp.notifier).update,
        ),
        if (Platform.isAndroid) ...[
          SwitchListTile(
            title: Row(
              children: [
                Expanded(child: Text(t.settings.general.dynamicNotification)),
                const HelpTooltip(message: "نمایش سرعت اینترنت در نوار اعلان‌های اندروید"),
              ],
            ),
            secondary: Icon(
              FluentIcons.top_speed_24_filled,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            value: ref.watch(Preferences.dynamicNotification),
            onChanged: (value) async {
              await ref.read(Preferences.dynamicNotification.notifier).update(value);
            },
          ),
          SwitchListTile(
            title: Row(
              children: [
                Expanded(child: Text(t.settings.general.hapticFeedback)),
                const HelpTooltip(message: "لرزش گوشی هنگام لمس دکمه‌ها"),
              ],
            ),
            secondary: Icon(
              FluentIcons.phone_vibrate_24_filled,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            value: ref.watch(hapticServiceProvider),
            onChanged: ref.read(hapticServiceProvider.notifier).updatePreference,
          ),
        ],
        if (PlatformUtils.isDesktop) ...[
          const ClosingPrefTile(),
          SwitchListTile(
            title: Row(
              children: [
                Expanded(child: Text(t.settings.general.autoStart)),
                HelpTooltip(message: t.help.settings.autoStart),
              ],
            ),
            secondary: Icon(
              FluentIcons.rocket_24_filled,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            value: ref.watch(autoStartNotifierProvider).asData!.value,
            onChanged: (value) async {
              if (value) {
                await ref.read(autoStartNotifierProvider.notifier).enable();
              } else {
                await ref.read(autoStartNotifierProvider.notifier).disable();
              }
            },
          ),
          SwitchListTile(
            title: Row(
              children: [
                Expanded(child: Text(t.settings.general.silentStart)),
                const HelpTooltip(message: "برنامه بدون نمایش پنجره اجرا شود"),
              ],
            ),
            secondary: Icon(
              FluentIcons.eye_off_24_filled,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
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
