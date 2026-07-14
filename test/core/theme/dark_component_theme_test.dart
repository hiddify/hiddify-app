import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';

void main() {
  final theme = AppTheme(AppThemeMode.dark, 'Shabnam').darkTheme(null);

  testWidgets('settings and rules controls stay dark with red selection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: ListView(
            children: const [
              ListTile(key: ValueKey('settings_row'), title: Text('Настройки'), subtitle: Text('Описание')),
              SwitchListTile(value: true, onChanged: null, title: Text('Правило')),
            ],
          ),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor ?? theme.scaffoldBackgroundColor, NovaColors.voidBackground);
    expect(theme.listTileTheme.textColor, NovaColors.primaryText);
    expect(theme.switchTheme.trackColor!.resolve({WidgetState.selected}), NovaColors.ritualRed);
  });

  testWidgets('dialogs and sheets inherit elevated dark chrome', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const AlertDialog(content: Text('Диалог')),
                  ),
                  child: const Text('Открыть диалог'),
                ),
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const SizedBox(height: 100, child: Text('Панель')),
                  ),
                  child: const Text('Открыть панель'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть диалог'));
    await tester.pumpAndSettle();
    expect(tester.widget<Material>(find.byType(Material).last).color, isNot(Colors.white));
    Navigator.of(tester.element(find.text('Диалог'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Открыть панель'));
    await tester.pumpAndSettle();
    expect(theme.bottomSheetTheme.modalBackgroundColor, NovaColors.elevatedSurface);
  });
}
