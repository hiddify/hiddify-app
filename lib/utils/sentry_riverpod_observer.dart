import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

base class SentryRiverpodObserver extends ProviderObserver {
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
    ProviderObserverContext context,
    Object? value,
  ) {
    super.didAddProvider(context, value);
    addBreadcrumb(
      'Provider [${context.provider.name ?? context.provider.runtimeType}] was ADDED',
      data: value != null ? {"initial-value": value} : null,
    );
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    super.didUpdateProvider(context, previousValue, newValue);
    addBreadcrumb(
      'Provider [${context.provider.name ?? context.provider.runtimeType}] was UPDATED',
      data: {
        "new-value": newValue,
        "old-value": previousValue,
      },
    );
  }
}
