import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/model/download_problem.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/gen/translations.g.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

/// The subscription is downloaded in the core first, and here only when the core fails.
void main() {
  late HttpServer server;
  late Directory dir;
  late String tempFilePath;
  var directRequests = 0;

  setUp(() async {
    directRequests = 0;
    dir = await Directory.systemTemp.createTemp('profile_download');
    tempFilePath = '${dir.path}/profile.tmp';
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      directRequests++;
      switch (request.uri.path) {
        case '/ok':
          request.response.headers.set('profile-title', 'direct');
          request.response.write('vless://direct');
        case '/unavailable':
          // a status the retry interceptor retries
          request.response.statusCode = HttpStatus.serviceUnavailable;
        default:
          request.response.statusCode = HttpStatus.forbidden;
      }
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await dir.delete(recursive: true);
  });

  String url(String path) => 'http://127.0.0.1:${server.port}$path';

  ProfileParser parser(CoreFetch? coreFetch) => ProfileParser(
    httpClient: DioHttpClient(timeout: const Duration(seconds: 5), userAgent: 'HiddifyTest/1', debug: false),
    coreFetch: coreFetch,
  );

  FetchUrlResponse coreResponse({int status = 200}) => FetchUrlResponse(
    statusCode: status,
    headers: [HttpHeader(name: 'profile-title', value: 'core')],
    body: 'vless://core'.codeUnits,
  );

  Future<String> addRemote(ProfileParser parser, String link) async {
    final result = await parser.addRemote(id: '1', url: link, tempFilePath: tempFilePath, userOverride: null).run();
    return result.match((failure) => throw failure, (entry) => entry.name.value);
  }

  test('the core downloads it, with the app user agent, and nothing is downloaded here', () async {
    String? sentUserAgent;
    final name = await addRemote(
      parser((link, userAgent, {required cancel}) async {
        sentUserAgent = userAgent;
        return coreResponse();
      }),
      url('/ok'),
    );
    expect(name, 'core');
    expect(sentUserAgent, 'HiddifyTest/1');
    expect(File(tempFilePath).readAsStringSync(), 'vless://core');
    expect(directRequests, 0);
  });

  test('when the core fails, it is downloaded here', () async {
    final name = await addRemote(
      parser((link, userAgent, {required cancel}) async => throw StateError('core failed')),
      url('/ok'),
    );
    expect(name, 'direct');
    expect(File(tempFilePath).readAsStringSync(), 'vless://direct');
  });

  test('a core response other than 2xx counts as a failure', () async {
    final name = await addRemote(
      parser((link, userAgent, {required cancel}) async => coreResponse(status: 404)),
      url('/ok'),
    );
    expect(name, 'direct');
  });

  Future<ProfileFailure> failure(CoreFetch? coreFetch, String link, {DownloadRetryCallback? onRetry}) async {
    final result = await parser(
      coreFetch,
    ).addRemote(id: '1', url: link, tempFilePath: tempFilePath, userOverride: null, onRetry: onRetry).run();
    return result.match((failure) => failure, (_) => throw StateError('expected a failure'));
  }

  test('a failure that may pass is tried twice, telling of the first, without the http retries', () async {
    final retries = <(DownloadProblem, int, int)>[];
    var coreCalls = 0;
    final watch = Stopwatch()..start();
    final err = await failure(
      (link, userAgent, {required cancel}) {
        coreCalls++;
        return Future.error(StateError('core failed'));
      },
      url('/unavailable'),
      onRetry: (failure, next, of) => retries.add((failure.problem, next, of)),
    );
    expect(watch.elapsed, lessThan(const Duration(milliseconds: 1900)));
    expect(coreCalls, 2);
    expect(directRequests, 2);
    expect(retries, [(DownloadProblem.serverError, 2, 2)]);
    expect(err, isA<ProfileDownloadFailure>());
    final download = err as ProfileDownloadFailure;
    expect(download.problem, DownloadProblem.serverError);
    expect(download.statusCode, 503);
    expect(download.detail, 'core: unavailable\napp: HTTP 503');
  });

  test('a failure that will not pass is not tried again', () async {
    var retried = false;
    final err = await failure(null, url('/denied'), onRetry: (_, _, _) => retried = true);
    expect((err as ProfileDownloadFailure).problem, DownloadProblem.denied);
    expect(retried, isFalse);
    expect(directRequests, 1);
  });

  test('an answer from the server tells more than a cut connection', () async {
    final err = await failure(
      (link, userAgent, {required cancel}) async => FetchUrlResponse(
        error: FetchUrlError.FETCH_URL_ERROR_RESET,
        errorDetail: 'tls handshake: read: connection reset by peer',
      ),
      url('/denied'),
    );
    final download = err as ProfileDownloadFailure;
    expect(download.problem, DownloadProblem.denied);
    expect(download.statusCode, 403);
    expect(download.detail, contains('connection reset by peer'));
  });

  test('a cut connection tells more than a refused one', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();
    final err = await failure(
      (link, userAgent, {required cancel}) async =>
          FetchUrlResponse(error: FetchUrlError.FETCH_URL_ERROR_RESET, errorDetail: 'connection reset by peer'),
      'http://127.0.0.1:$port/sub',
    );
    expect((err as ProfileDownloadFailure).problem, DownloadProblem.reset);
  });

  test('a refused connection here is told as such', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();
    final err = await failure(null, 'http://127.0.0.1:$port/sub?token=secret');
    final download = err as ProfileDownloadFailure;
    expect(download.problem, DownloadProblem.refused);
    expect(download.detail, isNot(contains('secret')));
  });

  test('the dialog says what happened, what to do, and the details', () {
    final t = AppLocale.en.buildSync();
    final shown = const ProfileFailure.download(
      DownloadProblem.serverError,
      statusCode: 502,
      detail: 'core: HTTP 502',
    ).present(t);
    expect(shown.type, t.errors.download.serverError.title);
    expect(shown.message, contains('502'));
    expect(shown.message, startsWith(t.errors.download.serverError.why(code: 502)));
    for (final tip in t.errors.download.serverError.tips) {
      expect(shown.message, contains('• $tip'));
    }
    expect(shown.message, endsWith('${t.errors.download.details}:\ncore: HTTP 502'));
  });

  test('cancelling stops the core download and does not fall back', () async {
    final token = CancelToken();
    final coreCancelled = Completer<void>();
    final result = parser((link, userAgent, {required cancel}) async {
      await cancel;
      coreCancelled.complete();
      throw StateError('cancelled');
    }).addRemote(id: '1', url: url('/ok'), tempFilePath: tempFilePath, userOverride: null, cancelToken: token).run();
    token.cancel();
    (await result).match(
      (failure) => expect(failure, isA<ProfileCancelByUserFailure>()),
      (_) => fail('expected a cancel'),
    );
    expect(coreCancelled.isCompleted, isTrue);
    expect(directRequests, 0);
  });

  test('without a core, it is downloaded here', () async {
    expect(await addRemote(parser(null), url('/ok')), 'direct');
  });
}
