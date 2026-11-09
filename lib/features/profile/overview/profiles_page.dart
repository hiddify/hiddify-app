import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfilesPage extends HookConsumerWidget {
  const ProfilesPage({super.key});

  Future<void> _removeInactive(WidgetRef ref) async {
    final notifier = ref.read(profilesNotifierProvider.notifier);
    final inactive = await notifier.findInactive();
    if (inactive.isEmpty) {
      final t = ref.read(translationsProvider).requireValue;
      ref.read(inAppNotificationControllerProvider).showInfoToast(t.pages.profiles.removeInactive.none);
      return;
    }
    final ids = await ref.read(dialogNotifierProvider.notifier).showRemoveInactiveProfiles(inactive);
    if (ids == null || ids.isEmpty) return;
    await notifier.deleteProfiles([
      for (final item in inactive)
        if (ids.contains(item.profile.id)) item.profile,
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final asyncProfiles = ref.watch(profilesNotifierProvider);

    ref.listen(hasAnyProfileProvider, (_, next) {
      if (next.value == false) {
        context.goNamed('home');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.profiles.title),
        actions: [
          IconButton(
            onPressed: () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger(),
            icon: const Icon(Icons.sync_rounded),
            tooltip: t.pages.profiles.updateSubscriptions,
          ),
          IconButton(
            onPressed: () => _removeInactive(ref),
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: t.pages.profiles.removeInactive.action,
          ),
          IconButton(
            onPressed: () => ref.read(dialogNotifierProvider.notifier).showSortProfiles(),
            icon: const Icon(Icons.sort_rounded),
            tooltip: t.common.sort,
          ),
          const Gap(8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async => await ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
        label: Text(t.pages.profiles.add),
        icon: const Icon(Icons.add_rounded),
      ),
      body: asyncProfiles.when(
        data: (data) => ListView.separated(
          padding: const EdgeInsets.all(12).copyWith(bottom: 84),
          separatorBuilder: (context, index) => const Gap(12),
          itemBuilder: (context, index) => ProfileTile(key: ValueKey(data[index].id), profile: data[index]),
          itemCount: data.length,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Text(t.presentShortError(error)),
      ),
    );
  }
}
