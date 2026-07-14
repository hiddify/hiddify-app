import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the native service channel compatible with Dart', () {
    final xcconfig = File('ios/Base.xcconfig').readAsStringSync();

    expect(xcconfig, contains('SERVICE_IDENTIFIER=com.hiddify.app'));
  });

  test('does not retain upstream Apple signing teams', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    expect(project, isNot(contains('DEVELOPMENT_TEAM = M7Q8ASP66Z;')));
  });

  test('uses Woman in Red on user-visible native surfaces', () {
    final shortcut = File('android/app/src/main/res/xml/shortcuts.xml').readAsStringSync();
    final notification = File(
      'android/app/src/main/kotlin/com/hiddify/hiddify/bg/ServiceNotification.kt',
    ).readAsStringSync();
    final vpnManager = File('ios/Runner/VPN/VPNManager.swift').readAsStringSync();
    final banner = File('android/app/src/main/res/drawable/ic_banner_foreground.xml').readAsStringSync();

    expect(shortcut, contains('android:targetPackage="com.womaninred"'));
    expect(notification, isNot(contains('"Hiddify"')));
    expect(notification, contains('"Woman in Red"'));
    expect(vpnManager, contains('localizedDescription = "Woman in Red"'));
    expect(banner, contains('@drawable/woman_in_red_banner'));
  });

  test('uses Woman in Red throughout the Flutter shell', () {
    final constants = File('lib/core/model/constants.dart').readAsStringSync();
    final themePreferences = File('lib/core/theme/theme_preferences.dart').readAsStringSync();
    final home = File('lib/features/home/widget/home_page.dart').readAsStringSync();
    final intro = File('lib/features/intro/widget/intro_page.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final translationFiles = Directory(
      'assets/translations',
    ).listSync().whereType<File>().where((file) => file.path.endsWith('.i18n.json'));

    expect(constants, contains('appName = "Woman in Red"'));
    expect(themePreferences, contains('persisted == null) return AppThemeMode.dark'));
    expect(home, isNot(contains('Assets.images.logo.svg')));
    expect(intro, isNot(contains('Assets.images.logo.svg')));
    expect(pubspec, contains('design/assets/woman-in-red-app-icon-master.png'));
    for (final file in translationFiles) {
      final translation = file.readAsStringSync();
      expect(translation, contains('"appTitle": "Woman in Red"'), reason: file.path);
    }
  });

  test('dates the upstream modification notice', () {
    final readme = File('README.md').readAsStringSync();

    expect(readme, contains('Changes from upstream — 2026-07-13'));
  });

  test('requests only the Network Extension capabilities used by the packet tunnel', () {
    final runner = File('ios/Runner/Runner.entitlements').readAsStringSync();
    final tunnel = File('ios/HiddifyPacketTunnel/HiddifyPacketTunnel.entitlements').readAsStringSync();

    for (final entitlements in [runner, tunnel]) {
      expect(entitlements, contains('<string>packet-tunnel-provider</string>'));
      expect(entitlements, isNot(contains('<string>app-proxy-provider</string>')));
      expect(entitlements, isNot(contains('<string>dns-proxy</string>')));
      expect(entitlements, isNot(contains('<string>content-filter-provider</string>')));
    }
    expect(runner, isNot(contains('<key>aps-environment</key>')));
  });

  test('declares non-tracking crash diagnostics in the app privacy manifest', () {
    final manifest = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();

    expect(manifest, contains('<key>NSPrivacyTracking</key>'));
    expect(manifest, contains('<false/>'));
    expect(manifest, contains('NSPrivacyCollectedDataTypeCrashData'));
    expect(manifest, contains('NSPrivacyCollectedDataTypePurposeAppFunctionality'));
  });

  test('copies both app-owned privacy manifests into their target bundles', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final resourceEntries = RegExp(r'PrivacyInfo\.xcprivacy in Resources').allMatches(project);

    expect(resourceEntries.length, 4, reason: 'each manifest needs a PBXBuildFile and resources-phase entry');
  });
}
