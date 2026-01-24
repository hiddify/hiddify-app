import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/settings/notifier/battery_optimization/battery_optimizations_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ValuePreferenceWidget<T> extends HookConsumerWidget {
  const ValuePreferenceWidget({
    super.key,
    required this.value,
    required this.preferences,
    this.enabled = true,
    required this.title,
    this.presentValue,
    this.formatInputValue,
    this.validateInput,
    this.inputToValue,
    this.digitsOnly = false,
    this.icon,
  });

  final T value;
  final PreferencesNotifier<T, dynamic> preferences;
  final bool enabled;
  final String title;
  final String Function(T value)? presentValue;
  final String Function(T value)? formatInputValue;
  final bool Function(String value)? validateInput;
  final T? Function(String input)? inputToValue;
  final bool digitsOnly;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(title),
      subtitle: Text(presentValue?.call(value) ?? value.toString()),
      leading: icon != null ? Icon(icon) : null,
      // material: (context, platform) => MaterialListTileData(
      enabled: enabled,

      // ),
      onTap: () async {
        final inputValue = await ref
            .read(dialogNotifierProvider.notifier)
            .showSettingInput(
              title: title,
              initialValue: value,
              validator: validateInput,
              valueFormatter: formatInputValue,
              onReset: preferences.reset,
              digitsOnly: digitsOnly,
              mapTo: inputToValue,
              possibleValues: preferences.possibleValues,
            );
        if (inputValue == null) {
          return;
        }
        await preferences.update(inputValue);
      },
    );
  }
}

class ChoicePreferenceWidget<T> extends HookConsumerWidget {
  const ChoicePreferenceWidget({
    super.key,
    required this.selected,
    required this.preferences,
    this.enabled = true,
    required this.choices,
    required this.title,
    this.icon,
    required this.presentChoice,
    this.validateInput,
    this.onChanged,
  });

  final T selected;
  final PreferencesNotifier<T, dynamic> preferences;
  final bool enabled;
  final List<T> choices;
  final String title;
  final IconData? icon;
  final String Function(T value) presentChoice;
  final bool Function(String value)? validateInput;
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(title),
      subtitle: Text(presentChoice(selected)),
      leading: icon != null ? Icon(icon) : null,
      enabled: enabled,
      onTap: () async {
        final selection = await ref
            .read(dialogNotifierProvider.notifier)
            .showSettingPicker<T>(
              title: title,
              selected: selected,
              options: choices,
              getTitle: (e) => presentChoice(e),
              onReset: preferences.reset,
            );
        if (selection == null) return;
        final out = await preferences.update(selection);
        onChanged?.call(selection);
        return out;
      },
    );
  }
}

class BatteryOptimizationWidget extends HookConsumerWidget {
  const BatteryOptimizationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final isIgnoringBatteryOptimizations = ref.watch(batteryOptimizationNotifierProvider);

    return isIgnoringBatteryOptimizations.when(
      data: (isIgnored) => isIgnored
          ? const SizedBox()
          : ListTile(
              title: Text(t.pages.settings.general.ignoreBatteryOptimizations),
              subtitle: Text(t.pages.settings.general.ignoreBatteryOptimizationsMsg),
              leading: const Icon(Icons.battery_saver_rounded),
              onTap: () async {
                await ref.read(batteryOptimizationNotifierProvider.notifier).requestToIgnore();
              },
            ),
      error: (_, _) => const SizedBox(),
      loading: () => const SizedBox(
        height: 48,
        child: Center(
          child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: LinearProgressIndicator()),
        ),
      ),
    );
  }
}
