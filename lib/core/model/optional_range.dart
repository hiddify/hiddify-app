import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';

part 'optional_range.freezed.dart';
part 'optional_range.g.dart';

@freezed
abstract class OptionalRange with _$OptionalRange {
  const OptionalRange._();
  const factory OptionalRange({int? min, int? max}) = _OptionalRange;

  factory OptionalRange.fromJson(Map<String, dynamic> json) =>
      _$OptionalRangeFromJson(json);

  String format() => [min, max].whereNotNull().join("-");
  String present(TranslationsEn t) =>
      format().isEmpty ? t.general.notSet : format();

  factory OptionalRange.parse(String input, {bool allowEmpty = false}) =>
      switch (input.split("-")) {
        [final String val] when val.isEmpty && allowEmpty =>
          const OptionalRange(),
        [final String min] => OptionalRange(min: int.parse(min)),
        [final String min, final String max] => OptionalRange(
          min: int.parse(min),
          max: int.parse(max),
        ),
        _ => throw Exception("Invalid range: $input"),
      };

  static OptionalRange? tryParse(String input, {bool allowEmpty = false}) {
    try {
      return OptionalRange.parse(input, allowEmpty: allowEmpty);
    } catch (_) {
      return null;
    }
  }
}

class OptionalRangeJsonConverter
    implements JsonConverter<OptionalRange, String> {
  const OptionalRangeJsonConverter();

  @override
  OptionalRange fromJson(String json) =>
      OptionalRange.parse(json, allowEmpty: true);

  @override
  String toJson(OptionalRange object) => object.format();
}
