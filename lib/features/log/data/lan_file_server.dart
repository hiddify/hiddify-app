import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:hiddify/features/profile/add/phone_import/phone_import_server.dart' show isLocalNetwork;
import 'package:path/path.dart' as p;

/// One file, offered for download on the local network: how an Android TV, which has no share
/// sheet worth the name, hands a log or a diagnostics zip to a phone that scans its QR code.
///
/// It listens on the TV's address on the local network only, at a random port, and serves the file
/// only at a random secret path, which the QR code carries; anything else gets 404. The secret is
/// never typed, so it is long enough that it can not be guessed. Only devices on a local network
/// are served, and a request must name this server in its Host, so a web page can not reach it by
/// rebinding its own name. It serves until [close], which the dialog showing the code calls.
class LanFileServer {
  LanFileServer._(this._server, this._file, this._token);

  final HttpServer _server;
  final File _file;
  final String _token;
  final _downloads = StreamController<InternetAddress>.broadcast();

  static Future<LanFileServer> start(InternetAddress address, File file) async {
    final server = await HttpServer.bind(address, 0);
    server.autoCompress = false;
    server.idleTimeout = const Duration(seconds: 30);
    final files = LanFileServer._(server, file, _newToken());
    server.listen(files._handle, onError: (_) {});
    return files;
  }

  /// The file's address, with its secret: what the QR code shows.
  Uri get url => Uri(
    scheme: 'http',
    host: _server.address.address,
    port: _server.port,
    pathSegments: [_token, p.basename(_file.path)],
  );

  /// The device of each download that went through to the end.
  Stream<InternetAddress> get downloads => _downloads.stream;

  Future<void> close() async {
    await _server.close(force: true);
    await _downloads.close();
  }

  static String _newToken() {
    final random = Random.secure();
    return base64Url.encode(List.generate(18, (_) => random.nextInt(256)));
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      final remote = request.connectionInfo?.remoteAddress;
      if (remote == null ||
          !isLocalNetwork(remote) ||
          request.headers.value(HttpHeaders.hostHeader)?.toLowerCase() != url.authority.toLowerCase() ||
          request.uri.pathSegments.firstOrNull != _token) {
        return await _plain(response, HttpStatus.notFound, 'Not found');
      }
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
        return await _plain(response, HttpStatus.methodNotAllowed, 'Method not allowed');
      }
      final name = p.basename(_file.path);
      response.headers
        ..contentType = _contentType(name)
        ..contentLength = await _file.length()
        ..set('Content-Disposition', 'attachment; filename="${name.replaceAll('"', '')}"');
      _secure(response);
      if (request.method == 'HEAD') return await response.close();
      await response.addStream(_file.openRead());
      await response.close();
      if (!_downloads.isClosed) _downloads.add(remote);
    } catch (_) {
      try {
        await _plain(response, HttpStatus.internalServerError, 'Error');
      } catch (_) {}
    }
  }

  static ContentType _contentType(String name) => switch (p.extension(name).toLowerCase()) {
    '.zip' => ContentType('application', 'zip'),
    '.txt' || '.log' => ContentType.text,
    _ => ContentType.binary,
  };

  Future<void> _plain(HttpResponse response, int status, String message) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.text;
    _secure(response);
    response.write(message);
    await response.close();
  }

  static void _secure(HttpResponse response) {
    response.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Referrer-Policy', 'no-referrer');
  }
}
