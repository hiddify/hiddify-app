import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:hiddify/core/theme/app_colors.dart';

class ConnectionButtonTheme extends ThemeExtension<ConnectionButtonTheme> {
  const ConnectionButtonTheme({this.idleColor, this.connectedColor});

  final Color? idleColor;
  final Color? connectedColor;

  static const ConnectionButtonTheme light = ConnectionButtonTheme(
    idleColor: Color(0xFF4a4d8b), // Custom idle color
    connectedColor: AppColors.connected,
  );
  static const ConnectionButtonTheme dark = ConnectionButtonTheme(
    idleColor: Color(0xFF4a4d8b),
    connectedColor: AppColors.connected,
  );

  @override
  ThemeExtension<ConnectionButtonTheme> copyWith({
    Color? idleColor,
    Color? connectedColor,
  }) => ConnectionButtonTheme(
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

class JsonEditorTheme extends ThemeExtension<JsonEditorTheme> {
  const JsonEditorTheme({
    this.indentSpacing = 18,
    this.textStyle = const TextStyle(fontSize: 16),
    this.expandIconWidth = 10,
    this.rowHeight = 30,
    this.popupMenuHeight = 30,
    this.popupMenuItemPadding = 20,
  });

  final double indentSpacing;
  final TextStyle textStyle;
  final double expandIconWidth;
  final double rowHeight;
  final double popupMenuHeight;
  final double popupMenuItemPadding;

  static const JsonEditorTheme standard = JsonEditorTheme();

  @override
  JsonEditorTheme copyWith({
    double? indentSpacing,
    TextStyle? textStyle,
    double? expandIconWidth,
    double? rowHeight,
    double? popupMenuHeight,
    double? popupMenuItemPadding,
  }) => JsonEditorTheme(
      indentSpacing: indentSpacing ?? this.indentSpacing,
      textStyle: textStyle ?? this.textStyle,
      expandIconWidth: expandIconWidth ?? this.expandIconWidth,
      rowHeight: rowHeight ?? this.rowHeight,
      popupMenuHeight: popupMenuHeight ?? this.popupMenuHeight,
      popupMenuItemPadding: popupMenuItemPadding ?? this.popupMenuItemPadding,
    );

  @override
  JsonEditorTheme lerp(JsonEditorTheme? other, double t) {
    if (other == null) return this;
    return JsonEditorTheme(
      indentSpacing:
          lerpDouble(indentSpacing, other.indentSpacing, t) ?? indentSpacing,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t) ?? textStyle,
      expandIconWidth:
          lerpDouble(expandIconWidth, other.expandIconWidth, t) ??
          expandIconWidth,
      rowHeight: lerpDouble(rowHeight, other.rowHeight, t) ?? rowHeight,
      popupMenuHeight:
          lerpDouble(popupMenuHeight, other.popupMenuHeight, t) ??
          popupMenuHeight,
      popupMenuItemPadding:
          lerpDouble(popupMenuItemPadding, other.popupMenuItemPadding, t) ??
          popupMenuItemPadding,
    );
  }
}
