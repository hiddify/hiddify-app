import 'package:flutter/material.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/settings/widgets/widgets.dart';

class ValuePreferenceWidget<T> extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(presentValue?.call(value) ?? value.toString()),
      enabled: enabled,
      onTap: () async {
        final inputValue = await SettingsInputDialog(
          title: title,
          initialValue: value,
          validator: validateInput,
          valueFormatter: formatInputValue,
          onReset: preferences.reset,
          digitsOnly: digitsOnly,
          mapTo: inputToValue,
          possibleValues: preferences.possibleValues,
        ).show(context);
        if (inputValue == null) {
          return;
        }
        await preferences.update(inputValue);
      },
    );
  }
}

class ChoicePreferenceWidget<T> extends StatelessWidget {
  const ChoicePreferenceWidget({
    super.key,
    required this.selected,
    required this.preferences,
    this.enabled = true,
    required this.choices,
    required this.title,
    required this.presentChoice,
    this.validateInput,
    this.onChanged,
  });

  final T selected;
  final PreferencesNotifier<T, dynamic> preferences;
  final bool enabled;
  final List<T> choices;
  final String title;
  final String Function(T value) presentChoice;
  final bool Function(String value)? validateInput;
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(presentChoice(selected)),
      enabled: enabled,
      onTap: () async {
        final selection = await SettingsPickerDialog(
          title: title,
          selected: selected,
          options: choices,
          getTitle: (e) => presentChoice(e),
          onReset: preferences.reset,
        ).show(context);
        if (selection == null) {
          return;
        }
        final out = await preferences.update(selection);
        onChanged?.call(selection);
        return out;
      },
    );
  }
}
