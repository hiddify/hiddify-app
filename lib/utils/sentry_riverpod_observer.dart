import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryRiverpodObserver extends ProviderObserver {
  void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: "Provider",
        message: message,
        data: data,
      ),
    );
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    super.didAddProvider(provider, value, container);
    addBreadcrumb(
      'Provider [${provider.name ?? provider.runtimeType}] was ADDED',
      data: value != null ? {"initial-value": value} : null,
    );
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    super.didUpdateProvider(provider, previousValue, newValue, container);
    addBreadcrumb(
      'Provider [${provider.name ?? provider.runtimeType}] was UPDATED',
      data: {
        "new-value": newValue,
        "old-value": previousValue,
      },
    );
  }
}
