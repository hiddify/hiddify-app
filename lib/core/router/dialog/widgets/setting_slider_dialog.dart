import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final localizations = MaterialLocalizations.of(context);

    final sliderValue = useState(initialValue);
    final sliderFocusNode = useFocusNode(
      onKeyEvent: (node, event) {
        if (KeyboardConst.verticalArrows.contains(event.logicalKey) && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            node.nextFocus();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );

    return AlertDialog(
      title: Text(title),
      content: IntrinsicHeight(
        child: Slider(
          focusNode: sliderFocusNode,
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
            onPressed: () {
              onReset!();
              context.pop();
            },
            child: Text(t.common.reset),
          ),
        TextButton(onPressed: () => context.pop(), child: Text(localizations.cancelButtonLabel.toUpperCase())),
        TextButton(
          onPressed: () => context.pop(sliderValue.value),
          child: Text(localizations.okButtonLabel.toUpperCase()),
        ),
      ],
    );
  }
}
