import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:hiddify/utils/custom_loggers.dart';

class DioHttpClient with InfraLogger {
  final Map<String, Dio> _dio = {};
  final Map<String, HttpClient> _httpClients = {};

  int port = 0;

  DioHttpClient({required Duration timeout, required String userAgent}) {
    for (final mode in ['proxy', 'direct', 'both']) {
      final dioInstance = Dio(
        BaseOptions(
          connectTimeout: timeout,
          sendTimeout: timeout,
          receiveTimeout: timeout,
          headers: {'User-Agent': userAgent},
        ),
      );

      dioInstance.interceptors.add(
        RetryInterceptor(
          dio: dioInstance,
          retryDelays: [
            const Duration(seconds: 1),
            if (mode != 'proxy') ...[
              const Duration(seconds: 2),
              const Duration(seconds: 3),
            ],
          ],
        ),
      );

      dioInstance.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final existing = _httpClients[mode];
          if (existing != null) return existing;

          final client = HttpClient();
          client.findProxy = (url) {
            if (mode == 'proxy') {
              return 'PROXY localhost:$port';
            } else if (mode == 'direct') {
              return 'DIRECT';
            } else {
              return 'PROXY localhost:$port; DIRECT';
            }
          };
          _httpClients[mode] = client;
          return client;
        },
      );

      _dio[mode] = dioInstance;
    }
  }

  Future<bool> isPortOpen(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      await socket.close();
      return true;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  void setProxyPort(int port) {
    this.port = port;
    loggy.debug('setting proxy port: [$port]');
  }

  Future<Response<T>> get<T>(
    String url, {
    CancelToken? cancelToken,
    String? userAgent,
    ({String username, String password})? credentials,
    bool proxyOnly = false,
    ResponseType? responseType,
  }) async {
    final mode = proxyOnly
        ? 'proxy'
        : await isPortOpen('127.0.0.1', port)
        ? 'both'
        : 'direct';

    final dio = _dio[mode]!;

    return dio.get<T>(
      url,
      cancelToken: cancelToken,
      options: _options(
        url,
        userAgent: userAgent,
        credentials: credentials,
        responseType: responseType,
      ),
    );
  }

  Future<Response<dynamic>> download(
    String url,
    String path, {
    CancelToken? cancelToken,
    String? userAgent,
    ({String username, String password})? credentials,
    bool proxyOnly = false,
  }) async {
    final mode = proxyOnly
        ? 'proxy'
        : await isPortOpen('127.0.0.1', port)
        ? 'both'
        : 'direct';

    final dio = _dio[mode]!;

    return dio.download(
      url,
      path,
      cancelToken: cancelToken,
      options: _options(url, userAgent: userAgent, credentials: credentials),
    );
  }

  Options _options(
    String url, {
    String? userAgent,
    ({String username, String password})? credentials,
    ResponseType? responseType,
  }) {
    final uri = Uri.parse(url);

    String? userInfo;
    if (credentials != null) {
      userInfo = '${credentials.username}:${credentials.password}';
    } else if (uri.userInfo.isNotEmpty) {
      userInfo = uri.userInfo;
    }

    String? basicAuth;
    if (userInfo != null) {
      basicAuth = 'Basic ${base64.encode(utf8.encode(userInfo))}';
    }

    return Options(
      responseType: responseType,
      headers: {
        if (userAgent != null) 'User-Agent': userAgent,
        if (basicAuth != null) 'authorization': basicAuth,
      },
    );
  }

  void close() {
    for (final client in _httpClients.values) {
      try {
        client.close(force: true);
      } catch (_) {}
    }
    _httpClients.clear();
  }
}
