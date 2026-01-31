import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class ShadowsocksRService {
  Process? _process;
  bool _isRunning = false;
  String? _lastError;
  int _localSocksPort = 10812;
  static const String _ssrVersion = '3.2.3';
  static const List<String> _downloadUrls = [
    'https://github.com/nicholascw/ShadowsocksR-Windows/releases/download/v$_ssrVersion/ssr-native-windows-x86_64.zip',
    'https://github.com/ShadowsocksR-Live/shadowsocksr-native/releases/latest/download/ssr-native-windows-x86_64.zip',
  ];

  bool get isRunning => _isRunning;
  String? get lastError => _lastError;
  int get localSocksPort => _localSocksPort;

  Future<String> getSsrPath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'ssr-local.exe');
  }

  Future<String> getConfigPath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'ssr-config.json');
  }

  Future<bool> isSsrAvailable() async {
    final path = await getSsrPath();
    final file = File(path);
    return file.existsSync();
  }

  Future<void> downloadSsr({void Function(double)? onProgress}) async {
    final ssrPath = await getSsrPath();

    
    for (final url in _downloadUrls) {
      try {
        Logger.ssr.info('Downloading ShadowsocksR from $url');
        
        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(url));
          final response = await client.send(request);
          
          if (response.statusCode != 200) {
            Logger.ssr.warning('Failed to download from $url: ${response.statusCode}');
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
          final archive = ZipDecoder().decodeBytes(bytes);
          
          for (final file in archive) {
            if (file.name.endsWith('ssr-local.exe') || 
                file.name.endsWith('ssr-native.exe') ||
                file.name.contains('ssr') && file.name.endsWith('.exe')) {
              final data = file.content as List<int>;
              final outFile = File(ssrPath);
              await outFile.writeAsBytes(data);
              Logger.ssr.info('ShadowsocksR extracted to $ssrPath');
              return;
            }
          }
          for (final file in archive) {
            if (file.isFile && file.name.endsWith('.exe')) {
              final data = file.content as List<int>;
              final outFile = File(ssrPath);
              await outFile.writeAsBytes(data);
              Logger.ssr.info('ShadowsocksR extracted to $ssrPath');
              return;
            }
          }

          throw Exception('No SSR executable found in archive');
        } finally {
          client.close();
        }
      } catch (e) {
        Logger.ssr.warning('Failed to download SSR from $url: $e');
        continue;
      }
    }

    throw Exception('Failed to download ShadowsocksR from all sources');
  }

  Future<void> generateConfig({
    required String server,
    required int port,
    required String password,
    required String method,
    required String protocol,
    required String protocolParam,
    required String obfs,
    required String obfsParam,
  }) async {
    final configPath = await getConfigPath();
    
    final config = <String, dynamic>{
      'server': server,
      'server_port': port,
      'password': password,
      'method': method,
      'protocol': protocol,
      'protocol_param': protocolParam,
      'obfs': obfs,
      'obfs_param': obfsParam,
      'local_address': '127.0.0.1',
      'local_port': _localSocksPort,
      'timeout': 300,
      'udp_timeout': 60,
      'fast_open': false,
    };
    
    await File(configPath).writeAsString(jsonEncode(config));
    Logger.ssr.info('SSR config generated at $configPath');
  }

  Future<String?> start({
    required String server,
    required int port,
    required String password,
    required String method,
    required String protocol,
    required String protocolParam,
    required String obfs,
    required String obfsParam,
    int localPort = 10812,
  }) async {
    if (_isRunning) {
      Logger.ssr.warning('ShadowsocksR is already running');
      return null;
    }

    _localSocksPort = localPort;
    if (!await isSsrAvailable()) {
      Logger.ssr.info('ShadowsocksR not found, downloading...');
      try {
        await downloadSsr();
      } catch (e) {
        return _lastError = 'Failed to download ShadowsocksR: $e';
      }
    }
    try {
      await generateConfig(
        server: server,
        port: port,
        password: password,
        method: method,
        protocol: protocol,
        protocolParam: protocolParam,
        obfs: obfs,
        obfsParam: obfsParam,
      );
    } catch (e) {
      return _lastError = 'Failed to generate config: $e';
    }

    final ssrPath = await getSsrPath();
    final configPath = await getConfigPath();

    Logger.ssr.info('Starting ShadowsocksR: $ssrPath -c $configPath');

    try {
      _process = await Process.start(
        ssrPath,
        ['-c', configPath],
      );

      _isRunning = true;
      _lastError = null;
      _process!.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            Logger.ssr.debug('[stdout] $line');
          }
        }
      });
      _process!.stderr.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            Logger.ssr.warning('[stderr] $line');
            if (line.contains('error') || line.contains('failed')) {
              _lastError = line;
            }
          }
        }
      });
      unawaited(_process!.exitCode.then((code) {
        Logger.ssr.info('ShadowsocksR exited with code: $code');
        _isRunning = false;
        if (code != 0) {
          _lastError = 'ShadowsocksR exited with code $code';
        }
      }),);
      await Future<void>.delayed(const Duration(seconds: 1));

      if (!_isRunning) {
        return _lastError ?? 'ShadowsocksR failed to start';
      }

      Logger.ssr.info('ShadowsocksR started successfully on port $_localSocksPort');
      return null;
    } catch (e) {
      _lastError = 'Failed to start ShadowsocksR: $e';
      Logger.ssr.error(_lastError);
      _isRunning = false;
      return _lastError;
    }
  }

  // Stop SSR process
  Future<void> stop() async {
    if (_process != null) {
      Logger.ssr.info('Stopping ShadowsocksR...');
      final process = _process!;
      _process = null;
      
      process.kill();
      
      try {
        await process.exitCode.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            Logger.ssr.warning('ShadowsocksR did not exit gracefully, force killing...');
            process.kill(ProcessSignal.sigkill);
            return -1;
          },
        );
      } catch (e) {
        Logger.ssr.warning('Error waiting for ShadowsocksR exit: $e');
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



  static Map<String, dynamic>? parseUri(String uri) {
    if (!uri.startsWith('ssr://')) return null;

    try {
      final encoded = uri.substring(6);
      var decoded = encoded.replaceAll('-', '+').replaceAll('_', '/');
      final padding = decoded.length % 4;
      if (padding > 0) {
        decoded += '=' * (4 - padding);
      }
      
      final decodedBytes = base64Decode(decoded);
      final decodedStr = utf8.decode(decodedBytes);
      final paramsIndex = decodedStr.indexOf('/?');
      String mainPart;
      var params = <String, String>{};
      
      if (paramsIndex != -1) {
        mainPart = decodedStr.substring(0, paramsIndex);
        final queryString = decodedStr.substring(paramsIndex + 2);
        params = Uri.splitQueryString(queryString);
      } else {
        mainPart = decodedStr;
      }
      
      final parts = mainPart.split(':');
      if (parts.length < 6) return null;
      
      final host = parts[0];
      final port = int.parse(parts[1]);
      final protocol = parts[2];
      final method = parts[3];
      final obfs = parts[4];
      final passwordBase64 = parts[5];
      var pwDecoded = passwordBase64.replaceAll('-', '+').replaceAll('_', '/');
      final pwPadding = pwDecoded.length % 4;
      if (pwPadding > 0) {
        pwDecoded += '=' * (4 - pwPadding);
      }
      final password = utf8.decode(base64Decode(pwDecoded));
      var protocolParam = '';
      var obfsParam = '';
      String? remark;
      
      if (params.containsKey('protoparam')) {
        var protoDecoded = params['protoparam']!.replaceAll('-', '+').replaceAll('_', '/');
        final protoPadding = protoDecoded.length % 4;
        if (protoPadding > 0) {
          protoDecoded += '=' * (4 - protoPadding);
        }
        try {
          protocolParam = utf8.decode(base64Decode(protoDecoded));
        } catch (_) {
          protocolParam = params['protoparam']!;
        }
      }
      
      if (params.containsKey('obfsparam')) {
        var obfsDecoded = params['obfsparam']!.replaceAll('-', '+').replaceAll('_', '/');
        final obfsPadding = obfsDecoded.length % 4;
        if (obfsPadding > 0) {
          obfsDecoded += '=' * (4 - obfsPadding);
        }
        try {
          obfsParam = utf8.decode(base64Decode(obfsDecoded));
        } catch (_) {
          obfsParam = params['obfsparam']!;
        }
      }
      
      if (params.containsKey('remarks')) {
        var remarkDecoded = params['remarks']!.replaceAll('-', '+').replaceAll('_', '/');
        final remarkPadding = remarkDecoded.length % 4;
        if (remarkPadding > 0) {
          remarkDecoded += '=' * (4 - remarkPadding);
        }
        try {
          remark = utf8.decode(base64Decode(remarkDecoded));
        } catch (_) {
          remark = params['remarks'];
        }
      }

      return {
        'server': host,
        'port': port,
        'password': password,
        'method': method,
        'protocol': protocol,
        'protocolParam': protocolParam,
        'obfs': obfs,
        'obfsParam': obfsParam,
        'remark': remark ?? 'SSR',
        'protocol_type': 'shadowsocksr',
      };
    } catch (e) {
      Logger.ssr.error('Failed to parse SSR URI: $e');
      return null;
    }
  }
}
