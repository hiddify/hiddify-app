import 'dart:io';

import 'package:dartx/dartx.dart';
import 'package:flutter/foundation.dart';

enum Environment {
  prod,
  dev;

  static const sentryDSN = String.fromEnvironment("sentry_dsn");
  // This environment variable is set in the 'windows-release-zip' command
  static const isPortable = bool.fromEnvironment("portable");
}

enum Release {
  general("general"),
  // This environment variable is set in the 'android-release-aab' command
  googlePlay("google-play"),
  // The App Store: the Mac App Store build sets it (macos/scripts/dist.sh app-store); every iOS
  // build is taken as one (read)
  appStore("app-store"),
  // The Microsoft Store: an MSIX package (read)
  microsoftStore("microsoft-store");

  const Release(this.key);

  final String key;

  /// The app finds and installs its own updates only outside a store: a store updates its apps
  /// itself, and does not allow an app to offer another way.
  bool get allowCustomUpdateChecker => this == general;

  /// The release of this build: what it was built as, else what it runs as. An iOS app is updated
  /// by the store that installed it (or the way it was sideloaded), never by the app; an MSIX
  /// package runs from WindowsApps and is updated by the Microsoft Store.
  static Release read() {
    const defined = String.fromEnvironment("release");
    if (Release.values.firstOrNullWhere((e) => e.key == defined) case final release?) return release;
    if (kIsWeb) return general;
    if (Platform.isIOS) return appStore;
    if (Platform.isWindows && isMsix(Platform.resolvedExecutable)) return microsoftStore;
    return general;
  }

  /// Whether [executable] runs from an MSIX package, which Windows installs under WindowsApps.
  @visibleForTesting
  static bool isMsix(String executable) => executable.toLowerCase().contains(r'\windowsapps\');
}
