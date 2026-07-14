import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/core/widget/nova_glass_tab_bar.dart';

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
  testWidgets('shows four labeled destinations and reports selection', (tester) async {
    var selected = NovaTab.home;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [inheritedTheme]),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                NovaGlassTabBar(
                  selected: selected,
                  labels: const {
                    NovaTab.home: 'Главная',
                    NovaTab.servers: 'Серверы',
                    NovaTab.rules: 'Правила',
                    NovaTab.settings: 'Настройки',
                  },
                  onSelected: (value) => setState(() => selected = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('Серверы'), findsOneWidget);
    expect(find.text('Правила'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);

    final homeIcon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
    expect(homeIcon.color, inheritedTheme.accentHover);
    final dockSurface = tester.widget<DecoratedBox>(find.byKey(const ValueKey('nova_dock_surface')));
    expect((dockSurface.decoration as BoxDecoration).color, inheritedTheme.glass);

    expect(tester.getSemantics(find.bySemanticsLabel('Главная')).flagsCollection.isSelected, Tristate.isTrue);
    expect(tester.getSemantics(find.bySemanticsLabel('Серверы')).flagsCollection.isSelected, Tristate.isFalse);
    expect(find.bySemanticsLabel('Правила'), findsOneWidget);
    expect(find.bySemanticsLabel('Настройки'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Серверы'));
    await tester.pumpAndSettle();

    expect(selected, NovaTab.servers);
    expect(tester.getSemantics(find.bySemanticsLabel('Серверы')).flagsCollection.isSelected, Tristate.isTrue);
  });

  testWidgets('uses opaque semantic dock treatment and no animation for accessibility', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [inheritedTheme]),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true, highContrast: true),
          child: Scaffold(
            body: Stack(
              children: [
                NovaGlassTabBar(
                  selected: NovaTab.home,
                  labels: const {
                    NovaTab.home: 'Главная',
                    NovaTab.servers: 'Серверы',
                    NovaTab.rules: 'Правила',
                    NovaTab.settings: 'Настройки',
                  },
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final surface = tester.widget<DecoratedBox>(find.byKey(const ValueKey('nova_dock_surface')));
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.color, inheritedTheme.elevatedSurface);
    expect(decoration.border, Border.all(color: inheritedTheme.separator));
    expect(
      tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).every((w) => w.duration == Duration.zero),
      isTrue,
    );
  });
}
