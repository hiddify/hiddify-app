import 'dart:developer';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class RiverpodObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value, ProviderContainer container) {
    log('didAddProvider : ${provider.name ?? provider.runtimeType} : $value');
  }

  @override
  void didDisposeProvider(ProviderBase<Object?> provider, ProviderContainer container) {
    log('didDisposeProvider : ${provider.name ?? provider.runtimeType}');
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    log('didUpdateProvider : ${provider.name ?? provider.runtimeType} : $previousValue -> $newValue');
  }
}
