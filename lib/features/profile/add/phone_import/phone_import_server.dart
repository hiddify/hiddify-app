import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:hiddify/features/profile/add/phone_import/phone_import_page.dart';

export 'package:hiddify/features/profile/add/phone_import/phone_import_page.dart'
    show PhoneImportPageText, PhoneImportStep;

/// What a phone sent: a subscription link or a config, waiting for the TV user to import it.
class PhoneEntry {
  PhoneEntry({required this.text, required this.from, required this.at});

  final String text;
  final InternetAddress from;
  final DateTime at;
}

/// A one-time page on the local network where a phone can send a subscription link to this TV.
///
/// It listens on the TV's address on the local network only, at a random port, and answers only
/// at a random secret path, which the QR code carries: a device that has not scanned the code
/// gets 404, as for any other path. The secret is a code of [tokenLength] digits, easy to type,
/// which is enough because it can hardly be guessed: after [maxMisses] wrong tries, from any
/// devices together, the page locks for good, and the TV offers a new code once the sheet is
/// opened again. Only devices on a local network are served, a request must name this server in
/// its Host (so a web page can not reach it by rebinding its own name), and a text larger than
/// [maxText] bytes is refused. The page needs no script. What the phone sends is only offered to
/// the TV user, never imported by itself.
class PhoneImportServer {
  PhoneImportServer._(this._server, this._token, this._text);

  static const tokenLength = 6;

  /// Wrong tries, from all devices together, before the page locks: 10 in a million.
  static const maxMisses = 10;

  static const maxText = 64 * 1024;

  /// Most entries waiting on the TV at once; more are refused until some are dealt with.
  static const maxPending = 20;

  final HttpServer _server;
  final String _token;
  final PhoneImportPageText _text;
  final _entries = StreamController<PhoneEntry>.broadcast();
  final _locked = Completer<void>();
  var _misses = 0;
  var _pending = 0;

  /// Starts serving on [address], which must be this device's address on the local network.
  static Future<PhoneImportServer> start(InternetAddress address, PhoneImportPageText text) async {
    final server = await HttpServer.bind(address, 0);
    server.autoCompress = false;
    server.idleTimeout = const Duration(seconds: 30);
    final import = PhoneImportServer._(server, _newToken(), text);
    server.listen(import._handle, onError: (_) {});
    return import;
  }

  /// The page's address, with its secret: what the QR code shows.
  Uri get url => Uri(scheme: 'http', host: _server.address.address, port: _server.port, path: '/$_token');

  /// Each text a phone sends, as it arrives.
  Stream<PhoneEntry> get entries => _entries.stream;

  /// Completes when too many wrong tries locked the page.
  Future<void> get whenLocked => _locked.future;

  bool get isLocked => _locked.isCompleted;

  /// One entry was imported or discarded on the TV, so there is room for another.
  void handled() => _pending = max(0, _pending - 1);

  Future<void> close() async {
    await _server.close(force: true);
    await _entries.close();
  }

  static String _newToken() {
    final random = Random.secure();
    return List.generate(tokenLength, (_) => random.nextInt(10)).join();
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      final remote = request.connectionInfo?.remoteAddress;
      if (remote == null || !isLocalNetwork(remote) || isLocked) {
        return await _plain(response, HttpStatus.notFound, 'Not found');
      }
      if (!_isOwnHost(request) || !_isOwnPath(request.uri.path)) {
        // a browser asks for its icon by itself; that is no guess
        if (request.uri.path != '/favicon.ico' && ++_misses >= maxMisses) _locked.complete();
        return await _plain(response, HttpStatus.notFound, 'Not found');
      }
      switch (request.method) {
        case 'GET' || 'HEAD':
          return await _page(response, sent: request.uri.queryParameters.containsKey('sent'));
        case 'POST':
          return await _receive(request, remote);
        default:
          response.headers.set(HttpHeaders.allowHeader, 'GET, POST');
          return await _plain(response, HttpStatus.methodNotAllowed, 'Method not allowed');
      }
    } catch (_) {
      try {
        await _plain(response, HttpStatus.badRequest, 'Bad request');
      } catch (_) {}
    }
  }

  bool _isOwnHost(HttpRequest request) => request.headers.value(HttpHeaders.hostHeader)?.toLowerCase() == url.authority;

  /// The secret path, compared in constant time.
  bool _isOwnPath(String path) {
    final expected = '/$_token';
    if (path.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < path.length; i++) {
      diff |= path.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return diff == 0;
  }

  Future<void> _receive(HttpRequest request, InternetAddress remote) async {
    final response = request.response;
    final type = request.headers.contentType;
    if (type == null || type.mimeType != 'application/x-www-form-urlencoded') {
      return _plain(response, HttpStatus.unsupportedMediaType, 'Unsupported media type');
    }
    final length = request.headers.contentLength;
    if (length > maxText * 3) return _plain(response, HttpStatus.requestEntityTooLarge, 'Too large');
    final body = BytesBuilder(copy: false);
    await for (final chunk in request) {
      body.add(chunk);
      // a form encodes a byte as at most three
      if (body.length > maxText * 3) return _plain(response, HttpStatus.requestEntityTooLarge, 'Too large');
    }
    final String text;
    try {
      text = (Uri.splitQueryString(utf8.decode(body.takeBytes()))['link'] ?? '').trim();
    } on FormatException {
      return _plain(response, HttpStatus.badRequest, 'Bad request');
    }
    if (utf8.encode(text).length > maxText) return _plain(response, HttpStatus.requestEntityTooLarge, 'Too large');
    if (text.isEmpty) return _page(response, sent: false, status: HttpStatus.badRequest, error: _text.empty);
    if (_pending >= maxPending) return _plain(response, HttpStatus.tooManyRequests, 'Too many requests');
    _pending++;
    _entries.add(PhoneEntry(text: text, from: remote, at: DateTime.now()));
    // back to the page, so a reload does not send it again
    response.statusCode = HttpStatus.seeOther;
    response.headers.set(HttpHeaders.locationHeader, '/$_token?sent');
    _secure(response);
    await response.close();
  }

  Future<void> _page(HttpResponse response, {required bool sent, int status = HttpStatus.ok, String? error}) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.html;
    _secure(response);
    response.write(phoneImportPage(_text, action: '/$_token', maxText: maxText, sent: sent, error: error));
    await response.close();
  }

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
      ..set(
        'Content-Security-Policy',
        "default-src 'none'; style-src 'unsafe-inline'; form-action 'self'; frame-ancestors 'none'",
      )
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('X-Frame-Options', 'DENY')
      ..set('Referrer-Policy', 'no-referrer');
  }
}

/// Whether [address] is on a local network: private IPv4 (10/8, 172.16/12, 192.168/16), link-local,
/// unique-local IPv6 (fc00::/7) or loopback.
bool isLocalNetwork(InternetAddress address) {
  final ip = address.type == InternetAddressType.IPv6 && _isMappedIPv4(address.rawAddress)
      ? InternetAddress.fromRawAddress(address.rawAddress.sublist(12))
      : address;
  if (ip.isLoopback || ip.isLinkLocal) return true;
  final b = ip.rawAddress;
  if (ip.type == InternetAddressType.IPv4) {
    return b[0] == 10 || (b[0] == 172 && b[1] >= 16 && b[1] <= 31) || (b[0] == 192 && b[1] == 168);
  }
  return (b[0] & 0xfe) == 0xfc;
}

bool _isMappedIPv4(Uint8List b) =>
    b.length == 16 && b.sublist(0, 10).every((x) => x == 0) && b[10] == 0xff && b[11] == 0xff;
