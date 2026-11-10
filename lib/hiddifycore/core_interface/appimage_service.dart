import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:hiddify/hiddifycore/core_interface/admin_permission_refused.dart';
import 'package:hiddify/utils/custom_loggers.dart';

final _logger = infraLogger('AppImageService');

/// The VPN service of the AppImage. An AppImage cannot install the system service: its files live
/// in the user's FUSE mount, which root cannot read. So the app starts the same AppImage as root,
/// through pkexec, as `HiddifyCli core-service` (hiddify-core cmd/cmd_core_service.go): root mounts
/// the image itself, and the service's API runs in the foreground for as long as this app runs.
/// The app connects to it as to the installed service.
///
/// pkexec clears the environment, so the control secret goes on the first stdin line. Stdin then
/// stays open: it closes when the app exits, even when it is killed, and the service stops its
/// engine (TUN, routes) and exits.
class AppImageService {
  AppImageService._(this._process, this.secret);

  static const port = 18021;
  static const _readyLine = 'HIDDIFY_SERVICE_READY';
  static const _errorPrefix = 'HIDDIFY_CORE_ERROR ';
  // pkexec waits while the user types the password
  static const _readyTimeout = Duration(minutes: 5);
  static const _stopTimeout = Duration(seconds: 10);

  final Process _process;
  final String secret;
  bool _exited = false;

  bool get running => !_exited;

  static String _newSecret() {
    const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(64, (_) => characters[random.nextInt(characters.length)]).join();
  }

  /// Asks for administrator rights (pkexec) and starts the service; returns once it serves.
  static Future<AppImageService> start(String appImage, int ownerPid) async {
    final process = await Process.start('pkexec', [
      appImage,
      'HiddifyCli',
      'core-service',
      '--listen',
      '127.0.0.1:$port',
      '--owner-pid',
      '$ownerPid',
    ]);
    final service = AppImageService._(process, _newSecret());
    process.stdin.writeln(service.secret);
    await process.stdin.flush();

    final ready = Completer<void>();
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (!ready.isCompleted && line.trim() == _readyLine) {
        ready.complete();
      } else if (!ready.isCompleted && line.startsWith(_errorPrefix)) {
        ready.completeError(StateError(line.substring(_errorPrefix.length)));
      } else if (line.isNotEmpty) {
        _logger.debug('service: $line');
      }
    }, onError: (Object _) {});
    final stderr = StringBuffer();
    process.stderr.transform(utf8.decoder).listen(stderr.write, onError: (Object _) {});
    unawaited(
      process.exitCode.then((code) {
        service._exited = true;
        if (ready.isCompleted) {
          _logger.warning('the AppImage VPN service exited ($code)');
          return;
        }
        // pkexec: 126 when the user dismissed the prompt, 127 both when authorization failed and when
        // the program could not run (hiddify-app#2461); only its stderr tells the two apart
        final detail = stderr.toString().trim();
        ready.completeError(
          code == 126 || (code == 127 && detail.isEmpty)
              ? const AdminPermissionRefused()
              : StateError('The VPN service did not start ($code): $detail'),
        );
      }),
    );
    try {
      await ready.future.timeout(_readyTimeout);
    } catch (_) {
      process.kill();
      rethrow;
    }
    _logger.info('AppImage VPN service ${process.pid} started');
    return service;
  }

  /// Stops the service: its engine restores what it changed, then it exits.
  Future<void> stop() async {
    if (_exited) return;
    try {
      await _process.stdin.close();
    } catch (_) {
      // already gone
    }
    try {
      await _process.exitCode.timeout(_stopTimeout);
    } on TimeoutException {
      // pkexec runs the service as root: this process cannot signal it, only pkexec
      _process.kill();
    }
  }
}
