import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'is_small_active.g.dart';

@Riverpod(keepAlive: true)
class IsSmallActive extends _$IsSmallActive {
  @override
  bool? build() {
    return null;
  }

  // ignore: use_setters_to_change_properties
  void isActive(bool value) => state = value;
}
