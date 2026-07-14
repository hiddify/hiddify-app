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
  });
}
