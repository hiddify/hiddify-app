import 'package:flutter/material.dart';

/// A section header widget for settings pages.
/// 
/// Displays a title with theme-appropriate styling to group related settings.
/// 
/// Usage:
/// ```dart
/// SettingsSection('General')
/// ```
class SettingsSection extends StatelessWidget {
  /// Creates a settings section header.
  const SettingsSection(
    this.title, {
    super.key,
    this.padding,
  });

  /// The section title text.
  final String title;
  
  /// Optional custom padding.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: ListTile(
        title: Text(title),
        titleTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        dense: true,
        contentPadding: padding,
      ),
    );
  }
}

/// A divider widget for separating settings groups.
/// 
/// Displays a horizontal line with consistent indentation.
class SettingsDivider extends StatelessWidget {
  /// Creates a settings divider.
  const SettingsDivider({
    super.key,
    this.indent = 16,
    this.endIndent = 16,
  });

  /// Leading indentation.
  final double indent;
  
  /// Trailing indentation.
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(indent: indent, endIndent: endIndent);
  }
}
