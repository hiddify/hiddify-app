import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hiddify/core/logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

 // Service to manage TUIC binary as external plugin
 // TUIC is a high-performance proxy protocol based on QUIC
class TuicService {
  Process? _process;
  bool _isRunning = false;
  String? _lastError;
  int _localSocksPort = 10810;
  static const String _tuicVersion = '1.0.0';
  static const List<String> _downloadUrls = [
    'https://github.com/EAimTY/tuic/releases/download/tuic-client-$_tuicVersion/tuic-client-$_tuicVersion-x86_64-pc-windows-msvc.exe',
    'https://ghproxy.com/https://github.com/EAimTY/tuic/releases/download/tuic-client-$_tuicVersion/tuic-client-$_tuicVersion-x86_64-pc-windows-msvc.exe',
  ];

  bool get isRunning => _isRunning;
  String? get lastError => _lastError;
  int get localSocksPort => _localSocksPort;

  // Get the TUIC executable path
  Future<String> getTuicPath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'tuic-client.exe');
  }

  // Get the TUIC config path
  Future<String> getConfigPath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'tuic-config.json');
  }

  // Check if TUIC binary exists
  Future<bool> isTuicAvailable() async {
    final path = await getTuicPath();
    final file = File(path);
    return file.existsSync();
  }

  // Download TUIC binary
  Future<void> downloadTuic({void Function(double)? onProgress}) async {
    final tuicPath = await getTuicPath();
    
    for (final url in _downloadUrls) {
      try {
        Logger.tuic.info('Downloading TUIC from $url');
        
        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(url));
          final response = await client.send(request);
          
          if (response.statusCode != 200) {
            Logger.tuic.warning('Failed to download from $url: ${response.statusCode}');
            continue;
          }

          final contentLength = response.contentLength ?? 0;
          var received = 0;
          final bytes = <int>[];

          await for (final chunk in response.stream) {
            bytes.addAll(chunk);
            received += chunk.length;
            if (contentLength > 0) {
              onProgress?.call(received / contentLength);
            }
          }

          final tmpPath = '$tuicPath.download';
          final tmpFile = File(tmpPath);
          await tmpFile.writeAsBytes(bytes);

          final outFile = File(tuicPath);
          if (await FileSystemEntity.type(tuicPath) != FileSystemEntityType.notFound) {
            await outFile.delete();
          }
          await tmpFile.rename(tuicPath);
          Logger.tuic.info('TUIC downloaded to $tuicPath');
          return;
        } finally {
          client.close();
        }
      } catch (e) {
        Logger.tuic.warning('Failed to download TUIC from $url: $e');
        continue;
      }
    }

    throw Exception('Failed to download TUIC from all sources');
  }

  // Generate TUIC config file
  Future<void> generateConfig({
    required String server,
    required int port,
    required String uuid,
    required String password,
    String? sni,
    bool insecure = false,
    List<String>? alpn,
    String congestionControl = 'bbr',
    String udpRelayMode = 'native',
    bool disableSni = false,
  }) async {
    final configPath = await getConfigPath();
    
    final config = <String, dynamic>{
      'relay': {
        'server': '$server:$port',
        'uuid': uuid,
        'password': password,
        'udp_relay_mode': udpRelayMode,
        'congestion_control': congestionControl,
        'alpn': alpn ?? ['h3'],
        'zero_rtt_handshake': true,
        'disable_sni': disableSni,
        'timeout': '8s',
        'heartbeat': '3s',
        'gc_interval': '3s',
        'gc_lifetime': '15s',
      },
      'local': {
        'server': '127.0.0.1:$_localSocksPort',
        'max_packet_size': 1500,
      },
      'log_level': 'info',
    };
    if (sni != null && sni.isNotEmpty) {
      (config['relay'] as Map<String, dynamic>)['server'] = '$server:$port';
    }

    if (insecure) {
      (config['relay'] as Map<String, dynamic>)['disable_certificate_verification'] = true;
    }
    
    await File(configPath).writeAsString(jsonEncode(config));
    Logger.tuic.info('TUIC config generated at $configPath');
  }

  // Start TUIC process
  Future<String?> start({
    required String server,
    required int port,
    required String uuid,
    required String password,
    String? sni,
    bool insecure = false,
    List<String>? alpn,
    String congestionControl = 'bbr',
    String udpRelayMode = 'native',
    bool disableSni = false,
    int localPort = 10810,
  }) async {
    if (_isRunning) {
      Logger.tuic.warning('TUIC is already running');
      return null;
    }

    _localSocksPort = localPort;
    if (!await isTuicAvailable()) {
      Logger.tuic.info('TUIC not found, downloading...');
      try {
        await downloadTuic();
      } catch (e) {
        return _lastError = 'Failed to download TUIC: $e';
      }
    }
    try {
      await generateConfig(
        server: server,
        port: port,
        uuid: uuid,
        password: password,
        sni: sni,
        insecure: insecure,
        alpn: alpn,
        congestionControl: congestionControl,
        udpRelayMode: udpRelayMode,
        disableSni: disableSni,
      );
    } catch (e) {
      return _lastError = 'Failed to generate config: $e';
    }

    final tuicPath = await getTuicPath();
    final configPath = await getConfigPath();

    Logger.tuic.info('Starting TUIC: $tuicPath -c $configPath');

    try {
      _process = await Process.start(
        tuicPath,
        ['-c', configPath],
      );

      _isRunning = true;
      _lastError = null;
      _process!.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            Logger.tuic.debug('[stdout] $line');
          }
        }
      });
      _process!.stderr.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            Logger.tuic.warning('[stderr] $line');
            if (line.contains('error') || line.contains('failed')) {
              _lastError = line;
            }
          }
        }
      });
      unawaited(_process!.exitCode.then((code) {
        Logger.tuic.info('TUIC exited with code: $code');
        _isRunning = false;
        if (code != 0) {
          _lastError = 'TUIC exited with code $code';
        }
      }),);
      await Future<void>.delayed(const Duration(seconds: 2));

      if (!_isRunning) {
        return _lastError ?? 'TUIC failed to start';
      }

      Logger.tuic.info('TUIC started successfully on port $_localSocksPort');
      return null;
    } catch (e) {
      _lastError = 'Failed to start TUIC: $e';
      Logger.tuic.error(_lastError);
      _isRunning = false;
      return _lastError;
    }
  }

  // Stop TUIC process
  Future<void> stop() async {
    if (_process != null) {
      Logger.tuic.info('Stopping TUIC...');
      final process = _process!;
      _process = null;
      
      process.kill();
      
      try {
        await process.exitCode.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            Logger.tuic.warning('TUIC did not exit gracefully, force killing...');
            process.kill(ProcessSignal.sigkill);
            return -1;
          },
        );
      } catch (e) {
        Logger.tuic.warning('Error waiting for TUIC exit: $e');
      }
    }
    _isRunning = false;
    _lastError = null;
    try {
      final configPath = await getConfigPath();
      final configFile = File(configPath);
      if (await FileSystemEntity.type(configPath) != FileSystemEntityType.notFound) {
        await configFile.delete();
      }
    } catch (_) {}
  }

  // Parse TUIC URI and extract config
  // Format: tuic://uuid:password@host:port?params#name
  static Map<String, dynamic>? parseUri(String uri) {
    if (!uri.startsWith('tuic://')) return null;

    try {
      final withoutScheme = uri.substring(7);
      final fragmentIndex = withoutScheme.indexOf('#');

      String mainPart;
      String? remark;

      if (fragmentIndex != -1) {
        mainPart = withoutScheme.substring(0, fragmentIndex);
        remark = Uri.decodeComponent(withoutScheme.substring(fragmentIndex + 1));
      } else {
        mainPart = withoutScheme;
      }

      final atIndex = mainPart.indexOf('@');
      if (atIndex == -1) return null;

      final userInfo = mainPart.substring(0, atIndex);
      final rest = mainPart.substring(atIndex + 1);
      final colonIndex = userInfo.indexOf(':');
      String uuid;
      String password;

      if (colonIndex != -1) {
        uuid = userInfo.substring(0, colonIndex);
        password = userInfo.substring(colonIndex + 1);
      } else {
        uuid = userInfo;
        password = '';
      }

      final queryIndex = rest.indexOf('?');
      String hostPort;
      var params = <String, String>{};

      if (queryIndex != -1) {
        hostPort = rest.substring(0, queryIndex);
        final queryString = rest.substring(queryIndex + 1);
        params = Uri.splitQueryString(queryString);
      } else {
        hostPort = rest;
      }
      String host;
      int port;

      if (hostPort.startsWith('[')) {
        final closeBracket = hostPort.indexOf(']');
        host = hostPort.substring(1, closeBracket);
        final portPart = hostPort.substring(closeBracket + 1);
        port = portPart.startsWith(':') ? int.parse(portPart.substring(1)) : 443;
      } else {
        final colonIdx = hostPort.lastIndexOf(':');
        if (colonIdx != -1) {
          host = hostPort.substring(0, colonIdx);
          port = int.parse(hostPort.substring(colonIdx + 1));
        } else {
          host = hostPort;
          port = 443;
        }
      }

      final sni = params['sni'] ?? '';
      final alpn = params['alpn']?.split(',') ?? ['h3'];
      final congestionControl = params['congestion_control'] ?? params['cc'] ?? 'bbr';
      final udpRelayMode = params['udp_relay_mode'] ?? 'native';
      final disableSni = params['disable_sni'] == '1';
      final insecure = params['allowInsecure'] == '1' || params['insecure'] == '1';

      return {
        'server': host,
        'port': port,
        'uuid': uuid,
        'password': password,
        'sni': sni.isNotEmpty ? sni : host,
        'alpn': alpn,
        'congestionControl': congestionControl,
        'udpRelayMode': udpRelayMode,
        'disableSni': disableSni,
        'insecure': insecure,
        'remark': remark ?? 'TUIC',
        'protocol': 'tuic',
      };
    } catch (e) {
      Logger.tuic.error('Failed to parse TUIC URI: $e');
      return null;
    }
  }
}
