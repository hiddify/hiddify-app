// This file is "main.dart"
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'free_profiles_model.freezed.dart';
part 'free_profiles_model.g.dart';

@freezed
class FreeProfilesModel with _$FreeProfilesModel {
  const factory FreeProfilesModel({required List<FreeProfile> profiles}) = _FreeProfilesModel;

  factory FreeProfilesModel.fromJson(Map<String, Object?> json) => _$FreeProfilesModelFromJson(json);
}

@freezed
class FreeProfile with _$FreeProfile {
  const factory FreeProfile({
    required List<String> region,
    required StringByLocale title,
    required String sublink,
    required ListOfStringByLocale tags,
    required StringByLocale consent,
    @JsonKey(name: 'needed_features') List<String>? neededFeatures,
  }) = _FreeProfile;

  factory FreeProfile.fromJson(Map<String, Object?> json) => _$FreeProfileFromJson(json);
}

@freezed
class StringByLocale with _$StringByLocale {
  const factory StringByLocale({required String en, required String fa}) = _StringByLocale;

  factory StringByLocale.fromJson(Map<String, Object?> json) => _$StringByLocaleFromJson(json);
}

@freezed
class ListOfStringByLocale with _$ListOfStringByLocale {
  const factory ListOfStringByLocale({required List<String> en, required List<String> fa}) = _ListOfStringByLocale;

  factory ListOfStringByLocale.fromJson(Map<String, Object?> json) => _$ListOfStringByLocaleFromJson(json);
}
