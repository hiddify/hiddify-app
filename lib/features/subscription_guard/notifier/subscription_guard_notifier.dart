import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_guard_notifier.g.dart';

/// Provider to check if user has valid Go-bull subscription
@riverpod
class SubscriptionGuard extends _$SubscriptionGuard {
  static const String _goBullDomain = 'go-bull';
  static const String _subscriptionValidatedKey = 'subscription_validated';

  @override
  Future<bool> build() async {
    // Check if subscription was previously validated
    final preferences = await ref.watch(sharedPreferencesProvider.future);
    final wasValidated = preferences.getBool(_subscriptionValidatedKey) ?? false;

    if (wasValidated) {
      // Double check that there's still a valid profile
      return _hasValidSubscription();
    }

    return false;
  }

  /// Check if there's an active remote profile with go_bull domain
  Future<bool> _hasValidSubscription() async {
    final activeProfile = await ref.read(activeProfileProvider.future);

    if (activeProfile == null) return false;

    return activeProfile.when(
      remote: (id, active, name, url, lastUpdate, testUrl, options, subInfo) {
        // Check if URL contains go_bull identifier
        final lowerUrl = url.toLowerCase();
        return lowerUrl.contains(_goBullDomain) ||
               lowerUrl.contains('go-bull') ||
               lowerUrl.contains('gobull');
      },
      local: (_, __, ___, ____,testUrl) => false,
    );
  }

  /// Validate a subscription URL
  Future<bool> validateSubscription(String url) async {
    if (url.isEmpty) return false;

    final lowerUrl = url.toLowerCase();
    final isValid = lowerUrl.contains(_goBullDomain) ||
                   lowerUrl.contains('go-bull') ||
                   lowerUrl.contains('gobull');

    if (isValid) {
      // Mark subscription as validated
      final preferences = await ref.read(sharedPreferencesProvider.future);
      await preferences.setBool(_subscriptionValidatedKey, true);
      state = const AsyncData(true);
    }

    return isValid;
  }

  /// Recheck subscription status
  Future<void> recheckSubscription() async {
    state = const AsyncLoading();
    final isValid = await _hasValidSubscription();
    state = AsyncData(isValid);
  }

  /// Reset subscription validation (for testing/debugging)
  Future<void> resetValidation() async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await preferences.remove(_subscriptionValidatedKey);
    state = const AsyncData(false);
  }
}
