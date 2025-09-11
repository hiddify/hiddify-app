import 'package:flutter/material.dart';

class ConnectionButtonTheme extends ThemeExtension<ConnectionButtonTheme> {
  const ConnectionButtonTheme({
    this.idleColor,
    this.connectedColor,
  });

  final Color? idleColor;
  final Color? connectedColor;

  static const ConnectionButtonTheme light = ConnectionButtonTheme(
    idleColor: Color(0xFF4a4d8b),
    connectedColor: Color(0xFF44a334),
  );

  static const ConnectionButtonTheme dark = ConnectionButtonTheme(
    idleColor: Color(0xFF6d70a8),
    connectedColor: Color(0xFF66c554),
  );

  static const ConnectionButtonTheme black = ConnectionButtonTheme(
    idleColor: Color(0xFF8085c0),
    connectedColor: Color(0xFF88e774),
  );

  @override
  ThemeExtension<ConnectionButtonTheme> copyWith({
    Color? idleColor,
    Color? connectedColor,
  }) =>
      ConnectionButtonTheme(
        idleColor: idleColor ?? this.idleColor,
        connectedColor: connectedColor ?? this.connectedColor,
      );

  @override
  ThemeExtension<ConnectionButtonTheme> lerp(
    covariant ThemeExtension<ConnectionButtonTheme>? other,
    double t,
  ) {
    if (other is! ConnectionButtonTheme) {
      return this;
    }
    return ConnectionButtonTheme(
      idleColor: Color.lerp(idleColor, other.idleColor, t),
      connectedColor: Color.lerp(connectedColor, other.connectedColor, t),
    );
  }
}
