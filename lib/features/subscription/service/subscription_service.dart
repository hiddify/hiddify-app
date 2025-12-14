import 'package:dio/dio.dart';
import 'package:hiddify/features/config/logic/config_import_result.dart';
import 'package:hiddify/features/config/logic/config_import_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_service.g.dart';

@riverpod
SubscriptionService subscriptionService(Ref ref) => SubscriptionService(Dio());

class SubscriptionService {
  final Dio _dio;

  SubscriptionService(this._dio);

  Future<ConfigImportResult> fetchConfigs(String url) async {
    try {
      final response = await _dio.get<String>(url, options: Options(responseType: ResponseType.plain));
      if (response.statusCode == 200) {
        final content = response.data.toString();
        return ConfigImportService.importContent(content, source: url);
      }
      throw Exception('Failed to load subscription: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching subscription: $e');
    }
  }
}
