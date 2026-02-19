import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/hiddifycore/hiddify_core_service_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proxy_data_providers.g.dart';

@Riverpod(keepAlive: true)
ProxyRepository proxyRepository(Ref ref) {
  return ProxyRepositoryImpl(singbox: ref.watch(hiddifyCoreServiceProvider), client: ref.watch(httpClientProvider));
}
