import 'dart:convert';
import 'dart:math';

import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';

part 'profile_entity.freezed.dart';
part 'profile_entity.g.dart';

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
    ProfileOptions? options,
    SubscriptionInfo? subInfo,
    // `profile-web-page-url` / `support-url` headers; independent of subInfo,
    // which only exists when the `subscription-userinfo` header is present.
    String? webPageUrl,
    String? supportUrl,
    Map<String, dynamic>? populatedHeaders,
    UserOverride? userOverride,
    @Default(false) bool pinned,
  }) = RemoteProfileEntity;

  const factory ProfileEntity.local({
    required String id,
    required bool active,
    required String name,
    required DateTime lastUpdate,
    Map<String, dynamic>? populatedHeaders,
    UserOverride? userOverride,
    @Default(false) bool pinned,
  }) = LocalProfileEntity;

  String profileOverride() =>
      ProfileParser.profileOverride(populatedHeaders: populatedHeaders, userOverride: userOverride);
}

@freezed
class ProfileOptions with _$ProfileOptions {
  const factory ProfileOptions({@Default(Duration.zero) Duration updateInterval}) = _ProfileOptions;
}

@freezed
class SubscriptionInfo with _$SubscriptionInfo {
  const SubscriptionInfo._();

  const factory SubscriptionInfo({
    required int upload,
    required int download,
    required int total,
    required DateTime expire,
  }) = _SubscriptionInfo;

  bool get isExpired => expire <= DateTime.now();

  int get consumption => upload + download;
  int get remainingBW => total - consumption;
  double get remainingBWratio => (remainingBW / total).clamp(0, 1);
  double get ratio => (consumption / total).clamp(0, 1);

  Duration get remaining => expire.difference(DateTime.now());
  double get remainingRatio => min(remaining.inDays, 30) / 30;
}

const int latestUserOverrideVersion = 2;

@freezed
abstract class UserOverride with _$UserOverride {
  const UserOverride._();

  const factory UserOverride({
    @Default(latestUserOverrideVersion) int version,
    String? name,
    @Default(false) bool isAutoUpdateDisable,
    // hours
    int? updateInterval,

    /// Single extra-security mode — `warp` or `psiphon`. They share one slot
    /// because the core runs one chain mode at a time, mirroring the
    /// `extra-security` subscription header.
    String? extraSecurity,

    /// Non-null enables TLS fragmentation. The value mirrors the `fragment`
    /// header / proxy-link format `size,sleep`; an empty string means "enable
    /// with the config defaults".
    String? fragment,
  }) = _UserOverride;

  factory UserOverride.fromJson(Map<String, Object?> json) => _$UserOverrideFromJson(json);

  String toStr() => jsonEncode(toJson());

  static UserOverride? fromStr(String? str) {
    if (str != null) {
      final m = (jsonDecode(str) as Map).cast<String, Object?>();
      return UserOverride.fromJson(_migrate(m));
    }
    return null;
  }

  static Map<String, dynamic> _migrate(Map<String, Object?> json) {
    final version = json['version'] as int? ?? 1;

    if (version < 2) {
      // v1 -> v2: the `enableWarp` / `enablePsiphon` booleans become a single
      // `extraSecurity` mode, and `enableFragment` becomes `fragment` (which can
      // also carry `size,sleep`). Psiphon wins when both were on, matching v1
      // behaviour where it overrode warp.
      if (json.remove('enableWarp') == true) json['extraSecurity'] = 'warp';
      if (json.remove('enablePsiphon') == true) json['extraSecurity'] = 'psiphon';
      if (json.remove('enableFragment') == true) json['fragment'] = '';
    }
    json['version'] = latestUserOverrideVersion;
    return json;
  }
}
