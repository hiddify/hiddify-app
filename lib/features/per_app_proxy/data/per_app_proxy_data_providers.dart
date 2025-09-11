import 'package:hiddify/features/per_app_proxy/data/per_app_proxy_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'per_app_proxy_data_providers.g.dart';

@Riverpod(keepAlive: true)
PerAppProxyRepository perAppProxyRepository(PerAppProxyRepositoryRef ref) {
  return PerAppProxyRepositoryImpl();
}
