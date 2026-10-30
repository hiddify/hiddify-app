import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/proxy/model/ip_info_entity.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart' hide IpInfo;
import 'package:hiddify/hiddifycore/hiddify_core_service.dart';
import 'package:hiddify/utils/custom_loggers.dart';

abstract interface class ProxyRepository {
  Stream<Either<ProxyFailure, OutboundGroup?>> watchProxies();
  Stream<Either<ProxyFailure, OutboundGroupList>> watchActiveProxies();
  TaskEither<ProxyFailure, IpInfo> getCurrentIpInfo(CancelToken cancelToken, {String? customIpInfoUrl});
  TaskEither<ProxyFailure, Unit> selectProxy(String groupTag, String outboundTag);
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag);
}

class ProxyRepositoryImpl with ExceptionHandler, InfraLogger implements ProxyRepository {
  ProxyRepositoryImpl({required this.singbox, required this.client});

  final HiddifyCoreService singbox;
  final DioHttpClient client;

  @override
  Stream<Either<ProxyFailure, OutboundGroup?>> watchProxies() {
    return singbox.watchGroup().handleExceptions((error, stackTrace) {
      loggy.error("error watching proxies", error, stackTrace);
      return ProxyUnexpectedFailure(error, stackTrace);
    });
  }

  @override
  Stream<Either<ProxyFailure, OutboundGroupList>> watchActiveProxies() {
    return singbox.watchActiveGroups().handleExceptions((error, stackTrace) {
      loggy.error("error watching active proxies", error, stackTrace);
      return ProxyUnexpectedFailure(error, stackTrace);
    });
  }

  @override
  TaskEither<ProxyFailure, Unit> selectProxy(String groupTag, String outboundTag) {
    return exceptionHandler(
      () => singbox.selectOutbound(groupTag, outboundTag).mapLeft(ProxyUnexpectedFailure.new).run(),
      ProxyUnexpectedFailure.new,
    );
  }

  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag) {
    return exceptionHandler(
      () => singbox.urlTest(groupTag).mapLeft(ProxyUnexpectedFailure.new).run(),
      ProxyUnexpectedFailure.new,
    );
  }

  /// Built-in sources that currently return usable JSON. Custom `ipinfo-url`
  /// from the active subscription is tried first when provided.
  static final List<(String, IpInfo Function(Map<String, dynamic>))> _ipInfoSources = [
    ('https://ipwho.is/', IpInfo.fromIpwhoIsJson),
    ('https://api.ip.sb/geoip/', IpInfo.fromIpSbJson),
    ('https://ipapi.co/json/', IpInfo.fromIpApiJson),
    ('https://ipinfo.io/json', IpInfo.fromIpInfoIoJson),
    ('https://ifconfig.co/json', IpInfo.fromIfconfigCoJson),
  ];

  @override
  TaskEither<ProxyFailure, IpInfo> getCurrentIpInfo(CancelToken cancelToken, {String? customIpInfoUrl}) {
    return TaskEither.tryCatch(() async {
      Object? error;
      final sources = <(String, IpInfo Function(Map<String, dynamic>))>[
        if (customIpInfoUrl case final url? when url.trim().isNotEmpty) (url.trim(), IpInfo.parseFlexible),
        ..._ipInfoSources,
      ];
      for (final (url, parse) in sources) {
        try {
          loggy.debug("getting current ip info using [$url]");
          final response = await client.get<Map<String, dynamic>>(
            url,
            cancelToken: cancelToken,
            proxyOnly: true,
          );
          if (response.statusCode == 200 && response.data != null) {
            return parse(response.data!);
          }
        } catch (e, s) {
          loggy.debug("failed getting ip info using [$url]", e, s);
          error = e;
          continue;
        }
      }
      throw UnableToRetrieveIp(error, StackTrace.current);
    }, ProxyUnexpectedFailure.new);
  }
}
