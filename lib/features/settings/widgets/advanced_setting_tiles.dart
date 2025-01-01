import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/overview/config_options_page.dart';
import 'package:hiddify/features/config_option/widget/preference_tile.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/settings/notifier/platform_settings_notifier.dart';
import 'package:hiddify/features/settings/widgets/settings_input_dialog.dart';
import 'package:hiddify/utils/validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:humanizer/humanizer.dart';

class AdvancedSettingTiles extends HookConsumerWidget {
  const AdvancedSettingTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final debug = ref.watch(debugModeNotifierProvider);
    final disableMemoryLimit = ref.watch(Preferences.disableMemoryLimit);

    String experimental(String txt) {
      return "$txt (${t.settings.experimental})";
    }

    return Column(
      children: [
        // const RegionPrefTile(),
        // ListTile(
        //   title: Text(t.settings.geoAssets.pageTitle),
        //   leading: const Icon(
        //     FluentIcons.arrow_routing_rectangle_multiple_24_regular,
        //   ),
        //   onTap: () async {
        //     // await const GeoAssetsRoute().push(context);
        //   },
        // ),

        SwitchListTile.adaptive(
          title: Text(t.settings.advanced.memoryLimit),
          subtitle: Text(t.settings.advanced.memoryLimitMsg),
          value: !disableMemoryLimit,
          secondary: const Icon(FluentIcons.developer_board_24_regular),
          onChanged: (value) async {
            await ref.read(Preferences.disableMemoryLimit.notifier).update(!value);
          },
        ),

        SwitchListTile.adaptive(
          title: Text(t.settings.advanced.debugMode),
          value: debug,
          secondary: const Icon(FluentIcons.window_dev_tools_24_regular),
          onChanged: (value) async {
            if (value) {
              await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(t.settings.advanced.debugMode),
                    content: Text(t.settings.advanced.debugModeMsg),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(true),
                        child: Text(
                          MaterialLocalizations.of(context).okButtonLabel,
                        ),
                      ),
                    ],
                  );
                },
              );
            }
            await ref.read(debugModeNotifierProvider.notifier).update(value);
          },
        ),
        ChoicePreferenceWidget(
          selected: ref.watch(ConfigOptions.logLevel),
          preferences: ref.watch(ConfigOptions.logLevel.notifier),
          choices: LogLevel.choices,
          title: t.config.logLevel,
          presentChoice: (value) => value.name.toUpperCase(),
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.connectionTestUrl),
          preferences: ref.watch(ConfigOptions.connectionTestUrl.notifier),
          title: t.config.connectionTestUrl,
        ),
        ListTile(
          title: Text(t.config.urlTestInterval),
          subtitle: Text(
            ref.watch(ConfigOptions.urlTestInterval).toApproximateTime(isRelativeToNow: false),
          ),
          onTap: () async {
            final urlTestInterval = await SettingsSliderDialog(
              title: t.config.urlTestInterval,
              initialValue: ref.watch(ConfigOptions.urlTestInterval).inMinutes.coerceIn(0, 60).toDouble(),
              onReset: ref.read(ConfigOptions.urlTestInterval.notifier).reset,
              min: 1,
              max: 60,
              divisions: 60,
              labelGen: (value) => Duration(minutes: value.toInt()).toApproximateTime(isRelativeToNow: false),
            ).show(context);
            if (urlTestInterval == null) return;
            await ref.read(ConfigOptions.urlTestInterval.notifier).update(Duration(minutes: urlTestInterval.toInt()));
          },
        ),
        ValuePreferenceWidget(
          value: ref.watch(ConfigOptions.clashApiPort),
          preferences: ref.watch(ConfigOptions.clashApiPort.notifier),
          title: t.config.clashApiPort,
          validateInput: isPort,
          digitsOnly: true,
          inputToValue: int.tryParse,
        ),
        switchListTileAdaptive(
          context,
          title: experimental(t.config.useXrayCoreWhenPossible.Label),
          subtitle: t.config.useXrayCoreWhenPossible.Description,
          value: ref.watch(ConfigOptions.useXrayCoreWhenPossible),
          onChanged: ref.read(ConfigOptions.useXrayCoreWhenPossible.notifier).update,
        ),
      ],
    );
  }
}
