import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/features/app_update/data/app_update_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_update_data_providers.g.dart';

@Riverpod(keepAlive: true)
AppUpdateRepository appUpdateRepository(
  AppUpdateRepositoryRef ref,
) {
  return AppUpdateRepositoryImpl(httpClient: ref.watch(httpClientProvider));
}
