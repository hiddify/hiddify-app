import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/settings/notifier/platform_settings_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PlatformSettingsTiles extends HookConsumerWidget {
  const PlatformSettingsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final isIgnoringBatteryOptimizations = ref.watch(ignoreBatteryOptimizationsProvider);

    return isIgnoringBatteryOptimizations.when(
      data: (isIgnored) => isIgnored
          ? const SizedBox()
          : ListTile(
              title: Text(t.settings.general.ignoreBatteryOptimizations),
              subtitle: Text(t.settings.general.ignoreBatteryOptimizationsMsg),
              leading: const Icon(Icons.battery_saver_rounded),
              onTap: () async {
                await ref.read(ignoreBatteryOptimizationsProvider.notifier).request();
              },
            ),
      error: (_, __) => const SizedBox(),
      loading: () => const SizedBox(
        height: 48,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: LinearProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
