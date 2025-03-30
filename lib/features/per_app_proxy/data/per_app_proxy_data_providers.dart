import 'package:hiddify/features/per_app_proxy/data/per_app_proxy_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'per_app_proxy_data_providers.g.dart';

@Riverpod(keepAlive: true)
PerAppProxyRepository perAppProxyRepository(Ref ref) {
  return PerAppProxyRepositoryImpl();
}
