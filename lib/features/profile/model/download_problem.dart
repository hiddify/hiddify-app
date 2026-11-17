import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

/// Why a subscription could not be downloaded, in terms a user can act on.
///
/// In the order of how much they tell: when the core and the app fail for different reasons, the
/// first one here is shown. An answer from the server says the most, so its problems come first.
enum DownloadProblem {
  /// 5xx: the provider's server is broken
  serverError,

  /// 404, 410: nothing at this link
  notFound,

  /// 401, 403: the provider refuses the link, an expired or disabled subscription
  denied,

  /// 429
  tooManyRequests,

  /// any other status that is not 2xx
  badStatus,

  /// the subscription is over the 16 MiB the core reads
  tooLarge,

  /// the device is offline
  noInternet,

  /// the server's name was not found: a typo, or a network that filters it
  dns,

  /// the server's certificate is not valid, or something on the network intercepts the connection
  certificate,

  /// the connection was cut while it was set up, often by a filter
  reset,

  /// the secure connection could not be set up
  tls,

  /// nothing listens at the server's address: it is down, or the link is wrong
  refused,

  /// no answer in time: the server is down, or the network drops its packets
  timeout,

  unknown;

  /// Whether trying again may help: not when the server said no, or its certificate is wrong.
  bool get mayPass => switch (this) {
    notFound || denied || badStatus || tooLarge || certificate => false,
    _ => true,
  };

  static DownloadProblem ofStatus(int code) => switch (code) {
    >= 500 => serverError,
    404 || 410 => notFound,
    401 || 403 => denied,
    429 => tooManyRequests,
    _ => badStatus,
  };

  /// The problem of a download in the core that failed, null when it did not.
  static DownloadProblem? ofCore(FetchUrlResponse response) => switch (response.error) {
    FetchUrlError.FETCH_URL_ERROR_NONE =>
      response.statusCode >= 200 && response.statusCode <= 299 ? null : ofStatus(response.statusCode),
    FetchUrlError.FETCH_URL_ERROR_TIMEOUT => timeout,
    FetchUrlError.FETCH_URL_ERROR_DNS => dns,
    FetchUrlError.FETCH_URL_ERROR_REFUSED => refused,
    FetchUrlError.FETCH_URL_ERROR_RESET => reset,
    FetchUrlError.FETCH_URL_ERROR_UNREACHABLE => noInternet,
    FetchUrlError.FETCH_URL_ERROR_TLS => tls,
    FetchUrlError.FETCH_URL_ERROR_CERTIFICATE => certificate,
    FetchUrlError.FETCH_URL_ERROR_TOO_LARGE => tooLarge,
    _ => unknown,
  };

  static DownloadProblem ofDio(DioException err) {
    if (err.response?.statusCode case final code? when code < 200 || code > 299) return ofStatus(code);
    switch (err.type) {
      case DioExceptionType.connectionTimeout || DioExceptionType.sendTimeout || DioExceptionType.receiveTimeout:
        return timeout;
      case DioExceptionType.badCertificate:
        return certificate;
      default:
    }
    final cause = err.error;
    if (cause is CertificateException) return certificate;
    final text = '${cause ?? ''} ${err.message ?? ''}'.toLowerCase();
    if (text.contains('certificate')) return certificate;
    if (text.contains('failed host lookup') || text.contains('nodename nor servname') || text.contains('no address')) {
      return dns;
    }
    if (text.contains('network is unreachable') || text.contains('no route to host')) return noInternet;
    if (text.contains('refused')) return refused;
    if (text.contains('reset by peer') ||
        text.contains('connection reset') ||
        text.contains('forcibly closed') ||
        text.contains('terminated during handshake') ||
        text.contains('broken pipe')) {
      return reset;
    }
    if (text.contains('timed out')) return timeout;
    if (cause is HandshakeException || cause is TlsException) return tls;
    return unknown;
  }

