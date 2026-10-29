import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_desktop.dart';
import 'package:hiddify/hiddifycore/core_interface/vpn_config_snapshot.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

/// Windows and Linux: full core usually runs in elevated admin_bgservice
/// (`HiddifyAdminBG`). Flutter never elevates; [NeedAdminBgService] /
/// [EnsureAdminBgService] live in hiddify-core.
class CoreInterfaceDesktopTun extends CoreInterfaceDesktop {
  CoreInterfaceDesktopTun() : super(port: 17078);

  static const _servicePort = 18020;
  final _status = BehaviorSubject<CoreStatus>.seeded(const CoreStatus.stopped());
  final _clientChanges = StreamController<void>.broadcast();
  ClientChannel? _serviceChannel;
  Directory? _workingDirectory;
  SingboxConfigOption? _options;
  bool _usingAdminBg = false;
  bool? _privileged;
  late String _secret;

  /// When true, start via admin_bgservice even in proxy mode (Mode C prefer-admin).
  bool useAdminBgService = false;

  /// Optional UI wrapper around elevation (waiting dialog). Returns false if the user stops.
  Future<bool> Function(Future<void> work)? wrapAdminElevation;

  /// AppImage payload lives under a user FUSE mount; root/`pkexec` cannot exec that path.
  bool get _isAppImage => Platform.isLinux && (Platform.environment['APPIMAGE'] ?? '').isNotEmpty;

  @override
  bool get managesLifecycle => true;
  @override
  bool get persistsAfterAppExit => false;
  @override
  Stream<CoreStatus> get managedStatus => _status.stream;
  @override
  Stream<void> get clientChanges => _clientChanges.stream;

  String get _cliPath {
    final dir = p.dirname(Platform.resolvedExecutable);
    return p.join(dir, Platform.isWindows ? 'HiddifyCli.exe' : 'HiddifyCli');
  }

  String get _dataDir {
    if (Platform.isWindows) {
      final base = Platform.environment['PROGRAMDATA'] ?? r'C:\ProgramData';
      return p.join(base, 'Hiddify', 'AdminBgService');
    }
    return '/var/lib/hiddify-admin-bgservice';
  }

  String get _secretPath => p.join(_dataDir, 'control.secret');

  String get _ownerUser =>
      Platform.isWindows ? (Platform.environment['USERNAME'] ?? '') : (Platform.environment['USER'] ?? '');

  @override
  Future<String> setup(Directories directories, bool debug, int mode) async {
    final error = await super.setup(directories, debug, mode);
    if (error.isNotEmpty) return error;
    _workingDirectory = directories.workingDir.absolute;
    return '';
  }

  @override
  Future<void> setOptions(SingboxConfigOption options) async {
    _options = options;
    // When admin_bgservice will own TUN, fg must not enable TUN; full settings go in Ensure.
    final adminOwnsTun = useAdminBgService || (options.enableTun && !await _isPrivileged());
    final forFg = adminOwnsTun ? options.copyWith(enableTun: false) : options;
    final response = await fgClient.changeHiddifySettings(
      ChangeHiddifySettingsRequest(hiddifySettingsJson: jsonEncode(forFg.toJson())),
    );
    _checkResponse(response);
  }

  Future<NeedAdminBgServiceResponse> needAdminBgService({
    required String serviceMode,
    required String settingsJson,
    required AdminPreference adminPreference,
    bool privilegeErrorRemembered = false,
  }) {
    return fgClient.needAdminBgService(
      NeedAdminBgServiceRequest(
        serviceMode: serviceMode,
        hiddifySettingsJson: settingsJson,
        adminPreference: adminPreference,
        privilegeErrorRemembered: privilegeErrorRemembered,
      ),
    );
  }

