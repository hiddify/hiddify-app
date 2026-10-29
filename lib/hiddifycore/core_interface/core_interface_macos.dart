import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_desktop.dart';
import 'package:hiddify/hiddifycore/core_interface/vpn_config_snapshot.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/adminbgservice/admin_bg_service.pbgrpc.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

class CoreInterfaceMacOS extends CoreInterfaceDesktop {
  // Keep the app's parser/proxy service separate from iOS-on-Mac's 17078/17079.
  CoreInterfaceMacOS() : super(port: 17080);

  @visibleForTesting
  CoreInterfaceMacOS.withForegroundClient(
    CoreClient client,
    Map<String, dynamic> nativeState, {
    Directory? workingDirectory,
  }) : super(port: 17080) {
    fgClient = bgClient = client;
    _workingDirectory = workingDirectory?.absolute;
    _receiveState(nativeState);
  }

  static const _methods = MethodChannel('com.hiddify.app/macos-vpn');
  static const _events = EventChannel('com.hiddify.app/macos-vpn-status');
  final _status = BehaviorSubject<CoreStatus>.seeded(const CoreStatus.stopped());
  final _clientChanges = StreamController<void>.broadcast();
  StreamSubscription<dynamic>? _nativeSubscription;
  StreamSubscription<CoreInfoResponse>? _foregroundSubscription;
  ClientChannel? _extensionChannel;
  int? _extensionPort;
  String? _extensionSecret;
  Directory? _workingDirectory;
  SingboxConfigOption? _options;
  bool _usingVPN = false;
  bool _startingVPN = false;
  /// Suppresses native "connected" events while stop() is in flight (app resume
  /// re-subscribes the EventChannel and would otherwise flash Connected again).
  bool _stoppingVPN = false;
  bool _vpnAvailable = false;
  // The Mac App Store build is sandboxed: its tunnel also sets the system proxy, which the app cannot.
  bool _proxyThroughTunnel = false;
  // Builds without a Developer ID have no Network Extension. Their VPN runs the full core in
  // hiddify-core's tunnel service (root launchd). Dart still uses the useTunnel method-channel path;
  // the service exposes the same port/secret status fields as the extension.
  bool _tunnelServiceAvailable = false;
  bool _tunnelServiceReady = false;
  /// Suppresses [clientChanges] during stop-before-start so coreRestartSignal does not rebuild UI mid-connect.
  bool _suppressClientChanges = false;
  String _nativeStatus = 'disconnected';

  /// True when this build uses the root admin_bgservice (no Network Extension).
  bool get tunnelServiceAvailable => _tunnelServiceAvailable;

  /// True when the root service matches this app build (connect needs no password).
  bool get tunnelServiceReady => _tunnelServiceReady;

  @override
  bool get managesLifecycle => true;
  @override
  // The unsigned tunnel service stops when this app exits; only the Network Extension can outlive it.
  bool get persistsAfterAppExit => _usingVPN && !_tunnelServiceAvailable;
  @override
  Stream<CoreStatus> get managedStatus => _status.stream;
  @override
  Stream<void> get clientChanges => _clientChanges.stream;

  @override
  Future<String> setup(Directories directories, bool debug, int mode) async {
    if (_nativeSubscription != null) return '';
    final workingDirectory = directories.workingDir.absolute;
    final error = await super.setup(directories, debug, mode);
    if (error.isNotEmpty) return error;
    _workingDirectory = workingDirectory;
    // Restore an existing system VPN before reporting the foreground state.
    final state = await _methods.invokeMapMethod<String, dynamic>('initialize');
    if (state != null) _receiveState(state);
    _nativeSubscription = _events.receiveBroadcastStream().listen(
      (dynamic state) => _receiveState(Map<String, dynamic>.from(state as Map)),
      onError: (Object error) => loggy.error('macOS VPN status error: $error'),
    );
    _foregroundSubscription = fgClient
        .coreInfoListener(Empty())
        .listen(
          (event) {
            if (!_usingVPN) {
              _status.add(
                event.messageType == MessageType.ALREADY_STOPPED
                    ? const CoreStatus.stopped()
                    : CoreStatus.fromCoreInfo(event),
              );
            }
          },
          onError: (Object error) {
            if (!_usingVPN) _status.add(CoreStatus.stopped(message: error.toString()));
          },
        );
    return '';
  }

