import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/home/widget/nova_connection_control.dart';

import '../../../helpers/nova_theme_fixture.dart';

void main() {
  testWidgets('keeps the connection action accessible and tappable', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [inheritedTheme]),
        home: Scaffold(
          body: NovaConnectionControl(
            enabled: true,
            connected: false,
            loading: false,
            label: 'Подключиться',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    final control = find.byKey(const ValueKey('home_connection_button'));
    expect(control, findsOneWidget);
    expect(tester.getSemantics(control).flagsCollection.isButton, isTrue);
    expect(tester.getSemantics(control).label, contains('Подключиться'));
    expect(tester.getSemantics(control).getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(tester.getSize(control).shortestSide, greaterThanOrEqualTo(44));
    final icon = tester.widget<Icon>(find.byIcon(Icons.power_settings_new_rounded));
    expect(icon.color, inheritedTheme.secondaryText);
    final gradientSurface = tester
        .widgetList<DecoratedBox>(find.descendant(of: control, matching: find.byType(DecoratedBox)))
        .singleWhere((widget) => (widget.decoration as BoxDecoration).gradient != null);
    expect(((gradientSurface.decoration as BoxDecoration).gradient! as RadialGradient).colors, [
      inheritedTheme.elevatedSurface,
      inheritedTheme.background,
    ]);

    await tester.tap(control);
    await tester.pump();
    expect(taps, 1);

    tester.semantics.tap(
      find.semantics.byPredicate(
        (node) => node.label == 'Подключиться' && node.getSemanticsData().hasAction(SemanticsAction.tap),
      ),
    );
    await tester.pump();
    expect(taps, 2);
  });

  testWidgets('uses disabled semantics and no animation for accessibility', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [inheritedTheme]),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: NovaConnectionControl(
              enabled: false,
              connected: false,
              loading: false,
              label: 'Недоступно',
              onTap: _noop,
            ),
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.power_settings_new_rounded));
    expect(icon.color, inheritedTheme.disabled);
    expect(tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration, Duration.zero);
    final control = find.byKey(const ValueKey('home_connection_button'));
    expect(tester.getSemantics(control).getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
  });
}

void _noop() {}
