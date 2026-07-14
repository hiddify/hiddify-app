import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EmptyProfilesHomeBody extends HookConsumerWidget {
  const EmptyProfilesHomeBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.vpn_key_off_rounded, size: 48),
          const Gap(16),
          Text(t.pages.home.noAccessTitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(t.pages.home.noAccessBody, textAlign: TextAlign.center),
          ),
          const Gap(16),
          FilledButton.icon(
            onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
            icon: const Icon(Icons.add_link_rounded),
            label: Text(t.pages.home.addAccess),
          ),
        ],
      ),
    );
  }
}

// class EmptyActiveProfileHomeBody extends HookConsumerWidget {
//   const EmptyActiveProfileHomeBody({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final t = ref.watch(translationsProvider).requireValue;

//     return SliverFillRemaining(
//       hasScrollBody: false,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(t.home.noActiveProfileMsg),
//           const Gap(16),
//           OutlinedButton(
//             onPressed: () => const ProfilesOverviewRoute().push(context),
//             child: Text(t.profile.overviewPageTitle),
//           ),
//         ],
//       ),
//     );
//   }
// }