  void _receiveState(Map<String, dynamic> state) {
    _vpnAvailable = state['available'] == true;
    _proxyThroughTunnel = state['proxyThroughTunnel'] == true;
    _tunnelServiceAvailable = state['tunnelService'] == true;
    _tunnelServiceReady = state['serviceReady'] == true;
    _nativeStatus = state['status'] as String? ?? 'disconnected';
    if (_stoppingVPN &&
        (_nativeStatus == 'connected' || _nativeStatus == 'connecting' || _nativeStatus == 'reasserting')) {
      _nativeStatus = 'disconnecting';
      _status.add(const CoreStatus.stopping());
      return;
    }
    if (_nativeStatus == 'connected' || _nativeStatus == 'connecting' || _nativeStatus == 'reasserting') {
      _usingVPN = true;
    }
    if (!_usingVPN) return;
    if (state['activation'] == 'waitingForApproval' && _nativeStatus == 'disconnected') {
      _status.add(CoreStatus.stopped(message: state['message'] as String?));
      return;
    }
    if (_startingVPN &&
        _nativeStatus == 'disconnected' &&
        state['activation'] != 'failed' &&
        state['activation'] != 'requiresReboot') {
      _status.add(const CoreStatus.starting());
      return;
    }
    if (_nativeStatus == 'connected') {
      final controlPort = state['port'] as int?;
      final secret = state['secret'] as String?;
      if (controlPort == null || secret == null || secret.isEmpty) {
        _status.add(const CoreStatus.stopped(message: 'The saved VPN control credentials are missing.'));
        return;
      }
      _attachExtensionClient(controlPort, secret);
      _status.add(const CoreStatus.started());
    } else if (_nativeStatus == 'connecting' || _nativeStatus == 'reasserting') {
      _status.add(const CoreStatus.starting());
    } else if (_nativeStatus == 'disconnecting') {
      _status.add(const CoreStatus.stopping());
    } else {
      // Quiet stop-before-start clears _usingVPN first so this path is skipped; still
      // guard so a late native event cannot flash Disconnected mid-connect.
      if (!_suppressClientChanges) {
        _status.add(CoreStatus.stopped(message: state['message'] as String?));
      }
    }
  }

