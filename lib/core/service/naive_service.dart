import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class NaiveService {
  Process? _process;
  bool _isRunning = false;
  String? _lastError;
  int _localSocksPort = 10814;
  static const String _naiveVersion = '130.0.6723.40-1';
  static const List<String> _downloadUrls = [
    'https://github.com/klzgrad/naiveproxy/releases/download/v$_naiveVersion/naiveproxy-v$_naiveVersion-win-x64.zip',
    'https://ghproxy.com/https://github.com/klzgrad/naiveproxy/releases/download/v$_naiveVersion/naiveproxy-v$_naiveVersion-win-x64.zip',
  ];

  bool get isRunning => _isRunning;
  String? get lastError => _lastError;
  int get localSocksPort => _localSocksPort;

  Future<String> getNaivePath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'naive.exe');
  }

  Future<String> getConfigPath() async {
    final exePath = Platform.resolvedExecutable;
    final exeDir = p.dirname(exePath);
    return p.join(exeDir, 'naive-config.json');
  }

  Future<bool> isNaiveAvailable() async {
    final path = await getNaivePath();
    final file = File(path);
    return file.existsSync();
  }

  Future<void> downloadNaive({void Function(double)? onProgress}) async {
    final naivePath = await getNaivePath();

    for (final url in _downloadUrls) {
      try {
        Logger.naive.info('Downloading NaïveProxy from $url');

        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(url));
          final response = await client.send(request);

          if (response.statusCode != 200) {
            Logger.naive.warning(
              'Failed to download from $url: ${response.statusCode}',
            );
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
            if (file.name.endsWith('naive.exe')) {
              final data = file.content as List<int>;
              final outFile = File(naivePath);
              await outFile.writeAsBytes(data);
              Logger.naive.info('NaïveProxy extracted to $naivePath');
              return;
            }
          }

          throw Exception('naive.exe not found in archive');
        } finally {
          client.close();
        }
      } catch (e) {
        Logger.naive.warning('Failed to download NaïveProxy from $url: $e');
        continue;
      }
    }

    throw Exception('Failed to download NaïveProxy from all sources');
  }

  Future<void> generateConfig({
    required String username,
    required String password,
    required String host,
    required int port,
    String scheme = 'https',
    String? sni,
    bool insecure = false,
  }) async {
    final configPath = await getConfigPath();
    final proxyUrl =
        '$scheme://${Uri.encodeComponent(username)}:${Uri.encodeComponent(password)}@$host:$port';

    final config = <String, dynamic>{
      'listen': 'socks://127.0.0.1:$_localSocksPort',
      'proxy': proxyUrl,
      'log': '',
    };
    if (sni != null && sni.isNotEmpty && sni != host) {
      config['host-resolver-rules'] = 'MAP $sni $host';
    }
    if (insecure) {
      config['insecure-concurrency'] = 1;
    }

    await File(configPath).writeAsString(jsonEncode(config));
    Logger.naive.info('NaïveProxy config generated at $configPath');
  }

  Future<String?> start({
    required String username,
    required String password,
    required String host,
    required int port,
    String scheme = 'https',
    String? sni,
    bool insecure = false,
    int localPort = 10814,
  }) async {
    if (_isRunning) {
      Logger.naive.warning('NaïveProxy is already running');
      return null;
    }

    _localSocksPort = localPort;
    if (!await isNaiveAvailable()) {
      Logger.naive.info('NaïveProxy not found, downloading...');
      try {
        await downloadNaive();
      } catch (e) {
        return _lastError = 'Failed to download NaïveProxy: $e';
      }
    }
    try {
      await generateConfig(
        username: username,
        password: password,
        host: host,
        port: port,
        scheme: scheme,
        sni: sni,
        insecure: insecure,
      );
    } catch (e) {
      return _lastError = 'Failed to generate config: $e';
    }

    final naivePath = await getNaivePath();
    final configPath = await getConfigPath();

    Logger.naive.info('Starting NaïveProxy: $naivePath $configPath');

    try {
      _process = await Process.start(naivePath, [configPath]);

      _isRunning = true;
      _lastError = null;
      _process!.stdout.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            Logger.naive.debug('[stdout] $line');
          }
        }
      });
      _process!.stderr.transform(utf8.decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) {
            if (line.contains('ERROR') || line.contains('error')) {
              Logger.naive.warning('[stderr] $line');
              _lastError = line;
            } else {
              Logger.naive.debug('[stdout] $line');
            }
          }
        }
      });
      unawaited(
        _process!.exitCode.then((code) {
          Logger.naive.info('NaïveProxy exited with code: $code');
          _isRunning = false;
          if (code != 0) {
            _lastError = 'NaïveProxy exited with code $code';
          }
        }),
      );
      await Future<void>.delayed(const Duration(seconds: 2));

      if (!_isRunning) {
        return _lastError ?? 'NaïveProxy failed to start';
      }

      Logger.naive.info(
        'NaïveProxy started successfully on port $_localSocksPort',
      );
      return null;
    } catch (e) {
      _lastError = 'Failed to start NaïveProxy: $e';
      Logger.naive.error(_lastError);
      _isRunning = false;
      return _lastError;
    }
  }

  Future<void> stop() async {
    if (_process != null) {
      Logger.naive.info('Stopping NaïveProxy...');
      final process = _process!;
      _process = null;

      process.kill();

      try {
        await process.exitCode.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            Logger.naive.warning(
              'NaïveProxy did not exit gracefully, force killing...',
            );
            process.kill(ProcessSignal.sigkill);
            return -1;
          },
        );
      } catch (e) {
        Logger.naive.warning('Error waiting for NaïveProxy exit: $e');
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
    final isNaiveHttps = uri.startsWith('naive+https://');
    final isNaiveQuic = uri.startsWith('naive+quic://');
    final isNaivePlain = uri.startsWith('naive://');

    if (!isNaiveHttps && !isNaiveQuic && !isNaivePlain) return null;

    try {
      String scheme;
      String withoutScheme;

      if (isNaiveHttps) {
        scheme = 'https';
        withoutScheme = uri.substring(14);
      } else if (isNaiveQuic) {
        scheme = 'quic';
        withoutScheme = uri.substring(13);
      } else {
        scheme = 'https';
        withoutScheme = uri.substring(8);
      }

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

      final atIndex = mainPart.lastIndexOf('@');
      if (atIndex == -1) return null;

      final userInfo = mainPart.substring(0, atIndex);
      final rest = mainPart.substring(atIndex + 1);
      final colonIndex = userInfo.indexOf(':');
      String username;
      String password;

      if (colonIndex != -1) {
        username = Uri.decodeComponent(userInfo.substring(0, colonIndex));
        password = Uri.decodeComponent(userInfo.substring(colonIndex + 1));
      } else {
        username = Uri.decodeComponent(userInfo);
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
        port = portPart.startsWith(':')
            ? int.parse(portPart.substring(1))
            : 443;
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
      final insecure =
          params['insecure'] == '1' || params['allowInsecure'] == '1';

      return {
        'host': host,
        'port': port,
        'username': username,
        'password': password,
        'scheme': scheme,
        'sni': sni.isNotEmpty ? sni : host,
        'insecure': insecure,
        'remark': remark ?? 'NaïveProxy',
        'protocol': 'naive',
      };
    } catch (e) {
      Logger.naive.error('Failed to parse Naive URI: $e');
      return null;
    }
  }
}
