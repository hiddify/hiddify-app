import 'package:freezed_annotation/freezed_annotation.dart';

part 'config.freezed.dart';
part 'config.g.dart';

@freezed
abstract class Config with _$Config {
  const factory Config({
    required String id,
    required String name,
    required String content,
    required String type,
    required DateTime addedAt, 
    @Default(0) int ping,
    @Default('') String source, 
  }) = _Config;

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);
}
