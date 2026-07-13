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

  test('dates the upstream modification notice', () {
    final readme = File('README.md').readAsStringSync();

    expect(readme, contains('Changes from upstream — 2026-07-13'));
  });
}
