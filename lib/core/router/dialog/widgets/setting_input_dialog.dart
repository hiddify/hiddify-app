import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingInputDialog<T> extends HookConsumerWidget with PresLogger {
  const SettingInputDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.mapTo,
    this.validator,
    this.valueFormatter,
    this.possibleValues,
    this.onReset,
    this.optionalAction,
    this.icon,
    this.digitsOnly = false,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final localizations = MaterialLocalizations.of(context);

    final textController = useTextEditingController(
      text: valueFormatter?.call(initialValue) ?? initialValue.toString(),
    );
    // focus management
    final okBtnFocusNode = useFocusNode();
    KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
      if (KeyboardConst.select.contains(event.logicalKey) && event is KeyDownEvent) {
        okBtnFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    return AlertDialog(
      title: Text(title),
      icon: icon != null ? Icon(icon) : null,
      // material: (context, platform) => MaterialAlertDialogData(
      //   icon: icon != null ? Icon(icon) : null,
      // ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (possibleValues != null)
            // AutocompleteField(initialValue: initialValue.toString(), options: possibleValues!.map((e) => e.toString()).toList())
            TypeAheadField<String>(
              controller: textController,
              builder: (context, controller, focusNode) {
                focusNode.onKeyEvent = handleKeyEvent;
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
                    .where((suggestion) => suggestion.toLowerCase().contains(pattern.toLowerCase()))
                    .toList();
                if (res.length <= 1) res = [pattern, ...items.where((s) => s != pattern)];
                return res;
              },
              // Widget to build each suggestion in the list
              itemBuilder: (context, suggestion) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10), // Minimize ListTile padding
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
                // print('Selected: $suggestion');
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
      actions: [
        if (optionalAction != null)
          TextButton(
            onPressed: () {
              optionalAction!.$2();
              context.pop(T == String ? textController.value.text : null);
            },
            child: Text(optionalAction!.$1.toUpperCase()),
          ),
        if (onReset != null)
          TextButton(
            onPressed: () {
              onReset!();
              context.pop();
            },
            child: Text(t.common.reset),
          ),
        TextButton(
          onPressed: () {
            context.pop();
          },
          child: Text(localizations.cancelButtonLabel.toUpperCase()),
        ),
        TextButton(
          focusNode: okBtnFocusNode,
          onPressed: () {
            if (validator?.call(textController.value.text) == false) {
              context.pop();
            } else if (mapTo != null) {
              context.pop(mapTo!.call(textController.value.text));
            } else {
              context.pop(T == String ? textController.value.text : null);
            }
          },
          child: Text(localizations.okButtonLabel.toUpperCase()),
        ),
      ],
    );
  }
}
