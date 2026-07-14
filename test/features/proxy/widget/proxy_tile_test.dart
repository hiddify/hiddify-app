import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('selected server uses red tint while latency keeps status color', (tester) async {
    final theme = AppTheme(AppThemeMode.dark, 'Shabnam').darkTheme(null);
    final proxy = OutboundInfo(tag: 'auto', type: 'urltest', urlTestDelay: 120);
    final translations = await AppLocale.en.build();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationsProvider.overrideWith((ref) => translations)],
        child: MaterialApp(
          theme: theme,
          darkTheme: theme,
          themeMode: ThemeMode.dark,
          home: Scaffold(body: ProxyTile(proxy, selected: true, onTap: () {})),
        ),
      ),
    );

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.selectedTileColor, NovaThemeData.dark.accentFill);
    expect(tile.selectedColor, NovaColors.ritualRed);
    expect(tester.widget<Text>(find.text('120')).style!.color, NovaColors.signalGood);
    expect(find.byKey(const ValueKey('proxy_selected_indicator')), findsOneWidget);
    expect(tester.widget<Icon>(find.byKey(const ValueKey('proxy_selected_indicator'))).icon, Icons.check_rounded);
  });

  test('keeps latency colors on explicit mid and bad boundaries', () {
    final tile = ProxyTile(OutboundInfo(), selected: false, onTap: null);

    expect(tile.delayColor(799), NovaColors.signalGood);
    expect(tile.delayColor(800), NovaColors.signalMid);
    expect(tile.delayColor(1499), NovaColors.signalMid);
    expect(tile.delayColor(1500), NovaColors.signalBad);
  });

  testWidgets('selected server consumes the inherited Nova theme', (tester) async {
    const customNova = NovaThemeData.dark;
    const customAccent = Color(0xFF00BCD4);
    const customFill = Color(0x3300BCD4);
    final theme = AppTheme(AppThemeMode.dark, 'Shabnam')
        .darkTheme(null)
        .copyWith(
          extensions: <ThemeExtension<dynamic>>{customNova.copyWith(accent: customAccent, accentFill: customFill)},
        );
    final translations = await AppLocale.en.build();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationsProvider.overrideWith((ref) => translations)],
        child: MaterialApp(
          theme: theme,
          darkTheme: theme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: ProxyTile(
              OutboundInfo(tag: 'custom', type: 'direct', urlTestDelay: 900),
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.selectedColor, customAccent);
    expect(tile.selectedTileColor, customFill);
    expect(tester.widget<Icon>(find.byKey(const ValueKey('proxy_selected_indicator'))).color, customAccent);
    expect(tester.widget<Text>(find.text('900')).style!.color, NovaColors.signalMid);
  });
}