  /// Reuses the gRPC channel when port/secret are unchanged (avoids leaking TCP to :18020).
  void _attachExtensionClient(int controlPort, String secret) {
    final sameEndpoint = _extensionPort == controlPort && _extensionSecret == secret;
    if (sameEndpoint && _extensionChannel != null) {
      if (bgClient == fgClient) {
        bgClient = CoreClient(
          _extensionChannel!,
          options: CallOptions(metadata: {'x-hiddify-secret': secret}),
        );
        _notifyClientChange();
      }
      return;
    }
    final oldChannel = _extensionChannel;
    _extensionPort = controlPort;
    _extensionSecret = secret;
    _extensionChannel = ClientChannel(
      '127.0.0.1',
      port: controlPort,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        // Drop idle sockets so a missed shutdown cannot leave ESTABLISHED forever.
        idleTimeout: Duration(seconds: 10),
      ),
    );
    bgClient = CoreClient(
      _extensionChannel!,
      options: CallOptions(metadata: {'x-hiddify-secret': secret}),
    );
    if (oldChannel != null) unawaited(oldChannel.shutdown());
    _notifyClientChange();
  }

  @override
  Future<void> setOptions(SingboxConfigOption options) async {
    _options = options;
    // The app core supplies parsing and proxy modes; only the extension may TUN.
    final foreground = options.copyWith(enableTun: false);
    final response = await fgClient.changeHiddifySettings(
      ChangeHiddifySettingsRequest(hiddifySettingsJson: jsonEncode(foreground.toJson())),
    );
    _checkResponse(response);
  }

  /// Installs/updates the root admin_bgservice (may show the macOS password prompt).
  /// Call after Mode B consent; [startManaged] then connects without elevating again.
  Future<void> installAdminBgService() async {
    if (!_tunnelServiceAvailable) {
      throw StateError('VPN is unavailable in this build. Proxy modes are available.');
    }
    if (_tunnelServiceReady) return;
    try {
      await _methods.invokeMethod<void>('installTunnelService');
    } on PlatformException catch (error) {
      throw StateError(error.message ?? error.toString());
    }
    final state = await _methods.invokeMapMethod<String, dynamic>('status');
    if (state != null) _receiveState(state);
    if (!_tunnelServiceReady) {
      throw StateError('The VPN service was installed but is not ready yet. Try connecting again.');
    }
  }

  void _notifyClientChange() {
    if (!_suppressClientChanges) _clientChanges.add(null);
  }

  @override
  Future<void> startManaged(String path, String name, bool disableMemoryLimit) async {
    final options = _options;
    if (options == null) throw StateError('Apply connection options before starting the core.');
    final proxyOnly = !options.enableTun && options.setSystemProxy && _proxyThroughTunnel;
    final useTunnel = options.enableTun || proxyOnly;
    if (useTunnel && !_vpnAvailable) {
      throw StateError('VPN is unavailable in this build. Proxy modes are available.');
    }
    _suppressClientChanges = true;
    try {
      // Quiet: do not publish Stopped mid-connect (that flashed "tap to connect" with no error).
      await stop(quiet: true);
      _status.add(const CoreStatus.starting());
      if (useTunnel) {
        _usingVPN = true;
        _startingVPN = true;
        // Save content rather than the app's profile path. The extension or root service must be
        // able to apply it without reading the app's working directory.
        final snapshot = await snapshotConfiguration(path);
        final state = await _methods.invokeMapMethod<String, dynamic>('start', {
          'configContent': snapshot.$1,
          'resources': snapshot.$2,
          'configName': name,
          'settingsJSON': jsonEncode(options.toJson()),
          'disableMemoryLimit': disableMemoryLimit,
          'proxyOnly': proxyOnly,
        });
        _startingVPN = false;
        if (state != null) _receiveState(state);
        if (_nativeStatus != 'connected') throw StateError('macOS did not connect the VPN.');
        // Control-port Core.Stop is denied; AdminBg.Status is the source of truth for
        // whether the root engine is actually running (avoids a false Connected UI).
        if (_tunnelServiceAvailable && !await _adminBgEngineStarted()) {
          throw StateError('VPN service reported connected but the engine is not running.');
        }
      } else {
        _usingVPN = false;
        bgClient = fgClient;
        final response = await fgClient.start(
          StartRequest(configPath: path, configName: name, disableMemoryLimit: disableMemoryLimit),
        );
        _checkResponse(response);
      }
      _status.add(const CoreStatus.started());
    } catch (error) {
      _startingVPN = false;
      final message = error is PlatformException ? (error.message ?? error.toString()) : error.toString();
      // startFailed so the status stream carries a ConnectionFailure (not a silent Disconnected).
      _status.add(CoreStatus.stopped(alert: CoreAlert.startFailed, message: message));
      rethrow;
    } finally {
      _suppressClientChanges = false;
      _notifyClientChange();
    }
  }

  void _checkResponse(CoreInfoResponse response, {bool allowStopped = false}) {
    if (response.messageType != MessageType.EMPTY &&
        response.messageType != MessageType.ALREADY_STARTED &&
        !(allowStopped && response.messageType == MessageType.ALREADY_STOPPED)) {
      throw StateError('${response.messageType}: ${response.message}');
    }
  }

  @visibleForTesting
  Future<(String, Map<String, Uint8List>)> snapshotConfiguration(String path) {
    final workingDirectory = _workingDirectory;
    if (workingDirectory == null) throw StateError('Set up the core before snapshotting a VPN configuration.');
    return snapshotVpnConfiguration(path, workingDirectory);
  }

  HiddifyAdminBGClient? _adminBgClientOrNull() {
    final channel = _extensionChannel;
    final secret = _extensionSecret;
    if (channel == null || secret == null || secret.isEmpty) return null;
    return HiddifyAdminBGClient(
      channel,
      options: CallOptions(metadata: {'x-hiddify-secret': secret}),
    );
  }

  Future<bool> _adminBgEngineStarted() async {
    final client = _adminBgClientOrNull();
    if (client == null) return false;
    try {
      final res = await client.status(Empty()).timeout(const Duration(seconds: 3));
      return res.message == 'started';
    } catch (error) {
      loggy.warning('admin_bgservice status failed: $error');
      return false;
    }
  }

  /// Stops the root engine via AdminBg.Stop (Core.Stop is intentionally denied on :18020).
  /// Returns true when the RPC completed without error.
  Future<bool> _stopAdminBgEngine() async {
    final client = _adminBgClientOrNull();
    if (client == null) return false;
    final sw = Stopwatch()..start();
    try {
      await client.stop(Empty()).timeout(const Duration(seconds: 8));
      loggy.warning('macOS stop: AdminBg.Stop ok in ${sw.elapsedMilliseconds}ms');
      return true;
    } catch (error) {
      loggy.warning('macOS stop: AdminBg.Stop failed in ${sw.elapsedMilliseconds}ms: $error');
      return false;
    }
  }

  @override
  Future<bool> stop({bool quiet = false}) async {
    final total = Stopwatch()..start();
    _startingVPN = false;
    if (!quiet) {
      _stoppingVPN = true;
      _status.add(const CoreStatus.stopping());
    }
    // Clear before native stop so _receiveState(disconnected) does not publish Stopped
    // during quiet stop-before-start (that flashed "tap to connect" and stuck SingleCall).
    final stopEngine = !quiet && _tunnelServiceAvailable && _extensionChannel != null;
    _usingVPN = false;
    bgClient = fgClient;

    // Stop over AdminBg gRPC first. If that works, tell Swift to skip spawning
    // another `Hiddify --tunnel disconnect` (the double-stop was the long hang).
    var engineStopped = false;
    if (stopEngine) {
      engineStopped = await _stopAdminBgEngine();
    } else {
      loggy.warning(
        'macOS stop: skip AdminBg.Stop (quiet=$quiet tunnel=$_tunnelServiceAvailable '
        'channel=${_extensionChannel != null})',
      );
    }

    // A saved on-demand VPN can be disconnected when the app reopens. Stop its
    // native configuration even when this app instance has never used the VPN.
    // Quiet + already idle: skip the serial Swift queue (stop-before-start after disconnect).
    final needsNativeStop =
        (_vpnAvailable || _tunnelServiceAvailable) &&
        (!quiet || _nativeStatus != 'disconnected' || _extensionChannel != null);
    if (needsNativeStop) {
      final nativeSw = Stopwatch()..start();
      final state = await _methods.invokeMapMethod<String, dynamic>('stop', {
        if (engineStopped) 'engineStopped': true,
      });
      loggy.warning(
        'macOS stop: native stop in ${nativeSw.elapsedMilliseconds}ms (engineStopped=$engineStopped)',
      );
      if (state != null) _receiveState(state);
    }

    try {
      if (quiet) {
        // Keep the channel for the immediate reconnect; detach only (bgClient already fg).
        final fgSw = Stopwatch()..start();
        _checkResponse(await fgClient.stop(Empty()), allowStopped: true);
        loggy.warning(
          'macOS stop: quiet fg stop in ${fgSw.elapsedMilliseconds}ms; total ${total.elapsedMilliseconds}ms',
        );
        return true;
      }

      // Notify first so log/status streams cancel, then shut the socket down.
      final oldChannel = _extensionChannel;
      _extensionChannel = null;
      _extensionPort = null;
      _extensionSecret = null;
      _notifyClientChange();
      if (oldChannel != null) {
        final shutSw = Stopwatch()..start();
        try {
          await oldChannel.shutdown().timeout(const Duration(seconds: 1));
          loggy.warning('macOS stop: channel shutdown in ${shutSw.elapsedMilliseconds}ms');
        } catch (error) {
          loggy.warning('macOS stop: channel shutdown after ${shutSw.elapsedMilliseconds}ms: $error');
        }
      }
      final fgSw = Stopwatch()..start();
      _checkResponse(
        await fgClient.stop(Empty()).timeout(const Duration(seconds: 2)),
        allowStopped: true,
      );
      loggy.warning('macOS stop: fg stop in ${fgSw.elapsedMilliseconds}ms');
      _status.add(const CoreStatus.stopped());
      loggy.warning('macOS stop: TOTAL ${total.elapsedMilliseconds}ms');
      return true;
    } finally {
      _stoppingVPN = false;
    }
  }

  @override
  Future<bool> isBgClientAvailable() async => !_usingVPN || _nativeStatus == 'connected';

  @override
  Future<bool> resetTunnel() async {
    await stop();
    if (_vpnAvailable || _tunnelServiceAvailable) await _methods.invokeMethod<void>('reset');
    return true;
  }

  @override
  Future<void> dispose() async {
    await _nativeSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _extensionChannel?.shutdown();
    await _clientChanges.close();
    await _status.close();
  }
}
