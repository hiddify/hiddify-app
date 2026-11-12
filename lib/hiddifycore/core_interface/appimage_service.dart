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

  /// Asks for administrator rights (pkexec, or sudo with a password dialog where pkexec is missing) and
  /// starts the service; returns once it serves.
  static Future<AppImageService> start(String appImage, int ownerPid) async {
    final args = [appImage, 'HiddifyCli', 'core-service', '--listen', '127.0.0.1:$port', '--owner-pid', '$ownerPid'];
    final Process process;
    var viaSudo = false;
    Directory? askpassDir;
    if (_which('pkexec') != null) {
      process = await Process.start('pkexec', args);
    } else {
      if (_which('sudo') == null) throw VpnServiceFailure.noAdminPrompt;
      viaSudo = true;
      final askpass = _sudoAskpass();
      if (askpass == null) {
        // no dialog to type the password into: only works when sudo needs none
        process = await Process.start('sudo', ['-n', ...args]);
      } else {
        askpassDir = askpass.ownDir;
        process = await Process.start('sudo', ['-A', ...args], environment: {'SUDO_ASKPASS': askpass.path});
      }
    }
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
        final refused = viaSudo
            ? code == 1 && _sudoRefusals.any(detail.contains)
            : code == 126 || (code == 127 && detail.isEmpty);
        ready.completeError(
          viaSudo && detail.contains('a password is required')
              ? VpnServiceFailure.noAdminPrompt
              : refused
              ? const AdminPermissionRefused()
              : VpnServiceFailure('The VPN service did not start ($code): $detail'),
        );
      }),
    );
    try {
      await ready.future.timeout(_readyTimeout);
    } catch (_) {
      process.kill();
      rethrow;
    } finally {
      // the dialog has been answered: the script is not needed any more
      try {
        askpassDir?.deleteSync(recursive: true);
      } catch (_) {}
    }
    _logger.info('AppImage VPN service ${process.pid} started');
    return service;
  }

  // sudo exits 1 both when the dialog was cancelled or the password was wrong, and when the program failed
  static const _sudoRefusals = ['no password was provided', 'incorrect password'];

  // Password dialogs that print the password, as sudo -A wants (hiddify-core admin_bgservice_elevate_linux.go)
  static const _askpassDialogs = [
    ('zenity', '--password --title="Hiddify: administrator password for VPN mode"'),
    ('kdialog', '--title=Hiddify --password="Administrator password for VPN mode"'),
    ('qarma', '--password --title="Hiddify: administrator password for VPN mode"'),
    ('ksshaskpass', r'"$@"'),
    ('lxqt-openssh-askpass', r'"$@"'),
    ('ssh-askpass', r'"$@"'),
    ('/usr/libexec/openssh/gnome-ssh-askpass', r'"$@"'),
    ('/usr/lib/openssh/gnome-ssh-askpass', r'"$@"'),
    ('/usr/lib/ssh/x11-ssh-askpass', r'"$@"'),
  ];

  static String? _which(String program) {
    if (program.startsWith('/')) return File(program).existsSync() ? program : null;
    for (final dir in (Platform.environment['PATH'] ?? '/usr/bin:/bin').split(':')) {
      if (dir.isEmpty) continue;
      final path = '$dir/$program';
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  /// A program for SUDO_ASKPASS: the user's own, or a small script around the first password dialog found,
  /// with the folder made for it (deleted once the dialog has been answered).
  static ({String path, Directory? ownDir})? _sudoAskpass() {
    final own = Platform.environment['SUDO_ASKPASS'];
    if (own != null && own.isNotEmpty && File(own).existsSync()) return (path: own, ownDir: null);
    for (final (program, args) in _askpassDialogs) {
      final path = _which(program);
      if (path == null) continue;
      final dir = Directory.systemTemp.createTempSync('hiddify-askpass-');
      final script = File('${dir.path}/askpass')
        ..writeAsStringSync("#!/bin/sh\nexec '${path.replaceAll("'", r"'\''")}' $args\n");
      Process.runSync('chmod', ['700', dir.path, script.path]);
      return (path: script.path, ownDir: dir);
    }
    return null;
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
