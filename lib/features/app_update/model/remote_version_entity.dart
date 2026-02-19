import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/model/environment.dart';

part 'remote_version_entity.freezed.dart';

@Freezed()
class RemoteVersionEntity with _$RemoteVersionEntity {
  const RemoteVersionEntity._();

  const factory RemoteVersionEntity({
    required String version,
    required String buildNumber,
    required String releaseTag,
    required bool preRelease,
    required String url,
    required DateTime publishedAt,
    required Environment flavor,
  }) = _RemoteVersionEntity;

  String get presentVersion => flavor == Environment.prod ? version : "$version ${flavor.name}";
}
