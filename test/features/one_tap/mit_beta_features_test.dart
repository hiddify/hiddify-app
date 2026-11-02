import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/one_tap/mit_profile_names.dart';
import 'package:hiddify/features/one_tap/mit_profile_import_dialog.dart';
import 'package:hiddify/features/one_tap/mit_qr_scanner.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/awg_fixture.dart';

void main() {
  test('aliases persist independently of profile credentials and can be cleared', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final names = MitProfileNames(prefs);
    await names.rename('synthetic-id', '  Дом  ');
    expect(MitProfileNames(prefs).state, {'synthetic-id': 'Дом'});
    expect(jsonDecode(prefs.getString(mitProfileNamesKey)!), {'synthetic-id': 'Дом'});
    await expectLater(names.rename('synthetic-id', 'bad\nname'), throwsFormatException);
    expect(names.state, {'synthetic-id': 'Дом'});
    await expectLater(names.rename('synthetic-id', 'x' * 61), throwsFormatException);
    await names.rename('synthetic-id', ' ');
    expect(names.state, isEmpty);
  });

  test('corrupt alias storage does not prevent loading profiles', () async {
    SharedPreferences.setMockInitialValues({mitProfileNamesKey: 'not json'});
    final prefs = await SharedPreferences.getInstance();
    expect(MitProfileNames(prefs).state, isEmpty);
    await prefs.setString(mitProfileNamesKey, jsonEncode({'a': 5, 'b': 'ok', 'c': 'bad\u0000'}));
    expect(MitProfileNames(prefs).state, {'b': 'ok'});
    await expectLater(MitProfileNames(null).rename('id', 'name'), throwsFormatException);
  });

  test('backup movement preserves IDs and bounds without mutating source', () {
    final ids = ['a', 'b', 'c'];
    expect(moveMitBackup(ids, 'c', -1), ['a', 'c', 'b']);
    expect(moveMitBackup(ids, 'a', 1), ['b', 'a', 'c']);
    for (final direction in [-1, 0, 2]) {
      expect(moveMitBackup(ids, 'a', direction), ids);
    }
    expect(moveMitBackup(ids, 'missing', 1), ids);
    expect(moveMitBackup(ids, 'c', 1), ids);
    expect(ids, ['a', 'b', 'c']);
  });

  test('QR accepts a supported synthetic client profile and rejects arbitrary content', () {
    expect(isMitProfileQr(awgTestConfig()), true);
    expect(isMitProfileQr('https://example.com/login'), false);
    expect(isMitProfileQr('not a profile'), false);
    expect(isMitProfileQr('vpn://invalid'), false);
  });

  testWidgets('QR is requested only on tap and requires explicit Add', (tester) async {
    var scans = 0;
    String? imported;
    await tester.pumpWidget(ProviderScope(overrides: [
      mitQrLoaderProvider.overrideWithValue((_) async { scans++; return awgTestConfig(); }),
    ], child: MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () async => imported = await showDialog<String>(context: context,
        builder: (_) => const MitProfileImportDialog()), child: const Text('open')))))));
    await tester.tap(find.text('open')); await tester.pumpAndSettle();
    expect(scans, 0);
    await tester.tap(find.byKey(const ValueKey('mit-scan-profile'))); await tester.pumpAndSettle();
    expect(scans, 1); expect(imported, isNull);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('mit-profile-input'))).obscureText, true);
    await tester.tap(find.text('Добавить')); await tester.pumpAndSettle();
    expect(imported, awgTestConfig());
  });
}
