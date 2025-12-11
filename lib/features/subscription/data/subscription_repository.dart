import 'dart:convert';

import 'package:hiddify/features/subscription/model/subscription.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'subscription_repository.g.dart';

@Riverpod(keepAlive: true)
Future<SubscriptionRepository> subscriptionRepository(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SubscriptionRepository(prefs);
}

class SubscriptionRepository {
  final SharedPreferences _prefs;
  static const _key = 'hiddify_subscriptions';

  SubscriptionRepository(this._prefs);

  List<Subscription> getSubscriptions() {
    final list = _prefs.getStringList(_key) ?? [];
    return list.map((e) => Subscription.fromJson(Map<String, dynamic>.from(jsonDecode(e) as Map))).toList();
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
