import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:path/path.dart' as p;

final _logger = infraLogger('CoreProcess');

/// Why the core's process could not start: its own error, or that it exited first.
class CoreProcessException implements Exception {
  const CoreProcessException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The desktop core in a process of its own, instead of the library loaded into the UI process.
///
/// It runs `<launcher> core …` (hiddify-core cmd/cmd_core.go):
/// - Windows: `HiddifyCoreEngine.exe`, shown as Hiddify Core Engine with the core icon
/// - macOS: `Contents/Helpers/Hiddify Core.app`, named Hiddify with the core icon; not an app to
///   macOS, so App Nap does not throttle it while the UI is in the background (hiddify-app#2343)
/// - Linux: `HiddifyCli`, which renames itself `hiddify-core` for htop and top
///
/// The core raises its own priority. It stops, restoring the system proxy, when its stdin closes:
/// this process holds the other end and never writes to it, so it closes when the UI exits, even
/// when the UI crashes or is killed. The core also watches the UI's process id.
class CoreProcess {
  CoreProcess._(this._process, this.serverCertificatePem, this._crashFile, this._stderrTail);

  static const _readyPrefix = 'HIDDIFY_CORE_READY ';
  static const _errorPrefix = 'HIDDIFY_CORE_ERROR ';
  static const _secretEnv = 'HIDDIFY_CORE_SECRET';
  // The setup loads the core's data and can take a while on a slow disk.
  static const _readyTimeout = Duration(seconds: 60);
  // The core stops within 8 s; a little more for the process to exit.
  static const _stopTimeout = Duration(seconds: 10);

  final Process _process;

  /// Where the core writes a Go crash (hcore.Setup: `<working dir>/data/stderr<mode name>.log`). Once it
  /// is set up its stderr goes to /dev/null or NUL, so this file is the only place a panic shows.
  final File _crashFile;

  /// The last lines of stderr, written before the core was set up.
  final List<String> _stderrTail;

  /// The gRPC server certificate (PEM), empty without TLS.
  final String serverCertificatePem;

  bool _stopping = false;

  int get processId => _process.pid;

  /// Completes with the exit code. [stop] completes it as well.
  Future<int> get exitCode => _process.exitCode;

  /// Whether the exit was asked for by [stop].
  bool get stopping => _stopping;

  /// The launcher of this build, or null when it has none (tests, or a core built before it).
  static String? executablePath() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
    final directory = p.dirname(Platform.resolvedExecutable);
    final String path;
    if (Platform.isWindows) {
      path = p.join(directory, 'HiddifyCoreEngine.exe');
    } else if (Platform.isMacOS) {
      path = p.normalize(p.join(directory, '..', 'Helpers', 'Hiddify Core.app', 'Contents', 'MacOS', 'Hiddify'));
    } else if (Platform.isLinux) {
      path = p.join(directory, 'HiddifyCli');
    } else {
      return null;
    }
    return File(path).existsSync() ? path : null;
  }

  /// Starts the core and waits until its gRPC server listens.
  static Future<CoreProcess> start({
    required String executable,
    required String baseDir,
    required String workingDir,
    required String tempDir,
    required String listen,
    required int mode,
    required String secret,
    required bool debug,
  }) async {
    final process = await Process.start(
      executable,
      [
        'core',
        '--base-dir',
        baseDir,
        '--working-dir',
        workingDir,
        '--temp-dir',
        tempDir,
        '--listen',
        listen,
        '--mode',
        '$mode',
        '--owner-pid',
        '$pid',
        if (debug) '--debug',
      ],
      // the secret stays out of the process list
      environment: {_secretEnv: secret},
      // Linux's HiddifyCli links its library as ./lib/hiddify-core.so, relative to the working
      // directory; the core changes it to its own folder once set up.
      workingDirectory: p.dirname(executable),
    );
    _logger.info('core process ${process.pid} started: $executable');

    // named by the mode's name, as Go prints the enum
    final crashFile = File(p.join(workingDir, 'data', 'stderr${SetupMode.valueOf(mode)?.name ?? mode}.log'));
    final stderrTail = <String>[];
    final ready = Completer<String>();
    // Both pipes are read to the end: a full pipe would block the core.
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (!ready.isCompleted && line.startsWith(_readyPrefix)) {
        ready.complete(line.substring(_readyPrefix.length).trim());
      } else if (!ready.isCompleted && line.startsWith(_errorPrefix)) {
        ready.completeError(CoreProcessException(line.substring(_errorPrefix.length)));
      } else if (line.isNotEmpty) {
        _logger.debug('core: $line');
      }
    }, onError: (Object _) {});
    final stderrDone = Completer<void>();
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.isEmpty) return;
            _logger.debug('core: $line');
            stderrTail.add(line);
            if (stderrTail.length > _stderrTailLines) stderrTail.removeAt(0);
          },
          onError: (Object _) {},
          onDone: stderrDone.complete,
        );
    unawaited(
      process.exitCode.then((code) async {
        if (ready.isCompleted) return;
        // the rest of stderr, which holds a crash, arrives after the exit
        await stderrDone.future.timeout(const Duration(seconds: 1), onTimeout: () {});
        final reason = await _crashReason(crashFile, stderrTail);
        if (ready.isCompleted) return;
        ready.completeError(
          CoreProcessException('the core exited ($code) before it was ready${reason == null ? '' : ': $reason'}'),
        );
      }),
    );

    try {
      final certificate = await ready.future.timeout(_readyTimeout);
      return CoreProcess._(
        process,
        certificate.isEmpty ? '' : utf8.decode(base64.decode(certificate)),
        crashFile,
        stderrTail,
      );
    } catch (_) {
      process.kill();
      rethrow;
    }
  }

  static const _stderrTailLines = 50;
  static const _maxReasonLength = 300;

  /// Why the core crashed, from its Go crash output: the `panic:` or `fatal error:` line, or null.
  /// Read it right after the exit: a restarted core moves the file into its crash reports.
  Future<String?> crashReason() => _crashReason(_crashFile, _stderrTail);

  static Future<String?> _crashReason(File crashFile, List<String> stderrTail) async {
    String? fromFile;
    try {
      if (await crashFile.exists()) fromFile = crashHeadline(await crashFile.readAsString());
    } catch (e) {
      _logger.debug('cannot read the core crash output: $e');
    }
    return fromFile ?? crashHeadline(stderrTail.join('\n'));
  }

  /// The line of a Go crash output that says what went wrong, shortened, or null when [output]
  /// holds no crash.
  static String? crashHeadline(String output) {
    final lines = const LineSplitter().convert(output).map((line) => line.trim()).toList();
    final line =
        lines.where((line) => line.startsWith('panic: ') || line.startsWith('fatal error: ')).firstOrNull ??
        lines.where((line) => RegExp('^SIG[A-Z]+: ').hasMatch(line)).firstOrNull;
    if (line == null) return null;
    return line.length > _maxReasonLength ? '${line.substring(0, _maxReasonLength)}…' : line;
  }

  /// Stops the core gracefully, so it can restore the system proxy, and kills it if it does not exit.
  Future<void> stop() async {
    if (_stopping) {
      await exitCode;
      return;
    }
    _stopping = true;
    try {
      await _process.stdin.close();
    } catch (_) {
      // already gone
    }
    try {
      await exitCode.timeout(_stopTimeout);
    } on TimeoutException {
      _logger.warning('core process $processId did not stop in time, killing it');
      _process.kill(ProcessSignal.sigkill);
      await exitCode;
    }
  }
}
