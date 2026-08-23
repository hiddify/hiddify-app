import 'dart:io';

IOSink? _sink;

void openLogFile(String path) {
  _sink = File(path).openWrite();
}

void writeLogLine(String line) => _sink?.writeln(line);

bool get isLogFileOpen => _sink != null;

Future<void> closeLogFile() async {
  final sink = _sink;
  _sink = null;
  await sink?.flush();
  await sink?.close();
}

Future<void> flushLogFile() async => _sink?.flush();