  @override
  Future<void> startManaged(String path, String name, bool disableMemoryLimit) async {
    final options = _options;
    if (options == null) throw StateError('Apply connection options before starting the core.');
    await stop();

    final wantAdminBg = useAdminBgService || options.enableTun;
    if (!wantAdminBg) {
      _usingAdminBg = false;
      bgClient = fgClient;
      _clientChanges.add(null);
      _checkResponse(
        await fgClient.start(StartRequest(configPath: path, configName: name, disableMemoryLimit: disableMemoryLimit)),
      );
      _status.add(const CoreStatus.started());
      return;
    }

    // Already elevated: run TUN in this process. AppImage also cannot install a service.
    if (await _isPrivileged()) {
      _status.add(const CoreStatus.starting());
      try {
        _usingAdminBg = false;
        bgClient = fgClient;
        _clientChanges.add(null);
        _checkResponse(
          await fgClient.changeHiddifySettings(
            ChangeHiddifySettingsRequest(hiddifySettingsJson: jsonEncode(options.toJson())),
          ),
        );
        _checkResponse(
          await fgClient.start(
            StartRequest(configPath: path, configName: name, disableMemoryLimit: disableMemoryLimit),
          ),
        );
        _status.add(const CoreStatus.started());
      } catch (error) {
        _status.add(CoreStatus.stopped(message: error.toString()));
        rethrow;
      }
      return;
    }

    if (_isAppImage) {
      throw StateError(
        'VPN mode in the AppImage needs root. Quit and run: sudo ${Platform.environment['APPIMAGE']}',
      );
    }

    _status.add(const CoreStatus.starting());
    try {
      final ensure = _ensureAdminBgAndAttach(
        path: path,
        name: name,
        options: options,
        disableMemoryLimit: disableMemoryLimit,
      );
      final wrap = wrapAdminElevation;
      if (wrap != null) {
        final ok = await wrap(ensure);
        wrapAdminElevation = null;
        if (!ok) {
          throw StateError('Administrator permission was not given, so VPN mode could not connect.');
        }
      } else {
        await ensure;
      }
      _status.add(const CoreStatus.started());
    } catch (error) {
      wrapAdminElevation = null;
      await _abandonVpnStart(error);
      rethrow;
    }
  }

