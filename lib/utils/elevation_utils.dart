import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hiddify/utils/platform_utils.dart';

/// Utilities for inspecting and elevating the current process privileges.
///
/// On macOS/Linux this means root (uid 0); on Windows this means
/// membership in the Administrators group. VPN/TUN service mode in the
/// underlying core requires these privileges to open the tun device.
abstract class ElevationUtils {
  static bool? _cachedIsElevated;

  /// Whether the current process is running with admin/root privileges.
  ///
  /// Always returns `true` on mobile/web platforms where the concept does
  /// not apply, so guards using this should also check [PlatformUtils.isDesktop].
  static bool get isElevated {
    final cached = _cachedIsElevated;
    if (cached != null) return cached;

    if (kIsWeb || !PlatformUtils.isDesktop) {
      return _cachedIsElevated = true;
    }

    try {
      if (Platform.isWindows) {
        // `net session` requires admin and exits with non-zero otherwise.
        final res = Process.runSync('net', ['session'], runInShell: true);
        return _cachedIsElevated = res.exitCode == 0;
      }
      // macOS & Linux
      final res = Process.runSync('id', ['-u']);
      final stdout = (res.stdout as String?)?.trim() ?? '';
      return _cachedIsElevated = stdout == '0';
    } catch (_) {
      return _cachedIsElevated = false;
    }
  }

  /// Whether the platform supports an interactive privilege-escalation
  /// prompt that we can drive from the GUI.
  static bool get canRelaunchElevated => PlatformUtils.isDesktop && !isElevated;

  /// Attempts to relaunch the application with admin/root privileges.
  ///
  /// Returns `false` if elevation is not supported, the user cancelled the
  /// authentication prompt, or no elevation tool was available. On success
  /// this never returns: the current process exits and the elevated
  /// instance takes over.
  static Future<bool> relaunchElevated() async {
    if (!PlatformUtils.isDesktop) return false;
    final exe = Platform.resolvedExecutable;

    try {
      if (Platform.isMacOS) {
        return await _relaunchMacOS(exe);
      }
      if (Platform.isLinux) {
        return await _relaunchLinux(exe);
      }
      if (Platform.isWindows) {
        return await _relaunchWindows(exe);
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  static Future<bool> _relaunchMacOS(String exe) async {
    // Resolve the .app bundle so we can `open` a brand-new instance.
    final appBundle = _findAppBundle(exe);
    final target = appBundle ?? exe;
    // Escape any double quotes for AppleScript embedding.
    final escaped = target.replaceAll('"', r'\"');
    final newArg = appBundle != null ? '-n -a' : '';
    final shell = appBundle != null
        ? 'open $newArg \\"$escaped\\"'
        : 'open \\"$escaped\\"';
    final script = 'do shell script "$shell" with administrator privileges';

    final result = await Process.run('osascript', ['-e', script]);
    if (result.exitCode != 0) {
      // Non-zero typically means the user dismissed the auth dialog.
      return false;
    }
    exit(0);
  }

  static Future<bool> _relaunchLinux(String exe) async {
    // Try graphical sudo wrappers in order of preference. They all open
    // their own password prompt and detach the elevated child.
    const candidates = <List<String>>[
      ['pkexec'],
      ['gksudo'],
      ['kdesudo'],
      ['gksu'],
    ];
    for (final tool in candidates) {
      try {
        await Process.start(
          tool.first,
          [...tool.skip(1), exe],
          mode: ProcessStartMode.detached,
        );
        // Give the new process a brief moment to spawn before we tear
        // ourselves down.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        exit(0);
      } on ProcessException {
        continue;
      }
    }
    return false;
  }

  static Future<bool> _relaunchWindows(String exe) async {
    // PowerShell's Start-Process -Verb RunAs triggers the standard UAC prompt.
    final cmd = 'Start-Process -Verb RunAs -FilePath "$exe"';
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      cmd,
    ]);
    if (result.exitCode != 0) return false;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    exit(0);
  }

  /// Returns the `.app` bundle path for an executable inside it, or `null`
  /// when running outside of a bundle (e.g. `flutter run`).
  static String? _findAppBundle(String executablePath) {
    final parts = executablePath.split(Platform.pathSeparator);
    for (var i = parts.length - 1; i >= 0; i--) {
      if (parts[i].endsWith('.app')) {
        return parts.sublist(0, i + 1).join(Platform.pathSeparator);
      }
    }
    return null;
  }
}
