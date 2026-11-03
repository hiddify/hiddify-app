import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/unique_keys_layout.dart';

Widget _switcher(String key, {AnimatedSwitcherLayoutBuilder? layout}) => Directionality(
  textDirection: TextDirection.ltr,
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    layoutBuilder: layout ?? AnimatedSwitcher.defaultLayoutBuilder,
    child: KeyedSubtree(key: ValueKey(key), child: Text(key)),
  ),
);

Future<void> _flip(WidgetTester tester, {AnimatedSwitcherLayoutBuilder? layout}) async {
  await tester.pumpWidget(_switcher('flag', layout: layout));
  await tester.pump(const Duration(milliseconds: 400));
  // a proxy's flag, its cached look and back, twice, faster than the switch takes: two flags fade
  // out at once
  for (final key in ['cached', 'flag', 'cached']) {
    await tester.pumpWidget(_switcher(key, layout: layout));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('a child back within the switch breaks the default layout', (tester) async {
    await _flip(tester);
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('it does not break the unique keys layout', (tester) async {
    await _flip(tester, layout: uniqueKeysLayout());
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('cached'), findsOneWidget);
    expect(find.text('flag'), findsNothing);
  });
}
