import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/auto_start/notifier/auto_start_notifier.dart';
import 'package:hiddify/features/common/general_pref_tiles.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GeneralSettingTiles extends HookConsumerWidget {
  const GeneralSettingTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Column(
      children: [
        const LocalePrefTile(),
        const ThemeModePrefTile(),
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
          const ClosingPrefTile(),
          SwitchListTile(
            title: Text(t.settings.general.autoStart),
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
