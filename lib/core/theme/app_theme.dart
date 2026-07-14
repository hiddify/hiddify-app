import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';

class AppTheme {
  AppTheme(this.mode, this.fontFamily);
  static const brandSeedColor = Color(0xFFFF2D3E);

  final AppThemeMode mode;
  final String fontFamily;

  ThemeData lightTheme(ColorScheme? lightColorScheme) {
    final ColorScheme scheme = lightColorScheme ?? ColorScheme.fromSeed(seedColor: brandSeedColor);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.light},
    );
  }

  ThemeData darkTheme(ColorScheme? _) {
    const nova = NovaThemeData.dark;
    const scheme = ColorScheme.dark(
      primary: NovaColors.ritualRed,
      onPrimary: Colors.white,
      primaryContainer: NovaColors.ritualRedContainer,
      onPrimaryContainer: Color(0xFFFFB3BA),
      secondary: NovaColors.ritualRed,
      onSecondary: Colors.white,
      secondaryContainer: NovaColors.ritualRedContainer,
      onSecondaryContainer: Color(0xFFFFB3BA),
      error: NovaColors.signalBad,
      // ignore: avoid_redundant_argument_values
      onError: Colors.black,
      surface: NovaColors.surface,
      onSurface: NovaColors.primaryText,
      onSurfaceVariant: NovaColors.secondaryText,
      outline: NovaColors.separator,
      outlineVariant: NovaColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: nova.background,
      fontFamily: fontFamily,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: NovaColors.voidBackground,
        foregroundColor: NovaColors.primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: nova.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NovaRadii.large)),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: NovaColors.surface,
        textColor: NovaColors.primaryText,
        iconColor: NovaColors.secondaryText,
        selectedColor: NovaColors.ritualRed,
        selectedTileColor: NovaColors.ritualRedTint,
        minVerticalPadding: NovaSpacing.sm,
      ),
      dividerTheme: const DividerThemeData(color: NovaColors.separator, thickness: 0.5, space: 1),
      iconTheme: const IconThemeData(color: NovaColors.secondaryText),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: NovaColors.elevatedSurface,
        modalBackgroundColor: NovaColors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: NovaColors.tertiaryText,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: NovaColors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NovaRadii.sheet)),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(NovaColors.elevatedSurface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(NovaRadii.medium))),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NovaColors.surface,
        labelStyle: const TextStyle(color: NovaColors.secondaryText),
        hintStyle: const TextStyle(color: NovaColors.tertiaryText),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(NovaRadii.medium)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NovaRadii.medium),
          borderSide: const BorderSide(color: NovaColors.ritualRed, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : NovaColors.secondaryText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? NovaColors.ritualRed : NovaColors.pressedSurface,
        ),
      ),
      checkboxTheme: CheckboxThemeData(fillColor: WidgetStateProperty.resolveWith(_selectionFill)),
      radioTheme: RadioThemeData(fillColor: WidgetStateProperty.resolveWith(_selectionFill)),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: NovaColors.ritualRed,
        linearTrackColor: NovaColors.pressedSurface,
        circularTrackColor: NovaColors.pressedSurface,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NovaColors.ritualRed,
        foregroundColor: Colors.white,
      ),
      extensions: const <ThemeExtension<dynamic>>{ConnectionButtonTheme.light, NovaThemeData.dark},
    );
  }

  static Color? _selectionFill(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return NovaColors.disabled;
    if (states.contains(WidgetState.selected)) return NovaColors.ritualRed;
    return NovaColors.tertiaryText;
  }

  CupertinoThemeData cupertinoThemeData(bool sysDark, ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
    const def = CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: NovaColors.ritualRed,
      scaffoldBackgroundColor: NovaColors.voidBackground,
    );
    final defaultMaterialTheme = darkTheme(darkColorScheme);
    return MaterialBasedCupertinoThemeData(
      materialTheme: defaultMaterialTheme.copyWith(
        cupertinoOverrideTheme: def.copyWith(
          textTheme: CupertinoTextThemeData(
            textStyle: def.textTheme.textStyle.copyWith(fontFamily: fontFamily),
            actionTextStyle: def.textTheme.actionTextStyle.copyWith(fontFamily: fontFamily),
            navActionTextStyle: def.textTheme.navActionTextStyle.copyWith(fontFamily: fontFamily),
            navTitleTextStyle: def.textTheme.navTitleTextStyle.copyWith(fontFamily: fontFamily),
            navLargeTitleTextStyle: def.textTheme.navLargeTitleTextStyle.copyWith(fontFamily: fontFamily),
            pickerTextStyle: def.textTheme.pickerTextStyle.copyWith(fontFamily: fontFamily),
            dateTimePickerTextStyle: def.textTheme.dateTimePickerTextStyle.copyWith(fontFamily: fontFamily),
            tabLabelTextStyle: def.textTheme.tabLabelTextStyle.copyWith(fontFamily: fontFamily),
          ).copyWith(),
          barBackgroundColor: def.barBackgroundColor,
          scaffoldBackgroundColor: def.scaffoldBackgroundColor,
        ),
      ),
    );
  }
}
