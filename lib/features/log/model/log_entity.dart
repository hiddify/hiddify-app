import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/log/model/log_level.dart';

part 'log_entity.freezed.dart';

@freezed
class LogEntity with _$LogEntity {
  const factory LogEntity({LogLevel? level, DateTime? time, required String message}) = _LogEntity;
}
