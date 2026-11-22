import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/details/json_editor.dart';

void main() {
  testWidgets('JSON digits keep their code font in the tree and text editors', (tester) async {
    const data = {'key123': '0123456789', 'port': 10443, 'label': 'فارسی ۱۲۳'};
    dynamic edited;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Shabnam'),
        home: Scaffold(
          body: JsonEditor(json: jsonEncode(data), onChanged: (value) => edited = value),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final text in ['key123', '0123456789', '10443', 'فارسی ۱۲۳']) {
      expect(tester.widget<Text>(find.text(text)).style?.fontFamily, 'monospace');
    }

    await tester.tap(find.byTooltip('Change editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    final field = find.byType(EditableText);
    final editor = tester.widget<EditableText>(field);
    expect(editor.style.fontFamily, 'monospace');
    expect(jsonDecode(editor.controller.text), data);

    final updated = {...data, 'port': 20443};
    await tester.enterText(field, jsonEncode(updated));
    await tester.pump(const Duration(milliseconds: 501));
    expect(edited, updated);
  });
}
