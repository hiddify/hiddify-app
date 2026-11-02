import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/one_tap/mit_updates.dart';
import 'package:hiddify/features/one_tap/mit_updates_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final update = MitUpdateCandidate(version: '1.6.0-beta', build: 50006, notes: 'Изменения тестовой версии',
  apk: mitReleaseAsset('mit-beta-1.6.0', 'mits-vpn.apk'), sha256: 'a' * 64, size: 3);

class _Service extends MitUpdateService {
  _Service() : super(Dio());
  int checks = 0, downloads = 0;
  @override
  Future<MitUpdateCandidate?> check(CancelToken token) async { checks++; return update; }
  @override
  Future<void> download(MitUpdateCandidate candidate, Directory directory, CancelToken token,
      void Function(int, int) progress) async { downloads++; progress(3, 3); }
}
class _Platform extends MitUpdatePlatform {
  bool reject = false;
  int verifies = 0, installs = 0, permissions = 0;
  @override
  Future<Directory> directory() async => Directory('/synthetic-unused-cache');
  @override
  Future<void> verify(MitUpdateCandidate candidate) async {
    verifies++;
    if (reject) throw StateError('private/cache/path/signature');
  }
  @override
  Future<String> install(MitUpdateCandidate candidate) async { installs++; return 'permission_required'; }
  @override
  Future<void> openPermission() async { permissions++; }
}

void main() {
  Future<void> open(WidgetTester tester, _Service service, _Platform platform) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      mitUpdateServiceProvider.overrideWithValue(service), mitUpdatePlatformProvider.overrideWithValue(platform),
    ], child: const MaterialApp(home: MitUpdatesPage())));
    await tester.pumpAndSettle();
  }
  testWidgets('manual checking, download, verification and installation are separate user actions', (tester) async {
    final service = _Service(); final platform = _Platform();
    await open(tester, service, platform);
    expect(service.checks, 0); expect(platform.installs, 0);
    await tester.tap(find.text('Проверить обновления')); await tester.pumpAndSettle();
    expect(service.checks, 1); expect(service.downloads, 0);
    expect(find.text('Изменения тестовой версии'), findsOneWidget);
    await tester.tap(find.text('Скачать обновление')); await tester.pumpAndSettle();
    expect(platform.verifies, 1); expect(platform.installs, 0);
    await tester.tap(find.text('Установить')); await tester.pumpAndSettle();
    expect(platform.installs, 1); expect(platform.permissions, 0);
    await tester.ensureVisible(find.text('Разрешить обновления в Android'));
    await tester.tap(find.text('Разрешить обновления в Android')); await tester.pumpAndSettle();
    expect(platform.permissions, 1);
  });
  testWidgets('verification failure blocks installation without exposing exception details', (tester) async {
    final service = _Service(); final platform = _Platform()..reject = true;
    await open(tester, service, platform);
    await tester.tap(find.text('Проверить обновления')); await tester.pumpAndSettle();
    await tester.tap(find.text('Скачать обновление')); await tester.pumpAndSettle();
    expect(find.text('Установить'), findsNothing);
    expect(find.textContaining('Установка заблокирована.'), findsOneWidget);
    expect(find.textContaining('private/cache'), findsNothing);
    expect(platform.installs, 0); expect(platform.permissions, 0);
  });
}
