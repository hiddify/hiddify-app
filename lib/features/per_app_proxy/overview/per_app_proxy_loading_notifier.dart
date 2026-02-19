import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'per_app_proxy_loading_notifier.g.dart';

@Riverpod()
class AppProxyLoading extends _$AppProxyLoading {
  @override
  bool build() => false;

  Future<T?> doAsync<T>(Future<T> Function() operation) async {
    state = true;
    final T? result = await operation();
    state = false;
    return result;
  }
}
