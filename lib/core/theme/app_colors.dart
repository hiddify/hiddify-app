import 'package:flutter/material.dart';

/// Centralized definition of application colors.
/// 
/// This class holds the core color palette. 
/// Use [AppTheme] to apply these to a [ThemeData].
class AppColors {
  const AppColors._();

  // Core Brand Colors
  static const Color brandColor = Color(0xFF293CA0);
  static const Color secondaryBrandColor = Color(0xFF5E69EE);

  // Status/Semantic Colors
  static const Color success = Color(0xFF44A334);
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Connection State Colors
  static const Color connected = Color(0xFF44A334);
  static const Color disconnected = Color(0xFF9EA3B0);
  
  // You might add specific UI element colors here if they differ significantly from the generated scheme
}
