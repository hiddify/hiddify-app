import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/logger/sinks/file_sink_io.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hiddify_log_sink');
    file = File('${dir.path}/app.log');
  });

  tearDown(() async {
    await closeLogFile();
    await dir.delete(recursive: true);
  });

  test('a line is on disk before anything else runs', () {
    openLogFile(file.path);
    writeLogLine('SEVERE something broke');

    // No flush, no await: the point of the file is to survive a crash that
    // happens on the very next line.
    expect(file.readAsStringSync(), 'SEVERE something broke\n');
  });

  test('a second run appends rather than starting over', () async {
    openLogFile(file.path);
    writeLogLine('first run');
    await closeLogFile();

    openLogFile(file.path);
    writeLogLine('second run');

    expect(file.readAsStringSync(), 'first run\nsecond run\n');
  });

  test('a missing folder is created rather than refused', () {
    openLogFile('${dir.path}/nested/deeper/app.log');
    writeLogLine('made it');

    expect(File('${dir.path}/nested/deeper/app.log').readAsStringSync(), 'made it\n');
  });

  test('an unwritable path leaves the sink closed instead of throwing', () {
    // A file where a folder should be: the only way to make a path unusable
    // that behaves the same on Windows and POSIX.
    final blocker = File('${dir.path}/blocker')..writeAsStringSync('x');

    expect(() => openLogFile('${blocker.path}/app.log'), returnsNormally);
    expect(isLogFileOpen, isFalse);
    expect(() => writeLogLine('dropped'), returnsNormally);
  });

  test('writing before opening does nothing', () {
    writeLogLine('dropped');
    expect(file.existsSync(), isFalse);
  });
}
