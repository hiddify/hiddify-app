import 'package:dio/dio.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum AutoSelectionResult {
  success,
  failure,
  notFound;

  bool isSuccess() => this == success;
  bool isFailure() => this == failure;
  bool isNotFound() => this == notFound;
}

abstract interface class AutoSelectionRepository {
  Future<(Set<String>?, AutoSelectionResult)> getByAppProxyMode({AppProxyMode? mode, Region? region});
  Future<(Set<String>?, AutoSelectionResult)> getInclude({Region? region});
  Future<(Set<String>?, AutoSelectionResult)> getExclude({Region? region});
}

class AutoSelectionRepositoryImpl with AppLogger implements AutoSelectionRepository {
  AutoSelectionRepositoryImpl({required Ref ref}) : _ref = ref;
  final Ref _ref;
  static const _baseUrl = 'https://raw.githubusercontent.com/hiddify/Android-GFW-Apps/refs/heads/master/';

  @override
  Future<(Set<String>?, AutoSelectionResult)> getByAppProxyMode({AppProxyMode? mode, Region? region}) async =>
      await _makeRequest(mode: mode ?? _getMode(), region: region ?? _getRegion());

  @override
  Future<(Set<String>?, AutoSelectionResult)> getExclude({Region? region}) async =>
      await _makeRequest(mode: AppProxyMode.exclude, region: region ?? _getRegion());

  @override
  Future<(Set<String>?, AutoSelectionResult)> getInclude({Region? region}) async =>
      await _makeRequest(mode: AppProxyMode.include, region: region ?? _getRegion());

  Future<(Set<String>?, AutoSelectionResult)> _makeRequest({required AppProxyMode mode, Region? region}) async {
    try {
      final rs = await _getHttp().get(_genUrl(mode, region ?? _getRegion()));
      if (rs.statusCode == 200) {
        return (_parseToListOfString(rs.data), AutoSelectionResult.success);
      }
      loggy.error("Auto selection failed. status code : ${rs.statusCode}");
      return (null, AutoSelectionResult.failure);
    } on DioException catch (e, st) {
      if (e.response?.statusCode == 404) {
        loggy.error("Auto selection region not found. region : ${region?.name ?? _getRegion().name}", e, st);
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

  AppProxyMode _getMode() => _ref.read(Preferences.perAppProxyMode).toAppProxy()!;

  Region _getRegion() => _ref.read(ConfigOptions.region);

  DioHttpClient _getHttp() => _ref.read(httpClientProvider);
}
