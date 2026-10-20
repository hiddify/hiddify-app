import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/app_theme.dart';

class ConnectionButtonTheme extends ThemeExtension<ConnectionButtonTheme> {
  const ConnectionButtonTheme({this.idleColor, this.connectedColor, this.connectingColor, this.errorColor});

  final Color? idleColor;
  final Color? connectedColor;
  final Color? connectingColor;
  final Color? errorColor;

  static const ConnectionButtonTheme spriteNet = ConnectionButtonTheme(
    idleColor: SpriteNetColors.idle,
    connectedColor: SpriteNetColors.lime,
    connectingColor: SpriteNetColors.limeLight,
    errorColor: SpriteNetColors.alert,
  );

  // Kept for compatibility with upstream code that references the light preset.
  static const ConnectionButtonTheme light = spriteNet;

  @override
  ThemeExtension<ConnectionButtonTheme> copyWith({
    Color? idleColor,
    Color? connectedColor,
    Color? connectingColor,
    Color? errorColor,
  }) => ConnectionButtonTheme(
    idleColor: idleColor ?? this.idleColor,
    connectedColor: connectedColor ?? this.connectedColor,
    connectingColor: connectingColor ?? this.connectingColor,
    errorColor: errorColor ?? this.errorColor,
  );

  @override
  ThemeExtension<ConnectionButtonTheme> lerp(covariant ThemeExtension<ConnectionButtonTheme>? other, double t) {
    if (other is! ConnectionButtonTheme) {
      return this;
    }
    return ConnectionButtonTheme(
      idleColor: Color.lerp(idleColor, other.idleColor, t),
      connectedColor: Color.lerp(connectedColor, other.connectedColor, t),
      connectingColor: Color.lerp(connectingColor, other.connectingColor, t),
      errorColor: Color.lerp(errorColor, other.errorColor, t),
    );
  }
}
