import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';

part 'geo_asset_failure.freezed.dart';

@freezed
sealed class GeoAssetFailure with _$GeoAssetFailure, Failure {
  const GeoAssetFailure._();

  @With<UnexpectedFailure>()
  const factory GeoAssetFailure.unexpected([
    Object? error,
    StackTrace? stackTrace,
  ]) = GeoAssetUnexpectedFailure;

  @With<ExpectedFailure>()
  const factory GeoAssetFailure.noUpdateAvailable() = GeoAssetNoUpdateAvailable;

  @With<ExpectedMeasuredFailure>()
  const factory GeoAssetFailure.activeAssetNotFound() = GeoAssetActiveAssetNotFound;

  @override
  ({String type, String? message}) present(TranslationsEn t) {
    return switch (this) {
      GeoAssetUnexpectedFailure() => (
          type: t.errors.geoAssets.unexpected,
          message: null,
        ),
      GeoAssetNoUpdateAvailable() => (type: t.errors.geoAssets.notUpdate, message: null),
      GeoAssetActiveAssetNotFound() => (
          type: t.errors.geoAssets.activeNotFound,
          message: null,
        ),
    };
  }
}
