import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Why a core process ended on Windows when it left no Go crash output: a native crash (in a DLL
/// such as cronet or wintun, on a thread of its own, which Go's handler does not see) or another
/// program ending it. Windows records a native crash as an "Application Error" event (1000) with
/// the faulting module, the exception code and the process id; the exit code alone names what
/// ended it. Before, the app said only "exit code -1073741819" (hiddify-app#2517).
class WindowsCrash {
  WindowsCrash._();

  /// The reason for process [pid] that ended with [exitCode]: the Application Error event of that
  /// process when Windows recorded one, else what the exit code means, or null.
  static Future<String?> reason(int pid, int exitCode) async {
    // Windows writes the event a moment after the process is gone
    for (var attempt = 0; attempt < 4; attempt++) {
      final event = await _applicationErrorOf(pid);
      if (event != null) return event;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return describeExitCode(exitCode);
  }

  static Future<String?> _applicationErrorOf(int pid) async {
    try {
      final result = await Process.run('wevtutil', [
        'qe',
        'Application',
        '/q:*[System[Provider[@Name="Application Error"] and EventID=1000 and TimeCreated[timediff(@SystemTime) <= 120000]]]',
        '/f:xml',
        '/rd:true',
        '/c:10',
      ]).timeout(const Duration(seconds: 5));
      if (result.exitCode != 0) return null;
      return applicationErrorFor(result.stdout as String, pid);
    } catch (_) {
      return null;
    }
  }

  /// The crash of process [pid] in the Application Error events in [xml] (wevtutil's /f:xml), or
  /// null. The event's data is read by position, which does not depend on the system's language:
  /// application, its version and time stamp, the faulting module, its version and time stamp,
  /// the exception code, the fault offset, the process id (hex).
  @visibleForTesting
  static String? applicationErrorFor(String xml, int pid) {
    for (final event in RegExp('<Event[ >].*?</Event>', dotAll: true).allMatches(xml)) {
      final data = RegExp(
        r'<Data(?:\s[^>]*)?>(.*?)</Data>',
        dotAll: true,
      ).allMatches(event.group(0)!).map((match) => match.group(1)!.trim()).toList();
      if (data.length < 9) continue;
      final eventPid = int.tryParse(data[8].replaceFirst(RegExp('^0[xX]'), ''), radix: 16);
      if (eventPid != pid) continue;
      final code = int.tryParse(data[6].replaceFirst(RegExp('^0[xX]'), ''), radix: 16);
      final name = code == null ? null : _ntStatusNames[code];
      final codeText = code == null ? data[6] : '0x${code.toRadixString(16).padLeft(8, '0')}';
      return 'a native crash in ${data[3]} (exception $codeText${name == null ? '' : ', $name'} at offset ${data[7]})';
    }
    return null;
  }

  /// What a Windows exit code says ended the process, or null for an ordinary code.
  @visibleForTesting
  static String? describeExitCode(int exitCode) {
    final code = exitCode & 0xFFFFFFFF;
    final name = _ntStatusNames[code];
    if (name != null) return 'ended by Windows: $name (0x${code.toRadixString(16)})';
    if (code == 1) return 'ended with exit code 1: an error, or another program (Task Manager, an antivirus) ended it';
    return null;
  }

  static const _ntStatusNames = {
    0xC0000005: 'access violation',
    0xC0000409: 'a fail-fast exit or a stack buffer overrun',
    0xC00000FD: 'stack overflow',
    0xC0000374: 'heap corruption',
    0xC0000017: 'out of memory',
    0xC000009A: 'out of system resources',
    0xC0000135: 'a DLL it needs was not found',
    0xC0000142: 'a DLL failed to initialize',
    0xC000001D: 'an illegal instruction',
    0xC0000094: 'an integer division by zero',
    0xC000013A: 'ended with Ctrl+C or its console closing',
    0x40010004: 'ended by a debugger or with the system shutting down',
    0xE06D7363: 'an unhandled C++ exception',
  };
}