  /// The technical words for a failed download here, without its URL, which carries the user's token.
  static String detailOfDio(DioException err) {
    if (err.response?.statusCode case final code?) return 'HTTP $code';
    return switch (err.error) {
      final OSError e => '${e.message} (errno ${e.errorCode})',
      final SocketException e => [
        e.message,
        if (e.osError case final os?) '${os.message} (errno ${os.errorCode})',
      ].join(': '),
      final TlsException e => [e.type, e.message, if (e.osError case final os?) os.message].join(': '),
      final Object e => e.toString(),
      null => err.type.name,
    };
  }

  /// One problem for both downloads that failed: the one that tells the most.
  static DownloadProblem mostTelling(Iterable<DownloadProblem> problems) =>
      problems.fold(unknown, (a, b) => b.index < a.index ? b : a);

  /// The error number shown with every failure as "ERROR 403", for the user to quote to support:
  /// the HTTP status when the server answered, a short name otherwise.
  String code(int? status) => switch (this) {
    serverError || notFound || denied || tooManyRequests || badStatus => '${status ?? '?'}',
    tooLarge => 'TOO_LARGE',
    noInternet => 'NET_OFFLINE',
    dns => 'DNS_NOT_FOUND',
    certificate => 'TLS_CERT',
    reset => 'CONN_RESET',
    tls => 'TLS_FAILED',
    refused => 'CONN_REFUSED',
    timeout => 'NET_TIMEOUT',
    unknown => 'UNKNOWN',
  };

  /// How far the download got on its way from the device, over the internet, to the provider: the
  /// stop that failed (0 the device, 1 the internet, 2 the provider), null when that is not known.
  int? get failedStop => switch (this) {
    noInternet => 0,
    dns || certificate || reset || tls || timeout => 1,
    serverError || notFound || denied || tooManyRequests || badStatus || tooLarge || refused => 2,
    unknown => null,
  };

  /// Whose side the problem is on, for the user to know who can fix it.
  DownloadProblemSide get side => switch (this) {
    serverError || tooManyRequests || badStatus || tooLarge || refused => DownloadProblemSide.provider,
    notFound || denied => DownloadProblemSide.subscription,
    noInternet || dns || certificate || reset || tls || timeout => DownloadProblemSide.network,
    unknown => DownloadProblemSide.unknown,
  };

  /// The words for the user: a title, what happened, and what to try. [code] is the HTTP status.
  ({String title, String why, List<String> tips}) text(TranslationsEn t, {int? code}) {
    final d = t.errors.download;
    return switch (this) {
      serverError => (title: d.serverError.title, why: d.serverError.why(code: code ?? 500), tips: d.serverError.tips),
      notFound => (title: d.notFound.title, why: d.notFound.why, tips: d.notFound.tips),
      denied => (title: d.denied.title, why: d.denied.why, tips: d.denied.tips),
      tooManyRequests => (title: d.tooManyRequests.title, why: d.tooManyRequests.why, tips: d.tooManyRequests.tips),
      badStatus => (title: d.badStatus.title, why: d.badStatus.why(code: code ?? 0), tips: d.badStatus.tips),
      tooLarge => (title: d.tooLarge.title, why: d.tooLarge.why, tips: d.tooLarge.tips),
      noInternet => (title: d.noInternet.title, why: d.noInternet.why, tips: d.noInternet.tips),
      dns => (title: d.dns.title, why: d.dns.why, tips: d.dns.tips),
      certificate => (title: d.certificate.title, why: d.certificate.why, tips: d.certificate.tips),
      reset => (title: d.reset.title, why: d.reset.why, tips: d.reset.tips),
      tls => (title: d.tls.title, why: d.tls.why, tips: d.tls.tips),
      refused => (title: d.refused.title, why: d.refused.why, tips: d.refused.tips),
      timeout => (title: d.timeout.title, why: d.timeout.why, tips: d.timeout.tips),
      unknown => (title: d.unknown.title, why: d.unknown.why, tips: d.unknown.tips),
    };
  }
}

/// Where a download problem is: at the provider, in the subscription itself, or on the user's connection.
enum DownloadProblemSide { provider, subscription, network, unknown }
