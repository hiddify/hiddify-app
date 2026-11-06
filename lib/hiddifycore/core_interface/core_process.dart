import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
/// - Windows: `core\Hiddify.exe`, named Hiddify with the core icon
/// - macOS: `Contents/Helpers/Hiddify Core.app`, named Hiddify with the core icon; not an app to
///   macOS, so App Nap does not throttle it while the UI is in the background (hiddify-app#2343)
/// - Linux: `HiddifyCli`, which renames itself `hiddify-core` for htop and top
///
/// The core raises its own priority. It stops, restoring the system proxy, when its stdin closes:
/// this process holds the other end and never writes to it, so it closes when the UI exits, even
/// when the UI crashes or is killed. The core also watches the UI's process id.
class CoreProcess {
  CoreProcess._(this._process, this.serverCertificatePem);

  static const _readyPrefix = 'HIDDIFY_CORE_READY ';
  static const _errorPrefix = 'HIDDIFY_CORE_ERROR ';
  static const _secretEnv = 'HIDDIFY_CORE_SECRET';
  // The setup loads the core's data and can take a while on a slow disk.
  static const _readyTimeout = Duration(seconds: 60);
  // The core stops within 8 s; a little more for the process to exit.
  static const _stopTimeout = Duration(seconds: 10);

  final Process _process;

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
      path = p.join(directory, 'core', 'Hiddify.exe');
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
    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.isNotEmpty) _logger.debug('core: $line');
    }, onError: (Object _) {});
    unawaited(
      process.exitCode.then((code) {
        if (!ready.isCompleted) {
          ready.completeError(CoreProcessException('the core exited ($code) before it was ready'));
        }
      }),
    );

    try {
      final certificate = await ready.future.timeout(_readyTimeout);
      return CoreProcess._(process, certificate.isEmpty ? '' : utf8.decode(base64.decode(certificate)));
    } catch (_) {
      process.kill();
      rethrow;
    }
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
