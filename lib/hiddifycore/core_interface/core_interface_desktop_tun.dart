import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/hiddifycore/core_interface/admin_permission_refused.dart';
import 'package:hiddify/hiddifycore/core_interface/appimage_service.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_desktop.dart';
import 'package:hiddify/hiddifycore/core_interface/vpn_config_snapshot.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/adminbgservice/admin_bg.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/adminbgservice/admin_bg_service.pbgrpc.dart';
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
  CoreInterfaceDesktopTun() : super(port: 17078) {
    _status.listen((status) {
      if (status is CoreStarted && _usingAdminBg) {
        _watchService();
      } else {
        _unwatchService();
      }
    });
  }

  static const _servicePort = 18020;
  final _status = BehaviorSubject<CoreStatus>.seeded(const CoreStatus.stopped());
  final _clientChanges = StreamController<void>.broadcast();
  ClientChannel? _serviceChannel;
  Directory? _workingDirectory;
  SingboxConfigOption? _options;
  bool _usingAdminBg = false;
  // The user's system proxy this app's core set for the service's engine (see _applyServiceSystemProxy).
  bool _serviceSystemProxy = false;
  bool? _privileged;
  late String _secret;
  // the port of the service the connection runs in: the installed one, or the AppImage's own
  int _servicePortInUse = _servicePort;
  // the AppImage's VPN service, started through pkexec once and kept until the app exits
  AppImageService? _appImageService;
  // checks, while a VPN runs in the service, that the service and its engine still run
  Timer? _serviceWatch;
  int _serviceMisses = 0;
  bool _checkingService = false;

  /// When true, start via admin_bgservice even in proxy mode (Mode C prefer-admin).
  bool useAdminBgService = false;

  /// Optional UI wrapper around elevation (waiting dialog). Returns false if the user stops; the start
  /// then fails with [AdminPermissionRefused], as when the prompt is refused.
  Future<bool> Function(Future<void> work)? wrapAdminElevation;

  /// AppImage payload lives under a user FUSE mount, so no system service can run it: its VPN runs
  /// in a root copy of the same AppImage instead (see [AppImageService]).
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
  void onCoreProcessExited(String message) {
    // In VPN mode the engine runs in the service; only a proxy-mode connection went with the core.
    if (_usingAdminBg || _status.value is CoreStopped) return;
    _status.add(CoreStatus.stopped(alert: CoreAlert.startFailed, message: message));
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
      _useBgClient(fgClient);
      // the stop above may still be under way in the core
      _checkResponse(
        await startOnceStopped(
          fgClient,
          StartRequest(configPath: path, configName: name, disableMemoryLimit: disableMemoryLimit),
        ),
      );
      _status.add(const CoreStatus.started());
      return;
    }

    // Already elevated: run TUN in this process. AppImage also cannot install a service.
    if (await _isPrivileged()) {
      _status.add(const CoreStatus.starting());
      try {
        _usingAdminBg = false;
        _useBgClient(fgClient);
        _checkResponse(
          await fgClient.changeHiddifySettings(
            ChangeHiddifySettingsRequest(hiddifySettingsJson: jsonEncode(options.toJson())),
          ),
        );
        _checkResponse(
          await startOnceStopped(
            fgClient,
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

    _status.add(const CoreStatus.starting());
    try {
      final ensure = _isAppImage
          ? _startAppImageServiceAndAttach(
              path: path,
              name: name,
              options: options,
              disableMemoryLimit: disableMemoryLimit,
            )
          : _ensureAdminBgAndAttach(path: path, name: name, options: options, disableMemoryLimit: disableMemoryLimit);
      final wrap = wrapAdminElevation;
      if (wrap != null) {
        final ok = await wrap(ensure);
        wrapAdminElevation = null;
        if (!ok) throw const AdminPermissionRefused();
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
        // a proxy mode whose profile needs administrator rights runs without the TUN
        proxyOnly: !options.enableTun,
      ),
    )) {
      last = event.progress;
      lastMessage = event.message;
      if (event.progress == EnsureAdminBgServiceProgress.ENSURE_ADMIN_BG_FAILED_PERMISSION_DENIED) {
        throw const AdminPermissionRefused();
      }
      if (event.progress == EnsureAdminBgServiceProgress.ENSURE_ADMIN_BG_FAILED_OTHER) {
        throw StateError(
          (event.message.isNotEmpty)
              ? event.message
              : 'Could not start the VPN service. Allow the administrator prompt and try again.',
        );
      }
    }
    if (last != EnsureAdminBgServiceProgress.ENSURE_ADMIN_BG_SERVICE_CONNECTED) {
      throw StateError(
        (lastMessage != null && lastMessage.isNotEmpty) ? lastMessage : 'The VPN service did not become ready.',
      );
    }

    final secret = (await File(_secretPath).readAsString()).trim();
    if (secret.length < 32) {
      throw StateError('The VPN service secret is missing. Reinstall the VPN service.');
    }
    await _attachService(_servicePort, secret, options);
  }

  /// The AppImage's VPN: its own service, started as root through pkexec on the first connect and
  /// kept while the app runs, so later connects ask for nothing. The engine starts with the same
  /// request as through the installed service.
  Future<void> _startAppImageServiceAndAttach({
    required String path,
    required String name,
    required SingboxConfigOption options,
    required bool disableMemoryLimit,
  }) async {
    final workingDirectory = _workingDirectory;
    if (workingDirectory == null) throw StateError('Set up the core before starting VPN mode.');
    var service = _appImageService;
    if (service == null || !service.running) {
      service = await AppImageService.start(Platform.environment['APPIMAGE']!, pid);
      _appImageService = service;
    }
    final snapshot = await snapshotVpnConfiguration(path, workingDirectory);
    final channel = ClientChannel(
      '127.0.0.1',
      port: AppImageService.port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    try {
      await HiddifyAdminBGClient(channel, options: CallOptions(metadata: {'x-hiddify-secret': service.secret})).start(
        AdminBgStartRequest(
          configContent: snapshot.$1,
          configName: name,
          settingsJson: jsonEncode(options.toJson()),
          resources: snapshot.$2,
          disableMemoryLimit: disableMemoryLimit,
          ownerPid: pid,
          proxyOnly: !options.enableTun,
        ),
      );
    } finally {
      unawaited(channel.shutdown());
    }
    await _attachService(AppImageService.port, service.secret, options);
  }

  /// Points the background client at a running VPN service, and hands its system proxy to this
  /// app's core.
  Future<void> _attachService(int port, String secret, SingboxConfigOption options) async {
    _secret = secret;
    _servicePortInUse = port;
    final old = _serviceChannel;
    _serviceChannel = ClientChannel(
      '127.0.0.1',
      port: port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    bgClient = CoreClient(_serviceChannel!, options: CallOptions(metadata: {'x-hiddify-secret': _secret}));
    if (old != null) unawaited(old.shutdown());
    _usingAdminBg = true;
    _clientChanges.add(null);
    await _applyServiceSystemProxy(options);
  }

  /// The service may die while its VPN runs (a crash, killed, the AppImage's root copy ended): the
  /// app would show it connected with no VPN at all. Its status is asked every few seconds.
  void _watchService() {
    _serviceWatch?.cancel();
    _serviceMisses = 0;
    _serviceWatch = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(_checkService()));
  }

  void _unwatchService() {
    _serviceWatch?.cancel();
    _serviceWatch = null;
  }

  Future<void> _checkService() async {
    final channel = _serviceChannel;
    if (_checkingService || channel == null || !_usingAdminBg || _status.value is! CoreStarted) return;
    _checkingService = true;
    try {
      final status = await HiddifyAdminBGClient(
        channel,
        options: CallOptions(metadata: {'x-hiddify-secret': _secret}),
      ).status(Empty()).timeout(const Duration(seconds: 5));
      _serviceMisses = 0;
      // the service answers without an engine: it was restarted (systemd, Windows), and took the
      // VPN down with the process
      if (status.message == 'stopped') await _serviceLost('The VPN service restarted, and the VPN stopped with it.');
    } catch (error) {
      // one miss may be a reload holding the service; two in a row is a service that is gone
      if (++_serviceMisses >= 2) await _serviceLost('The VPN service stopped unexpectedly.');
    } finally {
      _checkingService = false;
    }
  }

  /// Reports a VPN whose service is gone, as a failure; the service undoes the routing its engine
  /// left when it starts again (hiddify-core CleanupLeftovers).
  Future<void> _serviceLost(String message) async {
    // a stop or a restart under way changed the status: the loss is theirs to report
    if (!_usingAdminBg || _status.value is! CoreStarted) return;
    _unwatchService();
    final lost = _serviceChannel;
    _serviceChannel = null;
    _usingAdminBg = false;
    _useBgClient(fgClient);
    await _restoreServiceSystemProxy();
    if (lost != null) unawaited(lost.shutdown().catchError((_) {}));
    loggy.warning(message);
    _status.add(CoreStatus.stopped(alert: CoreAlert.startFailed, message: message));
  }

  /// Stops the service's engine: through the CLI for the installed service (which the CLI may need
  /// to reach first), over the API for the AppImage's, whose CLI is not reachable from outside it.
  Future<void> _stopServiceEngine(ClientChannel? channel) async {
    if (_isAppImage) {
      if (channel == null) return;
      await HiddifyAdminBGClient(
        channel,
        options: CallOptions(metadata: {'x-hiddify-secret': _secret}),
      ).stop(Empty()).timeout(const Duration(seconds: 10));
      return;
    }
    await _runCli(['admin_bgservice', 'disconnect']);
  }

  /// The service runs as root and cannot set the user's system proxy (the user's desktop session,
  /// D-Bus and Wayland, is out of its reach), so it reports where its config wanted it: the system
  /// proxy mode, or a profile's own proxy inbound beside the TUN. This app's core, which runs as the
  /// user, points the system proxy there, and restores it on disconnect or when it exits.
  Future<void> _applyServiceSystemProxy(SingboxConfigOption options) async {
    final channel = _serviceChannel;
    if (channel == null) return;
    final status = await HiddifyAdminBGClient(
      channel,
      options: CallOptions(metadata: {'x-hiddify-secret': _secret}),
    ).status(Empty()).timeout(const Duration(seconds: 5));
    if (status.systemProxy.isEmpty) {
      await _restoreServiceSystemProxy();
      return;
    }
    final response = await fgClient.setSystemProxyEnabled(
      SetSystemProxyEnabledRequest(isEnabled: true, address: status.systemProxy, supportSocks: status.systemProxySocks),
    );
    if (response.code != ResponseCode.OK) {
      // the system proxy mode is pointless without it; beside a TUN it is only a convenience
      if (!options.enableTun) throw StateError('Could not set the system proxy: ${response.message}');
      loggy.warning('setting the system proxy failed: ${response.message}');
      return;
    }
    _serviceSystemProxy = true;
  }

  @override
  Future<bool?> reloadManaged(String path, String name, bool disableMemoryLimit) async {
    if (!_usingAdminBg) return null;
    try {
      return await _sendToService(path, name, disableMemoryLimit, restart: false);
    } catch (error) {
      loggy.info('the VPN service did not hot reload, restarting: $error');
      return false;
    }
  }

  @override
  Future<bool?> restartManaged(String path, String name, bool disableMemoryLimit) async {
    final options = _options;
    // a connection moving out of the service (a VPN switched to a proxy mode) starts anew
    if (!_usingAdminBg || options == null || !(useAdminBgService || options.enableTun)) return null;
    _status.add(const CoreStatus.starting());
    try {
      final restarted = await _sendToService(path, name, disableMemoryLimit, restart: true);
      if (restarted) _status.add(const CoreStatus.started());
      return restarted;
    } catch (error) {
      await _abandonVpnStart(error);
      rethrow;
    }
  }

  /// Sends the config to the running VPN service, as the start does (a snapshot without file
  /// paths): a hot reload, or a restart of its engine. The system proxy hand-off follows the new
  /// config, which may point it elsewhere or no longer want one.
  Future<bool> _sendToService(String path, String name, bool disableMemoryLimit, {required bool restart}) async {
    final options = _options;
    final workingDirectory = _workingDirectory;
    final channel = _serviceChannel;
    if (options == null || workingDirectory == null || channel == null) return false;
    final snapshot = await snapshotVpnConfiguration(path, workingDirectory);
    final request = AdminBgStartRequest(
      configContent: snapshot.$1,
      configName: name,
      settingsJson: jsonEncode(options.toJson()),
      resources: snapshot.$2,
      disableMemoryLimit: disableMemoryLimit,
      ownerPid: pid,
      proxyOnly: !options.enableTun,
    );
    final client = HiddifyAdminBGClient(channel, options: CallOptions(metadata: {'x-hiddify-secret': _secret}));
    await (restart ? client.restart(request) : client.reload(request));
    await _applyServiceSystemProxy(options);
    return true;
  }

  Future<void> _restoreServiceSystemProxy() async {
    if (!_serviceSystemProxy) return;
    _serviceSystemProxy = false;
    try {
      await fgClient
          .setSystemProxyEnabled(SetSystemProxyEnabledRequest(isEnabled: false))
          .timeout(const Duration(seconds: 5));
    } catch (error) {
      loggy.warning('restoring the system proxy failed: $error');
    }
  }

  /// Tears down a partial VPN connect so the UI never stays Connected/Starting.
  Future<void> _abandonVpnStart(Object error) async {
    await _restoreServiceSystemProxy();
    final failedChannel = _serviceChannel;
    _serviceChannel = null;
    _usingAdminBg = false;
    _useBgClient(fgClient);
    try {
      await _stopServiceEngine(failedChannel);
    } catch (_) {}
    if (failedChannel != null) {
      unawaited(() async {
        try {
          await failedChannel.shutdown();
        } catch (_) {}
      }());
    }
    final message = error.toString();
    _status.add(CoreStatus.stopped(alert: CoreAlert.startFailed, message: message));
    loggy.warning('VPN start failed: $message');
  }

  /// Re-arms the background listeners only when the client really changes. Every event reopens
  /// the bg log stream, and a stop followed by a proxy-mode start sent two for the same client.
  void _useBgClient(CoreClient client) {
    if (identical(bgClient, client)) return;
    bgClient = client;
    _clientChanges.add(null);
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
    await _restoreServiceSystemProxy();
    final old = _serviceChannel;
    _serviceChannel = null;
    _usingAdminBg = false;
    useAdminBgService = false;
    wrapAdminElevation = null;
    _useBgClient(fgClient);
    if (wasAdminBg) {
      try {
        await _stopServiceEngine(old);
      } catch (error) {
        loggy.warning('stopping the VPN service failed: $error');
      }
    }
    if (old != null) {
      unawaited(() async {
        try {
          await old.shutdown();
        } catch (error) {
          loggy.warning('service channel shutdown failed: $error');
        }
      }());
    }
    try {
      // Bounded: a stalled channel must fail the stop, not leave the next connect stuck on connecting.
      _checkResponse(await fgClient.stop(Empty()).timeout(const Duration(seconds: 5)), allowStopped: true);
    } catch (error) {
      loggy.warning('stopping the in-process core failed: $error');
    }
    _status.add(const CoreStatus.stopped());
    return true;
  }

  @override
  Future<bool> isBgClientAvailable() async {
    if (!_usingAdminBg) return true;
    if (_isAppImage) return _appImageService?.running ?? false;
    try {
      final socket = await Socket.connect('127.0.0.1', _servicePortInUse, timeout: const Duration(milliseconds: 200));
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
  Future<void> shutdown() async {
    // the AppImage's root service stops its engine and exits with the app; asked first, so it is
    // done before the image's files go away with the app
    final service = _appImageService;
    _appImageService = null;
    await service?.stop();
    await super.shutdown();
  }

  @override
  Future<void> dispose() async {
    _unwatchService();
    await _serviceChannel?.shutdown();
    await _clientChanges.close();
    await _status.close();
  }
}
