// The whole logging pipeline: one stream, several sinks.
//
// Replaces LoggerController. Where loggy accepted a single printer and needed a
// class to fan out to the others, package:logging's root stream takes as many
// listeners as we like, so each destination is just a subscription we can
// attach or cancel.
//
// Sentry is added separately, see sinks/sentry_sink.dart.

import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:hiddify/core/logger/ring/log_ring.dart';
import 'package:hiddify/core/logger/sinks/file_sink.dart';
import 'package:logging/logging.dart';

/// one place that turns a record into one line of text
String formatRecord(LogRecord r) {
  final time = r.time.toIso8601String().split('T')[1];
  return '$time [${r.level.name}] [${r.loggerName}] ${messageOf(r)}';
}

/// The message, with the origin appended when the record carries a stack.
///
/// Kept in the message itself on purpose: DevTools, the logs page and app.log
/// all show the message, so this is the one place that reaches all three.
String messageOf(LogRecord r) {
  final origin = originOf(r.stackTrace);
  return origin == null ? r.message : '${r.message}  <-  $origin';
}

/// the history the logs page reads
final logRing = LogRing(1000);

// ------------------------------------------------------------------- console

/// Nobody listens to dev.log in a release build, so the sink is never even
/// attached there. In debug it is on by default and can be switched off when
/// the logs page alone is enough.
bool _consoleEnabled = !kReleaseMode;

bool get consoleEnabled => _consoleEnabled;

void logSetConsoleEnabled(bool on) {
  if (kReleaseMode) return; // never in release, whatever the caller asks
  if (on == _consoleEnabled) return;
  _consoleEnabled = on;
  if (on) {
    _consoleSub ??= Logger.root.onRecord.listen(_toConsole);
  } else {
    // detach, so an off console costs nothing per record at all
    _consoleSub?.cancel();
    _consoleSub = null;
  }
}

/// records below this never reach DevTools, so a burst cannot drown the view
Level _consoleLevel = Level.INFO;

Level get consoleLevel => _consoleLevel;

void logSetConsoleLevel(Level level) => _consoleLevel = level;

/// DevTools shows time, level and source in its own columns, so the message
/// must stay the bare message — a formatted string would repeat all three.
///
/// `zone` is deliberately not passed. DevTools turns it into a `_RootZone`
/// chip on every single row, and it never carries anything useful.
/// Only frames from our own package are worth reading; the rest is framework
/// and SDK noise. Set this to the app's package prefix.
String ownPackagePrefix = 'package:hiddify/';

/// how many of our own frames to keep
int errorFrames = 4;

/// Turns the first frame from our own code into `Class.method (file.dart:line)`.
///
/// A raw frame looks like:
///   #0      ProfileRepository.save (package:log_bench/data/repo.dart:88:12)
/// and only the method, the file name and the line are worth showing.
String? originOf(StackTrace? stack) {
  if (stack == null) return null;

  for (final frame in stack.toString().split('\n')) {
    if (!frame.contains(ownPackagePrefix)) continue;

    final open = frame.indexOf('(');
    final close = frame.lastIndexOf(')');
    if (open == -1 || close <= open) continue;

    // '#0      ProfileRepository.save ' -> 'ProfileRepository.save'
    final method = frame.substring(0, open).trim().split(RegExp(r'\s+')).last;

    // 'package:log_bench/data/repo.dart:88:12' -> ['...repo.dart', '88', '12']
    final parts = frame.substring(open + 1, close).split(':');
    if (parts.length < 3) continue;
    final file = parts[parts.length - 3].split('/').last;
    final line = parts[parts.length - 2];

    return '$method ($file:$line)';
  }
  return null;
}

/// Keeps only the frames from our own code.
///
/// A raw stack trace is ~20 frames, nearly all of them inside Flutter, and
/// every one of them gets printed. Trimming before dev.log is what keeps the
/// console readable — the surviving frames are still clickable.
StackTrace? _ownFrames(StackTrace? stack) {
  if (stack == null) return null;

  final mine = stack
      .toString()
      .split('\n')
      .where((line) => line.contains(ownPackagePrefix))
      .take(errorFrames)
      .toList();

  if (mine.isEmpty) return null;
  return StackTrace.fromString(mine.join('\n'));
}

void _toConsole(LogRecord r) {
  if (r.level < _consoleLevel) return;
  dev.log(
    messageOf(r),
    time: r.time,
    sequenceNumber: r.sequenceNumber,
    level: r.level.value,
    name: r.loggerName,
    error: r.error,
    stackTrace: _ownFrames(r.stackTrace),
  );
}

// ---------------------------------------------------------------------- file

void _toFile(LogRecord r) => writeLogLine(formatRecord(r));

bool get fileEnabled => _fileSub != null;

/// Detaches or reattaches the file sink without closing the file, so it can be
/// turned back on. Use [logFinish] to close it for good.
void logSetFileEnabled(bool on) {
  if (on) {
    if (_fileSub == null && isLogFileOpen) {
      _fileSub = Logger.root.onRecord.listen(_toFile);
    }
  } else {
    _fileSub?.cancel();
    _fileSub = null;
  }
}

// ---------------------------------------------------------------------- ring

void _toRing(LogRecord r) => logRing.add(r);

// ------------------------------------------------ handles we may cancel later

StreamSubscription<LogRecord>? _consoleSub;
StreamSubscription<LogRecord>? _fileSub;

// -------------------------------------------------------------------- phases

/// phase 1 — before the folders are known
void logStart() {
  // ALL on purpose: this is the only gate before the sinks, and each sink
  // applies its own threshold. Anything dropped here is gone for good.
  Logger.root.level = Level.ALL;
  if (_consoleEnabled) _consoleSub = Logger.root.onRecord.listen(_toConsole);
  // the ring is never detached — it is the history the page reads
  Logger.root.onRecord.listen(_toRing);
}

/// phase 2 — the folders are ready, so the file can be opened
void logAddFile(String path) {
  openLogFile(path);
  // on web the sink never opens, so no listener is attached at all
  if (!isLogFileOpen) return;
  _fileSub = Logger.root.onRecord.listen(_toFile);
}

/// phase 3 — the last word on whether the file stays at all
///
/// The root level is not touched here. It stays ALL so the ring keeps every
/// record; each sink decides for itself what it wants.
void logFinish({required bool keepFile}) {
  if (!keepFile) _dropFile();
}

// ------------------------------------------------- switch things at runtime

void _dropFile() {
  _fileSub?.cancel();
  _fileSub = null;
  closeLogFile();
}
