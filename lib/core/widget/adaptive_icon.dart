import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

/// Provides platform-adaptive icons following platform design guidelines.
/// 
/// iOS/macOS use horizontal more icon and iOS share icon.
/// Android uses vertical more icon and Android share icon.
/// Other platforms use generic variants.
/// 
/// Usage:
/// ```dart
/// final icons = AdaptiveIcon(context);
/// IconButton(icon: Icon(icons.more), onPressed: () {});
/// ```
class AdaptiveIcon {
  /// Creates an adaptive icon provider based on the current platform.
  AdaptiveIcon(BuildContext context) : platform = Theme.of(context).platform;

  /// The target platform for icon selection.
  final TargetPlatform platform;

  /// Returns the appropriate "more" menu icon for the platform.
  /// - iOS/macOS: Horizontal dots
  /// - Others: Vertical dots
  IconData get more => switch (platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => 
      FluentIcons.more_horizontal_24_regular,
    _ => FluentIcons.more_vertical_24_regular,
  };

  /// Returns the appropriate share icon for the platform.
  /// - Android: Android-style share icon
  /// - iOS/macOS: iOS-style share icon (box with arrow)
  /// - Others: Generic share icon
  IconData get share => switch (platform) {
    TargetPlatform.android => FluentIcons.share_android_24_regular,
    TargetPlatform.iOS || TargetPlatform.macOS => 
      FluentIcons.share_ios_24_regular,
    _ => FluentIcons.share_24_regular,
  };
}
