import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/arrow_keys_move_focus.dart';

void main() {
  Future<List<String?>> pump(WidgetTester tester, {required bool wrapped}) async {
    final changes = <String?>[];
    Widget list = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in ['en', 'fa', 'ru'])
          RadioListTile<String>(title: Text(e), value: e, autofocus: e == 'en'),
      ],
    );
    if (wrapped) list = ArrowKeysMoveFocus(child: list);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RadioGroup<String>(groupValue: 'en', onChanged: changes.add, child: list),
        ),
      ),
    );
    await tester.pump();
    return changes;
  }

  testWidgets("without it, the down arrow selects the next radio", (tester) async {
    final changes = await pump(tester, wrapped: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(changes, ['fa']);
  });

  testWidgets("the down arrow only moves the focus, and Enter selects", (tester) async {
    final changes = await pump(tester, wrapped: true);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(changes, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(changes, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(changes, ['ru']);
  });
}
