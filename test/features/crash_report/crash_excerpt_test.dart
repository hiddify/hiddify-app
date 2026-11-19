import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/logger/crash/app_crash_store_io.dart';
import 'package:hiddify/features/crash_report/data/crash_excerpt.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory working;

  setUp(() => working = Directory.systemTemp.createTempSync('crash_excerpt'));
  tearDown(() => working.deleteSync(recursive: true));

  test('a core crash starts at the panic, not at what the core wrote before it', () {
    final report = Directory(p.join(working.path, 'crash_reports', '2026-11-13T19-48-43'))..createSync(recursive: true);
    File(p.join(report.path, 'go.log')).writeAsStringSync(
      'some warning a library printed\n'
      'panic: runtime error: invalid memory address or nil pointer dereference\n'
      '[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x1234]\n\n'
      'goroutine 42 [running]:\n'
      'github.com/sagernet/sing-box/outbound.(*URLTest).loop(...)\n',
    );
    final excerpt = readCrashExcerpt(
      working,
      CrashReport(name: '2026-11-13T19-48-43', source: 'crash_reports', isCrash: true),
    )!;
    expect(excerpt.headline, 'panic: runtime error: invalid memory address or nil pointer dereference');
    expect(excerpt.text, isNot(contains('some warning')));
    expect(excerpt.text, contains('goroutine 42 [running]'));
  });

  test('a long crash is cut to what a link can carry', () {
    File(p.join(working.path, 'stderr.log')).writeAsStringSync('fatal error: concurrent map writes\n${'x' * 9000}\n');
    final excerpt = readCrashExcerpt(working, CrashReport(name: 'stderr.log', source: 'stderr.log'))!;
    expect(excerpt.headline, 'fatal error: concurrent map writes');
    expect(excerpt.text.length, lessThan(3100));
  });

  test('only the app crashes that ended the process are offered', () {
    final directory = Directory(p.join(working.path, appCrashDirectory))..createSync();
    File(p.join(directory.path, '2026-11-13T10-00-00-000-dart.txt')).writeAsStringSync('Flutter error\n');
    File(
      p.join(directory.path, '2026-11-13T11-00-00-000-android.txt'),
    ).writeAsStringSync('Uncaught java.lang.IllegalStateException: boom\n\nthread: main\n');
    File(p.join(directory.path, '2026-11-13T12-00-00-000-native.txt')).writeAsStringSync('Native crash in x\n');

    final reports = appCrashReports(working);
    expect(reports.map((r) => r.name), ['2026-11-13T11-00-00-000-android.txt', '2026-11-13T12-00-00-000-native.txt']);
    expect(reports.first.crashedAt, '2026-11-13T11:00:00Z');
    expect(readCrashExcerpt(working, reports.first)!.headline, 'Uncaught java.lang.IllegalStateException: boom');
    // every one goes in the zip, the dart one too
    expect(appCrashFiles(working), hasLength(3));
  });

  test('records each error once and keeps the newest ten', () {
    openAppCrashStore(working.path);
    recordAppCrash('dart', 'same error');
    recordAppCrash('dart', 'same error');
    expect(appCrashFiles(working), hasLength(1));
    for (var i = 0; i < 15; i++) {
      recordAppCrash('dart', 'error $i');
    }
    expect(appCrashFiles(working), hasLength(10));
    expect(appCrashFiles(working).last.readAsStringSync(), 'error 14');
  });
}
