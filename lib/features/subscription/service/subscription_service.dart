import 'dart:convert';
import 'package:dio/dio.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../config/logic/config_parser.dart';
import '../../config/model/config.dart';
import '../model/subscription.dart';

part 'subscription_service.g.dart';

@riverpod
SubscriptionService subscriptionService(Ref ref) {
  return SubscriptionService(Dio());
}

class SubscriptionService {
  final Dio _dio;
  static const _uuid = Uuid();

  SubscriptionService(this._dio);

  Future<List<Config>> fetchConfigs(String url) async {
    try {
      final response = await _dio.get(url, options: Options(responseType: ResponseType.plain));
      if (response.statusCode == 200) {
        final content = response.data.toString();
        return _parseConfigs(content, url);
      }
      throw Exception('Failed to load subscription: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching subscription: $e');
    }
  }

  List<Config> _parseConfigs(String content, String sourceUrl) {
    // Decoding base64 if needed (common in subscriptions)
    String decoded = content;
    try {
      decoded = utf8.decode(base64Decode(content));
    } catch (_) {}

    final lines = decoded.split('\n'); // naive, improved below
    // Better splitting handles both base64 decoded lines and plain text lists
    // Sometimes sub content is one line...
    
    final List<Config> configs = [];
    
    // Attempt to split by common delimiters if not handled by split('\n') well? 
    // Usually base64 decoded content is line separated.
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      final config = ConfigParser.parse(trimmed, source: sourceUrl);
      if (config != null) {
        configs.add(config);
      }
    }
    return configs;
  }
}
