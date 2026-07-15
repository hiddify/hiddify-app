import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/theme/app_theme.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/core/widget/nova_grouped_scaffold.dart';

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

  test('disabled switch thumb and track stay low emphasis even when selected', () {
    const combinedState = {WidgetState.selected, WidgetState.disabled};
    final thumb = theme.switchTheme.thumbColor!.resolve(combinedState);
    final track = theme.switchTheme.trackColor!.resolve(combinedState);

    expect(thumb, NovaColors.disabled);
    expect(thumb, isNot(Colors.white));
    expect(track, NovaColors.disabled);
    expect(track, isNot(NovaColors.ritualRed));
  });

  testWidgets('secondary route scaffold uses inherited grouped background', (tester) async {
    const groupedBackground = Color(0xFF101820);
    final routeTheme = theme.copyWith(
      extensions: <ThemeExtension<dynamic>>{NovaThemeData.dark.copyWith(groupedBackground: groupedBackground)},
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: routeTheme,
        home: const NovaGroupedScaffold(body: Text('Secondary route')),
      ),
    );

    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, groupedBackground);
  });

  testWidgets('secondary route content clears the injected mobile dock inset', (tester) async {
    const dockInset = 120.0;
    const targetKey = ValueKey('bottom_route_control');

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: const EdgeInsets.only(bottom: dockInset)),
          child: child!,
        ),
        home: const NovaGroupedScaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(key: targetKey, height: 44, child: Text('Bottom control')),
          ),
        ),
      ),
    );

    final scaffoldHeight = tester.getSize(find.byType(NovaGroupedScaffold)).height;
    expect(tester.getBottomRight(find.byKey(targetKey)).dy, lessThanOrEqualTo(scaffoldHeight - dockInset));
  });

  testWidgets('dialogs and production sheet surface inherit elevated dark chrome', (tester) async {
    const modalColor = Color(0xFF303840);
    final overlayTheme = theme.copyWith(bottomSheetTheme: const BottomSheetThemeData(modalBackgroundColor: modalColor));

    await tester.pumpWidget(
      MaterialApp(
        theme: overlayTheme,
        darkTheme: overlayTheme,
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
                  onPressed: () {},
                  child: const ThemedBottomSheetSurface(child: Text('Панель')),
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

    final sheetMaterial = tester.widget<Material>(find.byKey(const ValueKey('themed_bottom_sheet_material')));
    expect(sheetMaterial.color, modalColor);
  });
}
