import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile import never logs the private subscription URL', () {
    final source = File('lib/features/profile/notifier/profile_notifier.dart').readAsStringSync();

    expect(source, isNot(contains('url: [\${rs.url}]')));
  });

  test('Riverpod diagnostics never serialize provider values', () {
    final source = File('lib/riverpod_observer.dart').readAsStringSync();

    expect(source, isNot(contains(r': $value')));
    expect(source, isNot(contains(r': $previousValue -> $newValue')));
  });

  test('connection crash reporting never sends the raw core error', () {
    final source = File('lib/features/connection/notifier/connection_notifier.dart').readAsStringSync();
    final captureCall = RegExp(r'Sentry\.capture(?:Exception|Message)\((.*?)\);', dotAll: true).firstMatch(source);

    expect(captureCall, isNotNull);
    expect(captureCall!.group(1), isNot(contains('err.toString()')));
  });

  test('Release profile import has no bundled test subscription endpoint', () {
    final notifier = File('lib/features/profile/notifier/profile_notifier.dart').readAsStringSync();
    final modal = File('lib/features/profile/add/add_profile_modal.dart').readAsStringSync();

    expect(notifier, isNot(contains('test.configs/free_configs')));
    expect(modal, isNot(contains('FreeBtns')));
    expect(modal, isNot(contains('freeSwitchNotifierProvider')));
  });
}
