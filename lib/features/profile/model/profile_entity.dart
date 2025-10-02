import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_entity.freezed.dart';

enum ProfileType { remote, local }

@freezed
sealed class ProfileEntity with _$ProfileEntity {
  const ProfileEntity._();

  const factory ProfileEntity.remote({
    required String id,
    required bool active,
    required String name,
    required String url,
    required DateTime lastUpdate,
    String? testUrl,
    ProfileOptions? options,
    SubscriptionInfo? subInfo,
  }) = RemoteProfileEntity;

  const factory ProfileEntity.local({
    required String id,
    required bool active,
    required String name,
    required DateTime lastUpdate,
    String? testUrl,
  }) = LocalProfileEntity;
}

@freezed
abstract class ProfileOptions with _$ProfileOptions {
  const factory ProfileOptions({
    required Duration updateInterval,
  }) = _ProfileOptions;
}

@freezed
abstract class SubscriptionInfo with _$SubscriptionInfo {
  const SubscriptionInfo._();

  const factory SubscriptionInfo({
    required int upload,
    required int download,
    required int total,
    required DateTime expire,
    String? webPageUrl,
    String? supportUrl,
  }) = _SubscriptionInfo;

  bool get isExpired => expire <= DateTime.now();

  int get consumption => upload + download;

  double get ratio => (consumption / total).clamp(0, 1);

  Duration get remaining => expire.difference(DateTime.now());
}
