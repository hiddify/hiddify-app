import 'package:dio/dio.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_repository.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Service for detecting region from IPInfo
class RegionDetectionService with AppLogger {
  RegionDetectionService({
    required this.proxyRepository,
  });

  final ProxyRepository proxyRepository;

  /// Detect region from IPInfo
  /// Returns Region.other if detection fails
  Future<Region> detectRegion() async {
    try {
      final cancelToken = CancelToken();
      
      // Set timeout to 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Timeout');
        }
      });

      final result = await proxyRepository
          .getCurrentIpInfo(cancelToken, proxyOnly: false)
          .run();

      return result.fold(
        (error) {
          loggy.warning('Failed to detect region from IPInfo: $error');
          return Region.other;
        },
        (ipInfo) {
          final countryCode = ipInfo.countryCode.toUpperCase();
          loggy.debug('Detected country code: $countryCode');
          return _mapCountryCodeToRegion(countryCode);
        },
      );
    } catch (e, stackTrace) {
      loggy.warning('Exception during region detection', e, stackTrace);
      return Region.other;
    }
  }

  /// Map country code to Region enum
  Region _mapCountryCodeToRegion(String countryCode) {
    switch (countryCode) {
      case 'IR':
        return Region.ir;
      case 'CN':
        return Region.cn;
      case 'RU':
        return Region.ru;
      case 'AF':
        return Region.af;
      case 'ID':
        return Region.id;
      case 'TR':
        return Region.tr;
      case 'BR':
        return Region.br;
      default:
        return Region.other;
    }
  }
}

/// Provider for RegionDetectionService
final regionDetectionServiceProvider = Provider<RegionDetectionService>((ref) {
  return RegionDetectionService(
    proxyRepository: ref.watch(proxyRepositoryProvider),
  );
});

