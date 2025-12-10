import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/proxy/model/ip_info_entity.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:hiddify/utils/custom_loggers.dart';

abstract interface class ProxyRepository {
  Stream<Either<ProxyFailure, List<ProxyGroupEntity>>> watchProxies();
  Stream<Either<ProxyFailure, List<ProxyGroupEntity>>> watchActiveProxies();
  TaskEither<ProxyFailure, IpInfo> getCurrentIpInfo(CancelToken cancelToken, {bool proxyOnly = true});
  TaskEither<ProxyFailure, Unit> selectProxy(
    String groupTag,
    String outboundTag,
  );
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag);
}

class ProxyRepositoryImpl with ExceptionHandler, InfraLogger implements ProxyRepository {
  ProxyRepositoryImpl({
    required this.singbox,
    required this.client,
  });

  final SingboxService singbox;
  final DioHttpClient client;

  @override
  Stream<Either<ProxyFailure, List<ProxyGroupEntity>>> watchProxies() {
    return singbox.watchGroups().map((event) {
      final groupWithSelected = {
        for (final group in event) group.tag: group.selected,
      };
      return event
          .map(
            (e) => ProxyGroupEntity(
              tag: e.tag,
              type: e.type,
              selected: e.selected,
              items: e.items
                  .map(
                    (e) => ProxyItemEntity(
                      tag: e.tag,
                      type: e.type,
                      urlTestDelay: e.urlTestDelay,
                      selectedTag: groupWithSelected[e.tag],
                    ),
                  )
                  .filter((t) => t.isVisible)
                  .toList(),
            ),
          )
          .toList();
    }).handleExceptions(
      (error, stackTrace) {
        loggy.error("error watching proxies", error, stackTrace);
        return ProxyUnexpectedFailure(error, stackTrace);
      },
    );
  }

  @override
  Stream<Either<ProxyFailure, List<ProxyGroupEntity>>> watchActiveProxies() {
    return singbox.watchActiveGroups().map((event) {
      final groupWithSelected = {
        for (final group in event) group.tag: group.selected,
      };
      return event
          .map(
            (e) => ProxyGroupEntity(
              tag: e.tag,
              type: e.type,
              selected: e.selected,
              items: e.items
                  .map(
                    (e) => ProxyItemEntity(
                      tag: e.tag,
                      type: e.type,
                      urlTestDelay: e.urlTestDelay,
                      selectedTag: groupWithSelected[e.tag],
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
    }).handleExceptions(
      (error, stackTrace) {
        loggy.error("error watching active proxies", error, stackTrace);
        return ProxyUnexpectedFailure(error, stackTrace);
      },
    );
  }

  @override
  TaskEither<ProxyFailure, Unit> selectProxy(
    String groupTag,
    String outboundTag,
  ) {
    return exceptionHandler(
      () => singbox.selectOutbound(groupTag, outboundTag).mapLeft(ProxyUnexpectedFailure.new).run(),
      ProxyUnexpectedFailure.new,
    );
  }

  @override
  TaskEither<ProxyFailure, Unit> urlTest(String groupTag_) {
    var groupTag = groupTag_;
    loggy.debug("testing group: [$groupTag]");
    if (!["auto"].contains(groupTag)) {
      loggy.warning("only auto proxy group can do url test. Please change go code if you want");
    }
    groupTag = "auto";

    return exceptionHandler(
      () => singbox.urlTest(groupTag).mapLeft(ProxyUnexpectedFailure.new).run(),
      ProxyUnexpectedFailure.new,
    );
  }

  static final Map<String, IpInfo Function(Map<String, dynamic> response)> _ipInfoSources = {
    // "https://geolocation-db.com/json/": IpInfo.fromGeolocationDbComJson, //bug response is not json
    "https://ipwho.is/": IpInfo.fromIpwhoIsJson,
    "https://api.ip.sb/geoip/": IpInfo.fromIpSbJson,
    "https://ipapi.co/json/": IpInfo.fromIpApiCoJson,
    "https://ipinfo.io/json/": IpInfo.fromIpInfoIoJson,
  };

  @override
  TaskEither<ProxyFailure, IpInfo> getCurrentIpInfo(CancelToken cancelToken, {bool proxyOnly = true}) {
    return TaskEither.tryCatch(
      () async {
        Object? error;
        for (final source in _ipInfoSources.entries) {
          try {
            loggy.debug("getting current ip info using [${source.key}]");
            final response = await client.get<Map<String, dynamic>>(
              source.key,
              cancelToken: cancelToken,
              proxyOnly: proxyOnly,
            );
            if (response.statusCode == 200 && response.data != null) {
              return source.value(response.data!);
            }
          } catch (e, s) {
            loggy.debug("failed getting ip info using [${source.key}]", e, s);
            error = e;
            continue;
          }
        }
        throw UnableToRetrieveIp(error, StackTrace.current);
      },
      ProxyUnexpectedFailure.new,
    );
  }
}
