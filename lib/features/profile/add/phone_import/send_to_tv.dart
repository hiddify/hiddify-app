import 'dart:async';
import 'dart:io';

import 'package:hiddify/features/profile/add/phone_import/phone_import_server.dart';

/// How sending a link to a TV went.
enum SendToTvResult {
  sent,

  /// The scanned code is not the one Hiddify shows on a TV.
  notTvCode,

  /// The TV answered, but no longer takes links at this code: its sheet was closed, or locked.
  expired,

  /// The TV has too many links waiting to be imported.
  busy,

  /// The TV could not be reached: another network, or it is gone.
  unreachable,
}

/// The page address in a code scanned from a TV's add profile sheet ([PhoneImportServer.url]), or
/// null for any other code. Only such an address is ever sent to: any other request counts as a
/// wrong try against the TV's lock.
Uri? parseTvImportCode(String scanned) {
  final uri = Uri.tryParse(scanned.trim());
  if (uri == null || uri.scheme != 'http' || !uri.hasPort || uri.hasQuery || uri.hasFragment) return null;
  if (uri.userInfo.isNotEmpty) return null;
  final address = InternetAddress.tryParse(uri.host);
  if (address == null || !isLocalNetwork(address)) return null;
  if (!RegExp('^/[0-9]{${PhoneImportServer.tokenLength}}\$').hasMatch(uri.path)) return null;
  return uri;
}

/// Sends [link] to the TV page that [scanned] points to, as its form would.
Future<SendToTvResult> sendLinkToTv(String scanned, String link) async {
  final url = parseTvImportCode(scanned);
  if (url == null) return SendToTvResult.notTvCode;
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 8)
    ..findProxy = (_) => 'DIRECT';
  try {
    final request = await client.postUrl(url).timeout(const Duration(seconds: 10));
    request
      ..followRedirects = false
      ..headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8')
      ..write(Uri(queryParameters: {'link': link}).query);
    final response = await request.close().timeout(const Duration(seconds: 10));
    await response.drain<void>();
    return switch (response.statusCode) {
      // the page sends the browser back to itself once it took the link
      HttpStatus.seeOther || HttpStatus.ok => SendToTvResult.sent,
      HttpStatus.tooManyRequests => SendToTvResult.busy,
      HttpStatus.notFound => SendToTvResult.expired,
      _ => SendToTvResult.unreachable,
    };
  } on SocketException {
    return SendToTvResult.unreachable;
  } on TimeoutException {
    return SendToTvResult.unreachable;
  } on HttpException {
    return SendToTvResult.unreachable;
  } finally {
    client.close(force: true);
  }
}
