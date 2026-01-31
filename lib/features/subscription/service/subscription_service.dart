import 'package:dio/dio.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/features/config/logic/config_import_result.dart';
import 'package:hiddify/features/config/logic/config_import_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_service.g.dart';

@riverpod
SubscriptionService subscriptionService(Ref ref) =>
    SubscriptionService(ref.watch(httpClientProvider));

class SubscriptionService {
  final DioHttpClient _client;

  SubscriptionService(this._client);

  Future<ConfigImportResult> fetchConfigs(String url) async {
    Logger.subscription.info('Fetching subscription from: $url');
    try {
      final response = await _client.get<String>(
        url,
        responseType: ResponseType.plain,
      );
      final statusCode = response.statusCode;
      if (statusCode == 200) {
        final content = response.data?.toString() ?? '';
        Logger.subscription.debug(
          'Fetched subscription content (${content.length} chars)',
        );
        return ConfigImportService.importContent(content, source: url);
      }
      Logger.subscription.warning(
        'Failed to load subscription. Status: $statusCode',
      );
      throw Exception('Failed to load subscription: $statusCode');
    } catch (e, stackTrace) {
      Logger.subscription.error(
        'Error fetching subscription: $e',
        e,
        stackTrace,
      );
      throw Exception('Error fetching subscription: $e');
    }
  }
}
