import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/proxy/widget/upload_speed.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  Future<List<String>> tap(WidgetTester tester, {required int upload, required int download}) async {
    final tested = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [translationsProvider.overrideWith((ref) => AppLocale.en.buildSync())],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: UploadSpeedChip(
                speed: upload,
                testing: false,
                downloadSpeed: download,
                onTest: () => tested.add('upload'),
                onDownloadTest: () => tested.add('download'),
                dense: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(UploadSpeedChip));
    await tester.pump();
    return tested;
  }

  testWidgets('with both speeds shown, a tap tests both', (tester) async {
    expect(await tap(tester, upload: 6625000, download: 10750000), ['download', 'upload']);
  });

  testWidgets('with the upload alone, a tap tests the upload', (tester) async {
    expect(await tap(tester, upload: 6625000, download: 0), ['upload']);
  });
}
