import 'package:dart_mappable/dart_mappable.dart';
import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/localization/translations.dart';

part 'optional_range.mapper.dart';

@MappableClass()
class OptionalRange with OptionalRangeMappable {
  const OptionalRange({this.min, this.max});

  final int? min;
  final int? max;

  String format() => [min, max].whereNotNull().join("-");
  String present(TranslationsEn t) => format().isEmpty ? t.common.notSet : format();

  factory OptionalRange.parse(String input, {bool allowEmpty = false}) => switch (input.split("-")) {
    [final String val] when val.isEmpty && allowEmpty => const OptionalRange(),
    [final String min] => OptionalRange(min: int.parse(min)),
    [final String min, final String max] => OptionalRange(min: int.parse(min), max: int.parse(max)),
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

class OptionalRangeJsonConverter implements JsonConverter<OptionalRange, String> {
  const OptionalRangeJsonConverter();

  @override
  OptionalRange fromJson(String json) => OptionalRange.parse(json, allowEmpty: true);

  @override
  String toJson(OptionalRange object) => object.format();
}
