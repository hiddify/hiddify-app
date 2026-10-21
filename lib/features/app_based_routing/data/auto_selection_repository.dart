import 'package:dio/dio.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/features/app_based_routing/model/per_app_proxy_mode.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum AutoSelectionResult { success, failure, notFound }

abstract interface class AutoSelectionRepository {
  Future<(Set<String>?, AutoSelectionResult)> getByAppProxyMode({required AppProxyMode mode, required Region region});
}

class AutoSelectionRepositoryImpl with AppLogger implements AutoSelectionRepository {
  AutoSelectionRepositoryImpl({required Ref ref}) : _ref = ref;
  final Ref _ref;
  static const _baseUrl = 'https://raw.githubusercontent.com/hiddify/Android-GFW-Apps/refs/heads/master/';

  @override
  Future<(Set<String>?, AutoSelectionResult)> getByAppProxyMode({
    required AppProxyMode mode,
    required Region region,
  }) async {
    try {
      final rs = await _getHttp().get(_genUrl(mode, region));
      if (rs.statusCode == 200) {
        final list = _parseToListOfString(rs.data);
        // some regions have an empty file (direct_cn, proxy_ru), which means no list
        if (list.isEmpty) return (null, AutoSelectionResult.notFound);
        return (list, AutoSelectionResult.success);
      }
      loggy.error("Auto selection failed. status code : ${rs.statusCode}");
      return (null, AutoSelectionResult.failure);
    } on DioException catch (e, st) {
      if (e.response?.statusCode == 404) {
        loggy.error("Auto selection region not found. region : ${region.name}", e, st);
        return (null, AutoSelectionResult.notFound);
      } else {
        loggy.error("Failed to fetch auto selection", e, st);
        return (null, AutoSelectionResult.failure);
      }
    } catch (e, st) {
      loggy.error("Failed to fetch auto selection with unexpected error", e, st);
      return (null, AutoSelectionResult.failure);
    }
  }

  String _genUrl(AppProxyMode mode, Region region) => switch (mode) {
    AppProxyMode.include => '${_baseUrl}proxy_${region.name}',
    AppProxyMode.exclude => '${_baseUrl}direct_${region.name}',
  };

  Set<String> _parseToListOfString(dynamic data) =>
      data.toString().split('\n').map((e) => e.trim()).where((element) => element.isNotEmpty).toSet();

  DioHttpClient _getHttp() => _ref.read(httpClientProvider);
}
