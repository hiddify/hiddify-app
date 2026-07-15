import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/home/widget/nova_ritual_hero.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../helpers/nova_theme_fixture.dart';

void main() {
  testWidgets('omits duplicate ritual copy with the English translations provider', (tester) async {
    final translations = await AppLocale.en.build();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationsProvider.overrideWith((ref) => translations)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final t = ref.watch(translationsProvider).requireValue;
              return Scaffold(
                body: NovaRitualHero(state: NovaRitualState.disconnected, child: Text(t.pages.home.title)),
              );
            },
          ),
        ),
      ),
    );

    expect(translations.connection.tapToConnect, 'Tap to connect');
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tap to connect'), findsNothing);
    expect(find.text('Ты на виду · нажми кнопку'), findsNothing);
  });

  testWidgets('presents the connected ritual state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NovaRitualHero(state: NovaRitualState.connected, statusLabel: 'Connected', child: Text('control')),
        ),
      ),
    );

    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('control'), findsOneWidget);
  });

  testWidgets('presents the disconnected ritual state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [inheritedTheme]),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true, highContrast: true),
          child: Scaffold(
            body: NovaRitualHero(
              state: NovaRitualState.disconnected,
              statusLabel: 'Tap to connect',
              child: Text('control'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Tap to connect'), findsOneWidget);
    expect(find.bySemanticsLabel('ア'), findsNothing);
    expect(find.bySemanticsLabel('0'), findsNothing);
    final status = tester.widget<Text>(find.text('Tap to connect'));
    expect(status.style?.color, inheritedTheme.tertiaryText);
  });

  testWidgets('uses the semantic error color for ritual errors', (tester) async {
    const error = Color(0xFFCC3344);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(error: error),
          extensions: const [inheritedTheme],
        ),
        home: const Scaffold(
          body: NovaRitualHero(state: NovaRitualState.error, statusLabel: 'Connection error', child: Text('control')),
        ),
      ),
    );

    expect(find.text('Connection error'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Connection error')).style?.color, error);
  });
}
