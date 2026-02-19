import 'package:flutter/material.dart';

class AutocompleteField extends StatelessWidget {
  const AutocompleteField({super.key, required this.initialValue, required this.options});
  final List<String> options;
  final String initialValue;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(
        text: initialValue,
        selection: TextSelection(baseOffset: 0, extentOffset: initialValue.length), // Selects the entire text
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
