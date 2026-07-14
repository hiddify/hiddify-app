import 'package:flutter/material.dart';

abstract final class NovaColors {
  static const voidBackground = Color(0xFF060608);
  static const groupedBackground = Color(0xFF000000);
  static const surface = Color(0xFF1C1C1E);
  static const elevatedSurface = Color(0xFF2C2C2E);
  static const pressedSurface = Color(0xFF3A3A3C);
  static const glassRegular = Color(0xD91C1C1E);

  static const primaryText = Color(0xFFF2F2F7);
  static const secondaryText = Color(0xFFA1A1AA);
  static const tertiaryText = Color(0xFF6E6E73);
  static const mutedText = Color(0xFF48484A);

  static const ritualRed = Color(0xFFFF2D3E);
  static const ritualRedHover = Color(0xFFFF5C68);
  static const ritualRedPressed = Color(0xFFE01B2C);
  static const ritualRedContainer = Color(0xFF3A1016);
  static const ritualRedTint = Color(0x24FF2D3E);
  static const ritualRedGlow = Color(0x73FF2D3E);

  static const signalGood = Color(0xFF30D158);
  static const signalMid = Color(0xFFFF9F0A);
  static const signalBad = Color(0xFFFF453A);

  static const separator = Color(0x52545458);
  static const border = Color(0x3D545458);
  static const borderStrong = Color(0x80545458);
  static const disabled = Color(0x4D787880);
}

abstract final class NovaSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const gutter = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class NovaRadii {
  static const small = 10.0;
  static const medium = 14.0;
  static const large = 18.0;
  static const extraLarge = 22.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

abstract final class NovaDockTokens {
  static const height = 64.0;
  static const horizontalInset = 12.0;
  static const bottomGap = 8.0;
  static const minimumTarget = 44.0;
  static const blur = 28.0;
  static const radius = height / 2;
  static const contentClearance = height + bottomGap + 24;
}

@immutable
class NovaThemeData extends ThemeExtension<NovaThemeData> {
  const NovaThemeData({
    required this.background,
    required this.groupedBackground,
    required this.surface,
    required this.elevatedSurface,
    required this.pressedSurface,
    required this.glass,
    required this.separator,
    required this.border,
    required this.disabled,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.accent,
    required this.accentHover,
    required this.accentFill,
  });

  static const dark = NovaThemeData(
    background: NovaColors.voidBackground,
    groupedBackground: NovaColors.groupedBackground,
    surface: NovaColors.surface,
    elevatedSurface: NovaColors.elevatedSurface,
    pressedSurface: NovaColors.pressedSurface,
    glass: NovaColors.glassRegular,
    separator: NovaColors.separator,
    border: NovaColors.border,
    disabled: NovaColors.disabled,
    primaryText: NovaColors.primaryText,
    secondaryText: NovaColors.secondaryText,
    tertiaryText: NovaColors.tertiaryText,
    accent: NovaColors.ritualRed,
    accentHover: NovaColors.ritualRedHover,
    accentFill: NovaColors.ritualRedTint,
  );

  static const light = NovaThemeData(
    background: Color(0xFFF6F6F8),
    groupedBackground: Color(0xFFF2F2F7),
    surface: Colors.white,
    elevatedSurface: Color(0xFFF0F0F4),
    pressedSurface: Color(0xFFE5E5EA),
    glass: Color(0xD9FFFFFF),
    separator: Color(0x4A3C3C43),
    border: Color(0x1F000000),
    disabled: Color(0x4D787880),
    primaryText: Color(0xFF101015),
    secondaryText: Color(0xFF55555F),
    tertiaryText: Color(0xFF6D6D77),
    accent: NovaColors.ritualRed,
    accentHover: NovaColors.ritualRedPressed,
    accentFill: NovaColors.ritualRedTint,
  );

  static NovaThemeData of(BuildContext context) => Theme.of(context).extension<NovaThemeData>() ?? dark;

  final Color background;
  final Color groupedBackground;
  final Color surface;
  final Color elevatedSurface;
  final Color pressedSurface;
  final Color glass;
  final Color separator;
  final Color border;
  final Color disabled;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color accent;
  final Color accentHover;
  final Color accentFill;

  @override
  NovaThemeData copyWith({
    Color? background,
    Color? groupedBackground,
    Color? surface,
    Color? elevatedSurface,
    Color? pressedSurface,
    Color? glass,
    Color? separator,
    Color? border,
    Color? disabled,
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? accent,
    Color? accentHover,
    Color? accentFill,
  }) => NovaThemeData(
    background: background ?? this.background,
    groupedBackground: groupedBackground ?? this.groupedBackground,
    surface: surface ?? this.surface,
    elevatedSurface: elevatedSurface ?? this.elevatedSurface,
    pressedSurface: pressedSurface ?? this.pressedSurface,
    glass: glass ?? this.glass,
    separator: separator ?? this.separator,
    border: border ?? this.border,
    disabled: disabled ?? this.disabled,
    primaryText: primaryText ?? this.primaryText,
    secondaryText: secondaryText ?? this.secondaryText,
    tertiaryText: tertiaryText ?? this.tertiaryText,
    accent: accent ?? this.accent,
    accentHover: accentHover ?? this.accentHover,
    accentFill: accentFill ?? this.accentFill,
  );

  @override
  NovaThemeData lerp(covariant NovaThemeData? other, double t) {
    if (other == null) return this;
    return NovaThemeData(
      background: Color.lerp(background, other.background, t)!,
      groupedBackground: Color.lerp(groupedBackground, other.groupedBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      pressedSurface: Color.lerp(pressedSurface, other.pressedSurface, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      border: Color.lerp(border, other.border, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentFill: Color.lerp(accentFill, other.accentFill, t)!,
    );
  }
}
