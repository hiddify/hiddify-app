import 'dart:io';

import 'package:hiddify/core/logger/crash/app_crash_store_io.dart' show appCrashDirectory;
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:path/path.dart' as p;

/// What crashed, short enough for an issue link or a mail body: [headline] is the exception's own
/// line, [text] the lines that follow it.
typedef CrashExcerpt = ({String headline, String text});

/// The kinds of app crash that ended the process (app_crash_store_io.dart, AppCrashRecorder.kt);
/// a `dart` one is an error the app went on after, so it is sent along but offers no report.
const fatalAppCrashKinds = {'android', 'native', 'anr'};

/// Of a GitHub link's 8 KB, what is left for the crash once the rest is in.
const _maxText = 3000;
const _maxLines = 60;

/// Where a Go crash begins in what the core wrote to stderr (hcore/diagnostics.go crashMarker).
final _goCrash = RegExp(r'^(panic: |fatal error: |runtime: |SIG[A-Z]+: |\[signal )', multiLine: true);

/// The app's crash files, oldest first.
List<File> appCrashFiles(Directory workingDir) {
  final directory = Directory(p.join(workingDir.path, appCrashDirectory));
  if (!directory.existsSync()) return [];
  return directory.listSync().whereType<File>().where((f) => f.path.endsWith('.txt')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// The app's crashes that ended the process, as the core lists its own, so the dialog offers both.
List<CrashReport> appCrashReports(Directory workingDir) => [
  for (final file in appCrashFiles(workingDir))
    if (_kind(file) case final kind when fatalAppCrashKinds.contains(kind))
      CrashReport(name: p.basename(file.path), source: appCrashDirectory, isCrash: true, crashedAt: _time(file)),
];

/// What [report] says crashed, or null when its files are gone or say nothing.
CrashExcerpt? readCrashExcerpt(Directory workingDir, CrashReport report) {
  try {
    final String content;
    switch (report.source) {
      case appCrashDirectory:
        content = File(p.join(workingDir.path, appCrashDirectory, report.name)).readAsStringSync();
        return _excerpt(content, 0);
      case 'oom_reports':
        return (
          headline: 'The core ran out of memory',
          text: 'The core ran out of memory (oom_reports/${report.name}).',
        );
      case 'crash_reports':
        content = File(p.join(workingDir.path, 'crash_reports', report.name, 'go.log')).readAsStringSync();
      default:
        // a live stderr file the core has not archived yet
        content = File(p.join(workingDir.path, report.name)).readAsStringSync();
    }
    final start = _goCrash.firstMatch(content)?.start ?? 0;
    return _excerpt(content, start);
  } catch (_) {
    return null;
  }
}

CrashExcerpt? _excerpt(String content, int start) {
  final lines = content.substring(start).split('\n');
  final headline = lines.firstWhere((line) => line.trim().isNotEmpty, orElse: () => '').trim();
  if (headline.isEmpty) return null;
  var text = lines.take(_maxLines).join('\n').trimRight();
  if (text.length > _maxText) text = '${text.substring(0, _maxText)}\n…';
  return (headline: headline.length > 200 ? '${headline.substring(0, 200)}…' : headline, text: text);
}

/// `2026-11-13T19-48-43[-2]-android.txt` → `android`.
String _kind(File file) {
  final name = p.basenameWithoutExtension(file.path);
  return name.substring(name.lastIndexOf('-') + 1);
}

/// The file name's time, as the core gives a report's: RFC 3339 in UTC.
String _time(File file) {
  final name = p.basename(file.path);
  if (name.length < 19) return '';
  final stamp = name.substring(0, 19);
  return '${stamp.substring(0, 10)}T${stamp.substring(11).replaceAll('-', ':')}Z';
}
