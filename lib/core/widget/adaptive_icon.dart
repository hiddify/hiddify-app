import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class AdaptiveIcon {
  AdaptiveIcon(BuildContext context) : platform = Theme.of(context).platform;

  final TargetPlatform platform;

  IconData get more => switch (platform) {
        TargetPlatform.iOS ||
        TargetPlatform.macOS =>
          FluentIcons.more_horizontal_24_regular,
        _ => FluentIcons.more_vertical_24_regular,
      };

  IconData get share => switch (platform) {
        TargetPlatform.android => FluentIcons.share_android_24_regular,
        TargetPlatform.iOS ||
        TargetPlatform.macOS =>
          FluentIcons.share_ios_24_regular,
        _ => FluentIcons.share_24_regular,
      };
}