  Future<void> _ensureAdminBgAndAttach({
    required String path,
    required String name,
    required SingboxConfigOption options,
    required bool disableMemoryLimit,
  }) async {
    final workingDirectory = _workingDirectory;
    if (workingDirectory == null) throw StateError('Set up the core before starting VPN mode.');
    final snapshot = await snapshotVpnConfiguration(path, workingDirectory);
    final resources = <String, List<int>>{};
    for (final entry in snapshot.$2.entries) {
      resources[entry.key] = entry.value;
    }

    EnsureAdminBgServiceProgress? last;
    String? lastMessage;
    await for (final event in fgClient.ensureAdminBgService(
      EnsureAdminBgServiceRequest(
        configContent: snapshot.$1,
        configName: name,
        settingsJson: jsonEncode(options.toJson()),
        resources: resources,
        disableMemoryLimit: disableMemoryLimit,
        ownerPid: pid,
        cliPath: _cliPath,
        ownerUser: _ownerUser,
      ),
    )) {
      last = event.progress;
      lastMessage = event.message;
      if (event.progress == EnsureAdminBgServiceProgress.ENSURE_ADMIN_BG_FAILED_PERMISSION_DENIED ||
          event.progress == EnsureAdminBgServiceProgress.ENSURE_ADMIN_BG_FAILED_OTHER) {
        throw StateError(
          (event.message.isNotEmpty)
              ? event.message
              : 'Could not start the VPN service. Allow the administrator prompt and try again.',
        );
      }
    }
    if (last != EnsureAdminBgServiceProgress.ENSURE_ADMIN_BG_SERVICE_CONNECTED) {
      throw StateError(
        (lastMessage != null && lastMessage.isNotEmpty)
            ? lastMessage
            : 'The VPN service did not become ready.',
      );
    }

    _secret = (await File(_secretPath).readAsString()).trim();
    if (_secret.length < 32) {
      throw StateError('The VPN service secret is missing. Reinstall the VPN service.');
    }
    final old = _serviceChannel;
    _serviceChannel = ClientChannel(
      '127.0.0.1',
      port: _servicePort,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    bgClient = CoreClient(_serviceChannel!, options: CallOptions(metadata: {'x-hiddify-secret': _secret}));
    if (old != null) unawaited(old.shutdown());
    _usingAdminBg = true;
    _clientChanges.add(null);
  }

  /// Tears down a partial VPN connect so the UI never stays Connected/Starting.
  Future<void> _abandonVpnStart(Object error) async {
    final failedChannel = _serviceChannel;
    _serviceChannel = null;
    _usingAdminBg = false;
    bgClient = fgClient;
    _clientChanges.add(null);
    if (failedChannel != null) {
      unawaited(() async {
        try {
          await failedChannel.shutdown();
        } catch (_) {}
      }());
    }
    try {
      await _runCli(['admin_bgservice', 'disconnect']);
    } catch (_) {}
    final message = error.toString();
    _status.add(CoreStatus.stopped(alert: CoreAlert.startFailed, message: message));
    loggy.warning('VPN start failed: $message');
  }

  Future<bool> _isPrivileged() async {
    final cached = _privileged;
    if (cached != null) return cached;
    // The in-process core checks its own token (hutils.IsAdmin): no `id -u` or
    // PowerShell child process, which antivirus heuristics score against a GUI app.
    try {
      final privileged = (await fgClient.isAdmin(Empty())).isAdmin;
      loggy.debug('core IsAdmin: $privileged');
      _privileged = privileged;
      return privileged;
    } catch (e) {
      // Not cached: the core may simply not be up yet.
      loggy.warning('core IsAdmin failed, assuming unprivileged: $e');
      return false;
    }
  }

  Future<void> _runCli(List<String> args) async {
    final result = await Process.run(_cliPath, args);
    if (result.exitCode != 0) {
      final message = result.stderr.toString().trim();
      throw StateError(message.isEmpty ? 'The VPN service command failed.' : message);
    }
  }

  void _checkResponse(CoreInfoResponse response, {bool allowStopped = false}) {
    if (response.messageType != MessageType.EMPTY &&
        response.messageType != MessageType.ALREADY_STARTED &&
        !(allowStopped && response.messageType == MessageType.ALREADY_STOPPED)) {
      throw StateError('${response.messageType}: ${response.message}');
    }
  }

  @override
  Future<bool> stop() async {
    _status.add(const CoreStatus.stopping());
    final wasAdminBg = _usingAdminBg;
    final old = _serviceChannel;
    _serviceChannel = null;
    _usingAdminBg = false;
    useAdminBgService = false;
    wrapAdminElevation = null;
    bgClient = fgClient;
    _clientChanges.add(null);
    if (old != null) {
      unawaited(() async {
        try {
          await old.shutdown();
        } catch (error) {
          loggy.warning('service channel shutdown failed: $error');
        }
      }());
    }
    if (wasAdminBg) {
      try {
        await _runCli(['admin_bgservice', 'disconnect']);
      } catch (error) {
        loggy.warning('stopping the VPN service failed: $error');
      }
    }
    try {
      _checkResponse(await fgClient.stop(Empty()), allowStopped: true);
    } catch (error) {
      loggy.warning('stopping the in-process core failed: $error');
    }
    _status.add(const CoreStatus.stopped());
    return true;
  }

  @override
  Future<bool> isBgClientAvailable() async {
    if (!_usingAdminBg) return true;
    try {
      final socket = await Socket.connect('127.0.0.1', _servicePort, timeout: const Duration(milliseconds: 200));
      socket.destroy();
      return File(_secretPath).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> resetTunnel() async {
    await stop();
    return true;
  }

  @override
  Future<void> dispose() async {
    await _serviceChannel?.shutdown();
    await _clientChanges.close();
    await _status.close();
  }
}
