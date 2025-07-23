import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hiddify/core/http_client/dio_http_client.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:loggy/loggy.dart';

enum AutoSelectionResult {
  success,
  failure,
  notFound;

  bool isSuccess() => this == success;
  bool isFailure() => this == failure;
  bool isNotFound() => this == notFound;
}

abstract interface class AutoSelectionRepository {
  Future<(List<String>?, AutoSelectionResult)> getByPerAppProxyMode({PerAppProxyMode? mode, Region? region});
  Future<(List<String>?, AutoSelectionResult)> getInclude({Region? region});
  Future<(List<String>?, AutoSelectionResult)> getExclude({Region? region});
  Future share(Translations t, List<String> apps);
}

class AutoSelectionRepositoryImpl with AppLogger implements AutoSelectionRepository {
  AutoSelectionRepositoryImpl({
    required PerAppProxyMode mode,
    required Region region,
    required DioHttpClient httpClient,
  })  : _mode = mode,
        _region = region,
        _httpClient = httpClient;
  final PerAppProxyMode _mode;
  final Region _region;
  final DioHttpClient _httpClient;
  static const _baseUrl = 'https://raw.githubusercontent.com/hiddify/Android-GFW-Apps/refs/heads/master/';

  @override
  Future<(List<String>?, AutoSelectionResult)> getByPerAppProxyMode({PerAppProxyMode? mode, Region? region}) async => await _makeRequest(mode: mode ?? _mode, region: region ?? _region);

  @override
  Future<(List<String>?, AutoSelectionResult)> getExclude({Region? region}) async => await _makeRequest(mode: PerAppProxyMode.exclude, region: region ?? _region);

  @override
  Future<(List<String>?, AutoSelectionResult)> getInclude({Region? region}) async => await _makeRequest(mode: PerAppProxyMode.include, region: region ?? _region);

  @override
  Future share(Translations t, List<String> apps) async {
    final title = '${_region.name} | ${_mode.present(t).title}';
    var body = const JsonEncoder.withIndent('  ').convert({'packages': apps});
    body = '```\n$body\n```';
    UriUtils.tryLaunch(Uri.parse('https://github.com/hiddify/Android-GFW-Apps/issues/new?title=$title&body=$body'));
  }

  Future<(List<String>?, AutoSelectionResult)> _makeRequest({required PerAppProxyMode mode, Region? region}) async {
    try {
      final rs = await _httpClient.get(_genUrl(mode, region ?? _region));
      if (rs.statusCode == 200) {
        return (_parseToListOfString(rs.data), AutoSelectionResult.success);
      }
      loggy.error("Auto selection failed. status code : ${rs.statusCode}");
      return (null, AutoSelectionResult.failure);
    } on DioException catch (e, st) {
      if (e.response?.statusCode == 404) {
        loggy.error("Auto selection region not found. region : ${region?.name ?? _region.name}", e, st);
        return (null, AutoSelectionResult.notFound);
      } else {
        loggy.error("Failed to fetch auto selection", e, st);
        return (null, AutoSelectionResult.failure);
      }
    } catch (e, st) {
      loggy.log(LogLevel.error, e.toString(), e, st);
      rethrow;
    }
  }

  String _genUrl(PerAppProxyMode mode, Region region) => switch (mode) {
        PerAppProxyMode.off => throw Exception('Auto selection is not possible with PerAppProxyMode.off'),
        PerAppProxyMode.include => '${_baseUrl}proxy_${region.name}',
        PerAppProxyMode.exclude => '${_baseUrl}direct_${region.name}',
      };

  List<String> _parseToListOfString(dynamic data) => data.toString().split('\n').map((e) => e.trim()).where((element) => element.isNotEmpty).toList();
}
