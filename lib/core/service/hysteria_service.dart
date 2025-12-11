import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Service to manage Hysteria2 binary as external plugin
class HysteriaService {
  Process? _process;
  bool _isRunning = false;
  String? _lastError;
  int _localSocksPort = 10808;

  static const String _hysteriaVersion = '2.6.1';
  static const String _downloadUrl = 
      'https://github.com/apernet/hysteria/releases/download/app%2Fv$_hysteriaVersion/hysteria-windows-amd64.exe';

  bool get isRunning => _isRunning;
  String? get lastError => _lastError;
  int get localSocksPort => _localSocksPort;

  /// Get the Hysteria executable path
  Future<String> getHysteriaPath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'hysteria.exe');
  }

  /// Get the Hysteria config path
  Future<String> getConfigPath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'hysteria-config.yaml');
  }

  /// Check if Hysteria binary exists
  Future<bool> isHysteriaAvailable() async {
    final path = await getHysteriaPath();
    return File(path).existsSync();
  }

  /// Download Hysteria binary
  Future<void> downloadHysteria({void Function(double)? onProgress}) async {
    final hysteriaPath = await getHysteriaPath();
    
    Logger.app.info('Downloading Hysteria2 from $_downloadUrl');
    
    try {
      final request = http.Request('GET', Uri.parse(_downloadUrl));
      final response = await http.Client().send(request);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download Hysteria: ${response.statusCode}');
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

      await File(hysteriaPath).writeAsBytes(bytes);
      Logger.app.info('Hysteria2 downloaded to $hysteriaPath');
    } catch (e) {
      Logger.app.error('Failed to download Hysteria: $e');
      rethrow;
    }
  }

  /// Generate Hysteria config file
  Future<void> generateConfig({
    required String server,
    required int port,
    required String auth,
    String? sni,
    bool insecure = false,
    int upMbps = 100,
    int downMbps = 100,
    String? obfs,
    String? obfsPassword,
  }) async {
    final configPath = await getConfigPath();
    
    final config = StringBuffer()
      ..writeln('server: $server:$port')
      ..writeln('auth: $auth')
      ..writeln('bandwidth:')
      ..writeln('  up: $upMbps mbps')
      ..writeln('  down: $downMbps mbps')
      ..writeln('socks5:')
      ..writeln('  listen: 127.0.0.1:$_localSocksPort')
      ..writeln('http:')
      ..writeln('  listen: 127.0.0.1:${_localSocksPort + 1}');
    
    if (sni != null && sni.isNotEmpty) {
      config.writeln('tls:');
      config.writeln('  sni: $sni');
      if (insecure) {
        config.writeln('  insecure: true');
      }
    }
    
    if (obfs != null && obfs.isNotEmpty) {
      config.writeln('obfs:');
      config.writeln('  type: $obfs');
      if (obfsPassword != null && obfsPassword.isNotEmpty) {
        config.writeln('  salamander:');
        config.writeln('    password: $obfsPassword');
      }
    }
    
    await File(configPath).writeAsString(config.toString());
    Logger.app.info('Hysteria config generated at $configPath');
  }

  /// Start Hysteria process
  Future<String?> start({
    required String server,
    required int port,
    required String auth,
    String? sni,
    bool insecure = false,
    int upMbps = 100,
    int downMbps = 100,
    String? obfs,
    String? obfsPassword,
    int localPort = 10808,
  }) async {
    if (_isRunning) {
      Logger.app.warning('Hysteria is already running');
      return null;
    }

    _localSocksPort = localPort;

    // Check if binary exists
    if (!await isHysteriaAvailable()) {
      Logger.app.info('Hysteria not found, downloading...');
      try {
        await downloadHysteria();
      } catch (e) {
        _lastError = 'Failed to download Hysteria: $e';
        return _lastError;
      }
    }

    // Generate config
    try {
      await generateConfig(
        server: server,
        port: port,
        auth: auth,
        sni: sni,
        insecure: insecure,
        upMbps: upMbps,
        downMbps: downMbps,
        obfs: obfs,
        obfsPassword: obfsPassword,
      );
    } catch (e) {
      _lastError = 'Failed to generate config: $e';
      return _lastError;
    }

    final hysteriaPath = await getHysteriaPath();
    final configPath = await getConfigPath();

    Logger.app.info('Starting Hysteria: $hysteriaPath -c $configPath');

    try {
      _process = await Process.start(
        hysteriaPath,
        ['-c', configPath],
        mode: ProcessStartMode.normal,
      );

      _isRunning = true;
      _lastError = null;

      // Listen to stdout
      _process!.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            Logger.app.info('[hysteria] $line');
            if (line.contains('connected to server')) {
              Logger.app.info('Hysteria connected successfully');
            }
          }
        }
      });

      // Listen to stderr
      _process!.stderr.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            Logger.app.warning('[hysteria] $line');
            if (line.contains('error') || line.contains('failed')) {
              _lastError = line;
            }
          }
        }
      });

      // Handle process exit
      unawaited(_process!.exitCode.then((code) {
        Logger.app.info('Hysteria exited with code: $code');
        _isRunning = false;
        if (code != 0) {
          _lastError = 'Hysteria exited with code $code';
        }
      }));

      // Wait for startup
      await Future<void>.delayed(const Duration(seconds: 2));

      if (!_isRunning) {
        return _lastError ?? 'Hysteria failed to start';
      }

      Logger.app.info('Hysteria started successfully on port $_localSocksPort');
      return null;
    } catch (e) {
      _lastError = 'Failed to start Hysteria: $e';
      Logger.app.error(_lastError!);
      _isRunning = false;
      return _lastError;
    }
  }

  /// Stop Hysteria process
  Future<void> stop() async {
    if (_process != null) {
      Logger.app.info('Stopping Hysteria...');
      _process!.kill();
      _process = null;
    }
    _isRunning = false;
    _lastError = null;

    // Also clean up config file
    try {
      final configPath = await getConfigPath();
      final configFile = File(configPath);
      if (await configFile.exists()) {
        await configFile.delete();
      }
    } catch (_) {}
  }

  /// Parse Hysteria URI and extract config
  static Map<String, dynamic>? parseUri(String uri) {
    final isHy2 = uri.startsWith('hy2://') || uri.startsWith('hysteria2://');
    final isHy1 = uri.startsWith('hysteria://');

    if (!isHy2 && !isHy1) return null;

    try {
      final schemeEnd = uri.indexOf('://') + 3;
      final withoutScheme = uri.substring(schemeEnd);
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

      final auth = Uri.decodeComponent(mainPart.substring(0, atIndex));
      final rest = mainPart.substring(atIndex + 1);

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

      // Parse host and port
      String host;
      int port;

      if (hostPort.startsWith('[')) {
        final closeBracket = hostPort.indexOf(']');
        host = hostPort.substring(1, closeBracket);
        final portPart = hostPort.substring(closeBracket + 1);
        port = portPart.startsWith(':') ? int.parse(portPart.substring(1)) : 443;
      } else {
        final colonIndex = hostPort.lastIndexOf(':');
        if (colonIndex != -1) {
          host = hostPort.substring(0, colonIndex);
          port = int.parse(hostPort.substring(colonIndex + 1));
        } else {
          host = hostPort;
          port = 443;
        }
      }

      final sni = params['sni'] ?? params['peer'] ?? '';
      final insecure = params['insecure'] == '1' || params['allowInsecure'] == '1';
      final obfs = params['obfs'] ?? '';
      final obfsPassword = params['obfs-password'] ?? '';
      final upMbps = int.tryParse(params['up'] ?? params['upmbps'] ?? '') ?? 100;
      final downMbps = int.tryParse(params['down'] ?? params['downmbps'] ?? '') ?? 100;

      return {
        'server': host,
        'port': port,
        'auth': auth,
        'sni': sni.isNotEmpty ? sni : host,
        'insecure': insecure,
        'up': upMbps,
        'down': downMbps,
        'obfs': obfs,
        'obfsPassword': obfsPassword,
        'remark': remark ?? 'Hysteria2',
        'protocol': isHy2 ? 'hysteria2' : 'hysteria',
      };
    } catch (e) {
      Logger.app.error('Failed to parse Hysteria URI: $e');
      return null;
    }
  }
}
