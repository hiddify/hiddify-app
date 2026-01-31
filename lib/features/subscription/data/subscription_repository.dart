import 'dart:convert';

import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/subscription/model/subscription.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'subscription_repository.g.dart';

@Riverpod(keepAlive: true)
Future<SubscriptionRepository> subscriptionRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SubscriptionRepository(prefs);
}

class SubscriptionRepository {
  final SharedPreferences _prefs;
  static const _key = 'hiddify_subscriptions';

  SubscriptionRepository(this._prefs);

  List<Subscription> getSubscriptions() {
    final list = _prefs.getStringList(_key) ?? [];
    final result = <Subscription>[];
    for (final raw in list) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          result.add(Subscription.fromJson(decoded));
        } else if (decoded is Map) {
          result.add(Subscription.fromJson(decoded.cast<String, dynamic>()));
        } else {
          Logger.subscription.warning(
            'Invalid subscription entry in preferences',
          );
        }
      } catch (e, stackTrace) {
        Logger.subscription.warning(
          'Failed to parse stored subscription: $e',
          e,
          stackTrace,
        );
      }
    }
    return result;
  }

  Future<void> addSubscription(Subscription subscription) async {
    final subs = getSubscriptions();
    subs.add(subscription);
    await _saveSubscriptions(subs);
  }

  Future<void> updateSubscription(Subscription subscription) async {
    final subs = getSubscriptions();
    final index = subs.indexWhere((s) => s.id == subscription.id);
    if (index != -1) {
      subs[index] = subscription;
      await _saveSubscriptions(subs);
    }
  }

  Future<void> removeSubscription(String id) async {
    final subs = getSubscriptions();
    subs.removeWhere((s) => s.id == id);
    await _saveSubscriptions(subs);
  }

  Future<void> _saveSubscriptions(List<Subscription> subs) async {
    final list = subs.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_key, list);
  }
}
