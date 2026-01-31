import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class HysteriaService {
  Process? _process;
  bool _isRunning = false;
  String? _lastError;
  int _localSocksPort = 10808;

  static const String _hysteriaVersion = '2.6.1';
  static const String _downloadUrl =
      'https://github.com/apernet/hysteria/releases/download/app%2Fv$_hysteriaVersion/hysteria-windows-amd64.exe';
  static const String _hysteriaWindowsAmd64Sha256 =
      '99cb573049c8ae64c7e1584d5aa8b0b6cef58c2fa88bc7d7ffc3e3fb50241bc9';

  bool get isRunning => _isRunning;
  String? get lastError => _lastError;
  int get localSocksPort => _localSocksPort;

  Future<String> getHysteriaPath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'hysteria.exe');
  }

  Future<String> getConfigPath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'hysteria-config.yaml');
  }

  Future<bool> isHysteriaAvailable() async {
    final hysteriaPath = await getHysteriaPath();
    final configPath = await getConfigPath();

    Logger.hysteria.info('Starting Hysteria: $hysteriaPath -c $configPath');

    final file = File(hysteriaPath);
    if (await FileSystemEntity.type(hysteriaPath) ==
        FileSystemEntityType.notFound) {
      return false;
    }

    try {
      final digest = await sha256.bind(file.openRead()).first;
      if (digest.toString().toLowerCase() !=
          _hysteriaWindowsAmd64Sha256.toLowerCase()) {
        Logger.hysteria.warning(
          'Existing hysteria.exe SHA256 mismatch, re-downloading...',
        );
        await file.delete();
        return false;
      }
      return true;
    } catch (e) {
      Logger.hysteria.warning('Failed to verify hysteria.exe: $e');
      return false;
    }
  }

  Future<void> downloadHysteria({void Function(double)? onProgress}) async {
    final hysteriaPath = await getHysteriaPath();

    Logger.hysteria.info('Downloading Hysteria2 from $_downloadUrl');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(_downloadUrl));
      final response = await client.send(request);

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

      final digest = sha256.convert(bytes).toString();
      if (digest.toLowerCase() != _hysteriaWindowsAmd64Sha256.toLowerCase()) {
        throw Exception(
          'SHA256 mismatch for hysteria.exe. Expected: $_hysteriaWindowsAmd64Sha256, actual: $digest',
        );
      }

      final tmpPath = '$hysteriaPath.download';
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsBytes(bytes);

      final outFile = File(hysteriaPath);
      if (await FileSystemEntity.type(hysteriaPath) !=
          FileSystemEntityType.notFound) {
        await outFile.delete();
      }
      await tmpFile.rename(hysteriaPath);
      Logger.hysteria.info('Hysteria2 downloaded to $hysteriaPath');
    } catch (e) {
      Logger.hysteria.error('Failed to download Hysteria: $e');
      try {
        final tmpFile = File('$hysteriaPath.download');
        if (await FileSystemEntity.type('$hysteriaPath.download') !=
            FileSystemEntityType.notFound) {
          await tmpFile.delete();
        }
      } catch (_) {}
      rethrow;
    } finally {
      client.close();
    }
  }

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
    Logger.hysteria.info('Hysteria config generated at $configPath');
  }

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
      Logger.hysteria.warning('Hysteria is already running');
      return null;
    }

    _localSocksPort = localPort;
    if (!await isHysteriaAvailable()) {
      Logger.hysteria.info('Hysteria not found, downloading...');
      try {
        await downloadHysteria();
      } catch (e) {
        return _lastError = 'Failed to download Hysteria: $e';
      }
    }
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
      return _lastError = 'Failed to generate config: $e';
    }

    final hysteriaPath = await getHysteriaPath();
    final configPath = await getConfigPath();

    _process = await Process.start(hysteriaPath, ['-c', configPath]);

    _isRunning = true;
    _lastError = null;
    _process!.stdout.transform(utf8.decoder).listen((data) {
      for (final line in data.split('\n')) {
        if (line.trim().isNotEmpty) {
          Logger.hysteria.info('[hysteria] $line');
          if (line.contains('connected to server')) {
            Logger.hysteria.info('Hysteria connected successfully');
          }
        }
      }
    });
    _process!.stderr.transform(utf8.decoder).listen((data) {
      for (final line in data.split('\n')) {
        if (line.trim().isNotEmpty) {
          Logger.hysteria.warning('[hysteria] $line');
          if (line.contains('error') || line.contains('failed')) {
            _lastError = line;
          }
        }
      }
    });
    unawaited(
      _process!.exitCode.then((code) {
        Logger.hysteria.info('Hysteria exited with code: $code');
        _isRunning = false;
        if (code != 0) {
          _lastError = 'Hysteria exited with code $code';
        }
      }),
    );
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!_isRunning) {
      return _lastError ?? 'Hysteria failed to start';
    }

    Logger.hysteria.info(
      'Hysteria started successfully on port $_localSocksPort',
    );
    return null;
  }

  
  Future<void> stop() async {
    if (_process != null) {
      Logger.hysteria.info('Stopping Hysteria...');
      final process = _process!;
      _process = null;

      process.kill();
      try {
        await process.exitCode.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            Logger.hysteria.warning(
              'Hysteria did not exit gracefully, force killing...',
            );
            process.kill();
            return -1;
          },
        );
      } catch (e) {
        Logger.hysteria.warning('Error waiting for Hysteria exit: $e');
      }
    }
    _isRunning = false;
    _lastError = null;
    try {
      final configPath = await getConfigPath();
      final configFile = File(configPath);
      if (await FileSystemEntity.type(configPath) !=
          FileSystemEntityType.notFound) {
        await configFile.delete();
      }
    } catch (_) {}
  }

  
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
        remark = Uri.decodeComponent(
          withoutScheme.substring(fragmentIndex + 1),
        );
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
      String host;
      int port;

      if (hostPort.startsWith('[')) {
        final closeBracket = hostPort.indexOf(']');
        host = hostPort.substring(1, closeBracket);
        final portPart = hostPort.substring(closeBracket + 1);
        port = portPart.startsWith(':')
            ? int.parse(portPart.substring(1))
            : 443;
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
      final insecure =
          params['insecure'] == '1' || params['allowInsecure'] == '1';
      final obfs = params['obfs'] ?? '';
      final obfsPassword = params['obfs-password'] ?? '';
      final upMbps =
          int.tryParse(params['up'] ?? params['upmbps'] ?? '') ?? 100;
      final downMbps =
          int.tryParse(params['down'] ?? params['downmbps'] ?? '') ?? 100;

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
      Logger.hysteria.error('Failed to parse Hysteria URI: $e');
      return null;
    }
  }
}
