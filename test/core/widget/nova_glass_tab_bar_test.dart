import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/adaptive_layout/nova_tab_route.dart';
import 'package:hiddify/core/widget/nova_glass_tab_bar.dart';
import 'package:hiddify/gen/translations_ru.g.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../helpers/nova_theme_fixture.dart';

void main() {
  testWidgets('shows English provider labels visibly and in semantics', (tester) async {
    final translations = await AppLocale.en.build();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationsProvider.overrideWith((ref) => translations)],
        child: MaterialApp(
          theme: ThemeData(extensions: const [inheritedTheme]),
          home: Consumer(
            builder: (context, ref, _) {
              final t = ref.watch(translationsProvider).requireValue;
              return Scaffold(
                body: Stack(
                  children: [
                    NovaGlassTabBar(
                      selected: NovaTab.home,
                      labels: {
                        NovaTab.home: t.pages.home.title,
                        NovaTab.servers: t.pages.proxies.title,
                        NovaTab.rules: t.pages.settings.routing.title,
                        NovaTab.settings: t.pages.settings.title,
                      },
                      onSelected: (_) {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    for (final label in const ['Home', 'Proxies', 'Routing', 'Settings']) {
      expect(find.text(label), findsOneWidget);
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
  });

  testWidgets('keeps the Russian rules destination concise and fully visible', (tester) async {
    final translations = TranslationsRu();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [inheritedTheme]),
        home: Scaffold(
          body: Stack(
            children: [
              NovaGlassTabBar(
                selected: NovaTab.rules,
                labels: {
                  NovaTab.home: translations.pages.home.title,
                  NovaTab.servers: translations.pages.proxies.title,
                  NovaTab.rules: translations.pages.settings.routing.title,
                  NovaTab.settings: translations.pages.settings.title,
                },
                onSelected: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(translations.pages.settings.routing.title, 'Правила');
    expect(find.text('Правила'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows four labeled destinations and reports selection', (tester) async {
    var selected = NovaTab.home;
    final selections = <NovaTab>[];

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
                  onSelected: (value) {
                    selections.add(value);
                    setState(() => selected = value);
                  },
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
    expect(find.byType(BackdropFilter), findsOneWidget);
    final dockSurface = tester.widget<DecoratedBox>(find.byKey(const ValueKey('nova_dock_surface')));
    expect((dockSurface.decoration as BoxDecoration).color, inheritedTheme.glass);

    expect(tester.getSemantics(find.bySemanticsLabel('Главная')).flagsCollection.isSelected, Tristate.isTrue);
    expect(tester.getSemantics(find.bySemanticsLabel('Серверы')).flagsCollection.isSelected, Tristate.isFalse);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Главная')).getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(find.bySemanticsLabel('Правила'), findsOneWidget);
    expect(find.bySemanticsLabel('Настройки'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Серверы'));
    await tester.pumpAndSettle();

    expect(selected, NovaTab.servers);
    expect(selections, [NovaTab.servers]);
    expect(tester.getSemantics(find.bySemanticsLabel('Серверы')).flagsCollection.isSelected, Tristate.isTrue);

    tester.semantics.tap(
      find.semantics.byPredicate(
        (node) => node.label == 'Настройки' && node.getSemanticsData().hasAction(SemanticsAction.tap),
      ),
    );
    await tester.pumpAndSettle();
    expect(selections, [NovaTab.servers, NovaTab.settings]);
  });

  testWidgets('reports a tap when the selected destination is reselected', (tester) async {
    final selections = <NovaTab>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [inheritedTheme]),
        home: Scaffold(
          body: Stack(
            children: [
              NovaGlassTabBar(
                selected: NovaTab.home,
                labels: const {NovaTab.home: 'Главная'},
                onSelected: selections.add,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Главная'));
    await tester.pump();
    expect(selections, [NovaTab.home]);
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
    expect(decoration.border, Border.all(color: inheritedTheme.separator, width: 1.5));
    final inactiveIcons = tester.widgetList<Icon>(find.byType(Icon)).where((icon) => icon.icon != Icons.home_rounded);
    expect(inactiveIcons.every((icon) => icon.color == inheritedTheme.secondaryText), isTrue);
    for (final label in const ['Серверы', 'Правила', 'Настройки']) {
      expect(tester.widget<Text>(find.text(label)).style?.color, inheritedTheme.secondaryText);
    }
    expect(
      tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).every((w) => w.duration == Duration.zero),
      isTrue,
    );
  });

  for (final media in const [
    MediaQueryData(disableAnimations: true),
    MediaQueryData(accessibleNavigation: true),
    MediaQueryData(highContrast: true),
  ]) {
    testWidgets('uses an opaque dock for available reduced-effects signal $media', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [inheritedTheme]),
          home: MediaQuery(
            data: media,
            child: Scaffold(
              body: Stack(
                children: [NovaGlassTabBar(selected: NovaTab.home, labels: const {}, onSelected: (_) {})],
              ),
            ),
          ),
        ),
      );

      final surface = tester.widget<DecoratedBox>(find.byKey(const ValueKey('nova_dock_surface')));
      expect((surface.decoration as BoxDecoration).color, inheritedTheme.elevatedSurface);
      expect(find.byType(BackdropFilter), findsNothing);
    });
  }
}
