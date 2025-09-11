import 'package:freezed_annotation/freezed_annotation.dart';

class IntervalInSecondsConverter implements JsonConverter<Duration, int> {
  const IntervalInSecondsConverter();

  @override
  Duration fromJson(int json) => Duration(seconds: json);

  @override
  int toJson(Duration object) => object.inSeconds;
}
