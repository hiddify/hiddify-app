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
  return '$time [${r.level.name}] [${r.loggerName}] ${r.message}';
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
void _toConsole(LogRecord r) {
  if (r.level < _consoleLevel) return;
  dev.log(
    r.message,
    time: r.time,
    sequenceNumber: r.sequenceNumber,
    level: r.level.value,
    name: r.loggerName,
    error: r.error,
    stackTrace: r.stackTrace,
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
