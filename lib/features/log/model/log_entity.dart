import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/log/model/log_level.dart';

part 'log_entity.freezed.dart';

@freezed
sealed class LogEntity with _$LogEntity {
  const factory LogEntity({
    required LogLevel level,
    required String message,
    required DateTime time,
  }) = _LogEntity;
}
