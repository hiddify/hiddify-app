import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/features/home/widget/nova_connection_control.dart';

const inheritedTheme = NovaThemeData(
  background: Color(0xFF010203),
  groupedBackground: Color(0xFF020304),
  surface: Color(0xFF030405),
  elevatedSurface: Color(0xFF040506),
  pressedSurface: Color(0xFF050607),
  glass: Color(0xEE060708),
  border: Color(0xFF070809),
  separator: Color(0xFF08090A),
  primaryText: Color(0xFFFAFAFA),
  secondaryText: Color(0xFFB0B0B0),
  tertiaryText: Color(0xFF909090),
  disabled: Color(0xFF505050),
  accent: Color(0xFFAA1122),
  accentHover: Color(0xFFBB2233),
  accentFill: Color(0x33AA1122),
);

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
