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
    @Default(<ReleaseAsset>[]) List<ReleaseAsset> assets,
  }) = _RemoteVersionEntity;

  String get presentVersion => flavor == Environment.prod ? version : "$version ${flavor.name}";

  /// The asset named [name], if the release has it.
  ReleaseAsset? asset(String name) => assets.where((e) => e.name == name).firstOrNull;
}

/// A file of a release: an installer or a package.
class ReleaseAsset {
  const ReleaseAsset({required this.name, required this.url, required this.size, this.digest});

  final String name;

  /// Where it downloads from.
  final String url;

  /// Bytes; 0 when the release does not say.
  final int size;

  /// GitHub's release-asset digest, such as `sha256:<hex>`.
  /// This trusts the HTTPS release metadata; it is not a publisher signature.
  final String? digest;

  @override
  bool operator ==(Object other) =>
      other is ReleaseAsset && other.name == name && other.url == url && other.size == size && other.digest == digest;

  @override
  int get hashCode => Object.hash(name, url, size, digest);
}
