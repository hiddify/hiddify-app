import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/config/controller/config_controller.dart';
import 'package:hiddify/features/subscription/data/subscription_repository.dart';
import 'package:hiddify/features/subscription/model/subscription.dart';
import 'package:hiddify/features/subscription/service/subscription_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_controller.g.dart';

@Riverpod(keepAlive: true)
class SubscriptionController extends _$SubscriptionController {
  @override
  Future<List<Subscription>> build() async {
    final repo = await ref.watch(subscriptionRepositoryProvider.future);
    return repo.getSubscriptions();
  }

  Future<void> updateSubscription(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      final service = ref.read(subscriptionServiceProvider);
      final subs = repo.getSubscriptions();
      final sub = subs.firstWhere((s) => s.id == id);

      Logger.subscription.info('Updating subscription: ${sub.name}');
      
      final result = await service.fetchConfigs(sub.url);
      
      final newConfigs = result.items.map((e) => e.config).toList();
      final updatedSub = sub.copyWith(
        lastUpdated: DateTime.now(),
        configs: newConfigs,
      );

      await repo.updateSubscription(updatedSub);

      // Update ConfigController: remove old configs from this source and add new ones
      final configController = ref.read(configControllerProvider.notifier);
      final allConfigs = await ref.read(configControllerProvider.future);
      
      // Remove configs that match the subscription URL
      for (final config in allConfigs) {
        if (config.source == sub.url) {
          await configController.remove(config.id);
        }
      }
      
      // Add new configs
      await configController.addAll(newConfigs);

      return repo.getSubscriptions();
    });
  }

  Future<void> deleteSubscription(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      final subs = repo.getSubscriptions();
      final sub = subs.firstWhere((s) => s.id == id);

      Logger.subscription.info('Deleting subscription: ${sub.name}');

      await repo.removeSubscription(id);

      // Remove configs from ConfigController
      final configController = ref.read(configControllerProvider.notifier);
      final allConfigs = await ref.read(configControllerProvider.future);
      
      for (final config in allConfigs) {
        if (config.source == sub.url) {
          await configController.remove(config.id);
        }
      }

      return repo.getSubscriptions();
    });
  }
}
