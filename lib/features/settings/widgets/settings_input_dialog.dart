import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsInputDialog<T> extends HookConsumerWidget with PresLogger {
  const SettingsInputDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.mapTo,
    this.validator,
    this.valueFormatter,
    this.onReset,
    this.optionalAction,
    this.icon,
    this.digitsOnly = false,
    this.possibleValues,
  });

  final String title;
  final T initialValue;
  final T? Function(String value)? mapTo;
  final bool Function(String value)? validator;
  final String Function(T value)? valueFormatter;
  final List<T>? possibleValues;
  final VoidCallback? onReset;
  final (String text, VoidCallback)? optionalAction;
  final IconData? icon;
  final bool digitsOnly;

  Future<T?> show(BuildContext context) {
    return showDialog(context: context, builder: (context) => this);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final localizations = MaterialLocalizations.of(context);

    final textController = useTextEditingController(
      text: valueFormatter?.call(initialValue) ?? initialValue.toString(),
    );

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: AlertDialog(
        title: Text(title),
        icon: icon != null ? Icon(icon) : null,
        content: FocusTraversalOrder(
          order: const NumericFocusOrder(1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (possibleValues != null)
                // AutocompleteField(initialValue: initialValue.toString(), options: possibleValues!.map((e) => e.toString()).toList())
                TypeAheadField<String>(
                  controller: textController,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textDirection: TextDirection.ltr,
                      autofocus: true,
                      // decoration: InputDecoration(
                      //     // border: OutlineInputBorder(),
                      //     // labelText: 'City',
                      //     )
                    );
                  },
                  // Callback to fetch suggestions based on user input
                  suggestionsCallback: (pattern) {
                    final items = possibleValues!.map((p) => p.toString());
                    var res = items
                        .where(
                          (suggestion) => suggestion.toLowerCase().contains(
                            pattern.toLowerCase(),
                          ),
                        )
                        .toList();
                    if (res.length <= 1)
                      res = [pattern, ...items.where((s) => s != pattern)];
                    return res;
                  },
                  // Widget to build each suggestion in the list
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 10,
                      ), // Minimize ListTile padding
                      minTileHeight: 0,
                      title: Text(
                        suggestion,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                  // Callback when a suggestion is selected
                  onSelected: (suggestion) {
                    // Handle the selected suggestion
                    textController.text = suggestion;
                  },
                )
              else
                CustomTextFormField(
                  controller: textController,
                  inputFormatters: [
                    FilteringTextInputFormatter.singleLineFormatter,
                    if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
                  ],
                  autoCorrect: true,
                  hint: title,
                ),
            ],
          ),
        ),
        actions: [
          if (optionalAction != null)
            FocusTraversalOrder(
              order: const NumericFocusOrder(5),
              child: TextButton(
                onPressed: () async {
                  optionalAction!.$2();
                  await Navigator.of(
                    context,
                  ).maybePop(T == String ? textController.value.text : null);
                },
                child: Text(optionalAction!.$1.toUpperCase()),
              ),
            ),
          if (onReset != null)
            FocusTraversalOrder(
              order: const NumericFocusOrder(4),
              child: TextButton(
                onPressed: () async {
                  onReset!();
                  await Navigator.of(context).maybePop();
                },
                child: Text(t.general.reset.toUpperCase()),
              ),
            ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: TextButton(
              onPressed: () async {
                await Navigator.of(context).maybePop();
              },
              child: Text(localizations.cancelButtonLabel.toUpperCase()),
            ),
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: TextButton(
              onPressed: () async {
                if (validator?.call(textController.value.text) == false) {
                  await Navigator.of(context).maybePop();
                } else if (mapTo != null) {
                  await Navigator.of(
                    context,
                  ).maybePop(mapTo!.call(textController.value.text));
                } else {
                  await Navigator.of(
                    context,
                  ).maybePop(T == String ? textController.value.text : null);
                }
              },
              child: Text(localizations.okButtonLabel.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}

class AutocompleteField extends StatelessWidget {
  const AutocompleteField({
    super.key,
    required this.initialValue,
    required this.options,
  });
  final List<String> options;
  final String initialValue;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(
        text: initialValue,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: initialValue.length,
        ), // Selects the entire text
      ),
      optionsBuilder: (TextEditingValue textEditingValue) {
        // if (textEditingValue.text == '') {
        //   return const Iterable<String>.empty();
        // }
        return options.where((String option) {
          return option.contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        //debugPrint('You just selected $selection');
      },
    );
  }
}

class SettingsPickerDialog<T> extends HookConsumerWidget with PresLogger {
  const SettingsPickerDialog({
    super.key,
    required this.title,
    required this.selected,
    required this.options,
    required this.getTitle,
    this.onReset,
  });

  final String title;
  final T selected;
  final List<T> options;
  final String Function(T e) getTitle;
  final VoidCallback? onReset;

  Future<T?> show(BuildContext context) {
    return showDialog(context: context, builder: (context) => this);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final localizations = MaterialLocalizations.of(context);

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (e) => RadioListTile<T>(
                  title: Text(getTitle(e)),
                  value: e,
                  groupValue: selected,
                  onChanged: (value) {
                    Navigator.of(context).maybePop(value);
                  },
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        if (onReset != null)
          TextButton(
            onPressed: () async {
              onReset!();
              await Navigator.of(context).maybePop();
            },
            child: Text(t.general.reset.toUpperCase()),
          ),
        TextButton(
          onPressed: () async {
            await Navigator.of(context).maybePop();
          },
          child: Text(localizations.cancelButtonLabel.toUpperCase()),
        ),
      ],
      scrollable: true,
    );
  }
}

class SettingsSliderDialog extends HookConsumerWidget with PresLogger {
  const SettingsSliderDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.onReset,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.labelGen,
  });

  final String title;
  final double initialValue;
  final VoidCallback? onReset;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value)? labelGen;

  Future<double?> show(BuildContext context) {
    return showDialog(context: context, builder: (context) => this);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final localizations = MaterialLocalizations.of(context);

    final sliderValue = useState(initialValue);

    return AlertDialog(
      title: Text(title),
      content: IntrinsicHeight(
        child: Slider(
          value: sliderValue.value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: (value) => sliderValue.value = value,
          label: labelGen?.call(sliderValue.value),
        ),
      ),
      actions: [
        if (onReset != null)
          TextButton(
            onPressed: () async {
              onReset!();
              await Navigator.of(context).maybePop();
            },
            child: Text(t.general.reset.toUpperCase()),
          ),
        TextButton(
          onPressed: () async {
            await Navigator.of(context).maybePop();
          },
          child: Text(localizations.cancelButtonLabel.toUpperCase()),
        ),
        TextButton(
          onPressed: () async {
            await Navigator.of(context).maybePop(sliderValue.value);
          },
          child: Text(localizations.okButtonLabel.toUpperCase()),
        ),
      ],
    );
  }
}
