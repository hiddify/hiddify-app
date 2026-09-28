import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/core/model/directories.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_desktop.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcommon/common.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore_service.pbgrpc.dart';
import 'package:hiddify/singbox/model/core_status.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
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
  bool _vpnAvailable = false;
  String _nativeStatus = 'disconnected';

  @override
  bool get managesLifecycle => true;
  @override
  bool get persistsAfterAppExit => _usingVPN;
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
    _nativeStatus = state['status'] as String? ?? 'disconnected';
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
      if (_extensionPort != controlPort || _extensionSecret != secret || bgClient == fgClient) {
        final oldChannel = _extensionChannel;
        _extensionPort = controlPort;
        _extensionSecret = secret;
        _extensionChannel = ClientChannel(
          '127.0.0.1',
          port: controlPort,
          options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
        );
        bgClient = CoreClient(_extensionChannel!, options: CallOptions(metadata: {'x-hiddify-secret': secret}));
        if (oldChannel != null) unawaited(oldChannel.shutdown());
        _clientChanges.add(null);
      }
      _status.add(const CoreStatus.started());
    } else if (_nativeStatus == 'connecting' || _nativeStatus == 'reasserting') {
      _status.add(const CoreStatus.starting());
    } else if (_nativeStatus == 'disconnecting') {
      _status.add(const CoreStatus.stopping());
    } else {
      _status.add(CoreStatus.stopped(message: state['message'] as String?));
    }
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

  @override
  Future<void> startManaged(String path, String name, bool disableMemoryLimit) async {
    final options = _options;
    if (options == null) throw StateError('Apply connection options before starting the core.');
    if (options.enableTun && !_vpnAvailable) {
      throw StateError(
        'VPN requires an authorized Apple Developer team and a build with Network Extension enabled. Proxy modes are available in Debug builds without Network Extension enabled.',
      );
    }
    await stop();
    _status.add(const CoreStatus.starting());
    try {
      if (options.enableTun) {
        _usingVPN = true;
        _startingVPN = true;
        // Save content rather than the app's profile path. The extension must be
        // able to connect with the app closed and in its own sandbox/container.
        final snapshot = await snapshotConfiguration(path);
        final state = await _methods.invokeMapMethod<String, dynamic>('start', {
          'configContent': snapshot.$1,
          'resources': snapshot.$2,
          'configName': name,
          'settingsJSON': jsonEncode(options.toJson()),
          'disableMemoryLimit': disableMemoryLimit,
        });
        _startingVPN = false;
        if (state != null) _receiveState(state);
        if (_nativeStatus != 'connected') throw StateError('macOS did not connect the VPN.');
      } else {
        _usingVPN = false;
        bgClient = fgClient;
        _clientChanges.add(null);
        final response = await fgClient.start(
          StartRequest(configPath: path, configName: name, disableMemoryLimit: disableMemoryLimit),
        );
        _checkResponse(response);
      }
      _status.add(const CoreStatus.started());
    } catch (error) {
      _startingVPN = false;
      _status.add(CoreStatus.stopped(message: error is PlatformException ? error.message : error.toString()));
      rethrow;
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
  Future<(String, Map<String, Uint8List>)> snapshotConfiguration(String path) async {
    final workingDirectory = _workingDirectory;
    if (workingDirectory == null) throw StateError('Set up the core before snapshotting a VPN configuration.');
    final content = await File(path).readAsString();
    final resources = <String, Uint8List>{};
    final document = jsonDecode(content);
    var totalBytes = 0;
    Future<void> collect(dynamic value, String? parent) async {
      if (value is List) {
        for (final item in value) {
          await collect(item, parent);
        }
      } else if (value is Map<String, dynamic>) {
        for (final key in value.keys.toList()) {
          final item = value[key];
          final isFile =
              const {
                'certificate_path',
                'key_path',
                'client_certificate_path',
                'client_key_path',
                'private_key_path',
              }.contains(key) ||
              (key == 'path' && (value['type'] == 'local' || parent == 'geoip' || parent == 'geosite'));
          if (isFile && item is String && item.isNotEmpty) {
            // Match the core's setup working directory, even when the profile
            // lives in configs/ or elsewhere. Absolute resource paths stay intact.
            final source = File(p.isAbsolute(item) ? item : p.join(workingDirectory.path, item));
            final bytes = await source.readAsBytes();
            totalBytes += bytes.length;
            if (totalBytes > 32 * 1024 * 1024) {
              throw StateError(
                'Local VPN resources exceed the 32 MB snapshot limit. Use remote rule sets for large files.',
              );
            }
            final name = '${resources.length}-${p.basename(item).replaceAll(RegExp('[^a-zA-Z0-9._-]'), '_')}';
            resources[name] = bytes;
            value[key] = 'resources/$name';
          } else {
            await collect(item, key);
          }
        }
      }
    }

    await collect(document, null);
    return (jsonEncode(document), resources);
  }

  @override
  Future<bool> stop() async {
    _startingVPN = false;
    // A saved on-demand VPN can be disconnected when the app reopens. Stop its
    // native configuration even when this app instance has never used the VPN.
    if (_vpnAvailable) {
      final state = await _methods.invokeMapMethod<String, dynamic>('stop');
      if (state != null) _receiveState(state);
    }
    final oldChannel = _extensionChannel;
    _extensionChannel = null;
    if (oldChannel != null) await oldChannel.shutdown();
    _usingVPN = false;
    bgClient = fgClient;
    _clientChanges.add(null);
    _checkResponse(await fgClient.stop(Empty()), allowStopped: true);
    _status.add(const CoreStatus.stopped());
    return true;
  }

  @override
  Future<bool> isBgClientAvailable() async => !_usingVPN || _nativeStatus == 'connected';

  @override
  Future<bool> resetTunnel() async {
    await stop();
    if (_vpnAvailable) await _methods.invokeMethod<void>('reset');
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
