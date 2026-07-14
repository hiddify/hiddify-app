import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/features/home/widget/nova_ritual_hero.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  testWidgets('renders Home ritual copy from the English translations provider', (tester) async {
    final translations = await AppLocale.en.build();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationsProvider.overrideWith((ref) => translations)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final t = ref.watch(translationsProvider).requireValue;
              return Scaffold(
                body: NovaRitualHero(
                  state: NovaRitualState.disconnected,
                  statusLabel: t.connection.tapToConnect,
                  child: const Text('control'),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Tap to connect'), findsOneWidget);
    expect(find.text('Ты на виду · нажми кнопку'), findsNothing);
  });

  testWidgets('presents the connected ritual state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NovaRitualHero(
            state: NovaRitualState.connected,
            statusLabel: 'Connected',
            callToActionLabel: 'Welcome back',
            child: Text('control'),
          ),
        ),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
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

    expect(tester.widget<Text>(find.text('Connection error')).style?.color, error);
  });
}
