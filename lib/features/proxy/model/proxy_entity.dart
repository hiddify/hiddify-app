import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/singbox/model/singbox_outbound.dart';

part 'proxy_entity.freezed.dart';

@freezed
sealed class ProxyGroupEntity with _$ProxyGroupEntity {
  const factory ProxyGroupEntity({
    required String tag,
    required String type,
    required String selected,
    required List<ProxyItemEntity> items,
  }) = _ProxyGroupEntity;
}

enum ProxyType {
  shadowsocks,
  vmess,
  trojan,
  vless,
  wireguard,
  hysteria,
  hysteria2,
  tuic,
}

@freezed
sealed class ProxyItemEntity with _$ProxyItemEntity {
  const ProxyItemEntity._();

  const factory ProxyItemEntity({
    required String tag,
    required String type,
    required String urlTestDelay,
    required String? selectedTag,
  }) = _ProxyItemEntity;

  factory ProxyItemEntity.fromOutbound(SingboxOutboundGroupItem outbound) {
    return ProxyItemEntity(
      tag: outbound.tag,
      type: outbound.type.toString(),
      urlTestDelay: outbound.urlTestDelay.toString(),
      selectedTag: null,
    );
  }

  // Cached getters for better performance
  String get name => _sanitizedTag(tag);
  String? get selectedName => selectedTag == null ? null : _sanitizedTag(selectedTag!);
  bool get isVisible => !tag.contains("§hide§");

  // Cached delay conversion with error handling
  int get urlTestDelayInt {
    try {
      final parsed = int.parse(urlTestDelay);
      return parsed >= 0 ? parsed : 0; // Ensure non-negative
    } catch (e) {
      return 0;
    }
  }

  // Performance status getter
  ProxyPerformanceStatus get performanceStatus {
    final delay = urlTestDelayInt;
    if (delay == 0) return ProxyPerformanceStatus.unknown;
    if (delay < 100) return ProxyPerformanceStatus.excellent;
    if (delay < 300) return ProxyPerformanceStatus.good;
    if (delay < 600) return ProxyPerformanceStatus.fair;
    return ProxyPerformanceStatus.poor;
  }
}

// Enhanced performance status enum
enum ProxyPerformanceStatus {
  unknown,
  excellent,
  good,
  fair,
  poor;

  String get label => switch (this) {
        unknown => 'Unknown',
        excellent => 'Excellent',
        good => 'Good',
        fair => 'Fair',
        poor => 'Poor',
      };
}

String _sanitizedTag(String tag) => tag.replaceFirst(RegExp(r"\§[^]*"), "").trimRight();
