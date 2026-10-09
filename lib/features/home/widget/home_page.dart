import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/theme/cat/cat_ears_border.dart';
import 'package:hiddify/core/theme/cat/cat_theme.dart';
import 'package:hiddify/core/widget/cat/cat_face.dart';
import 'package:hiddify/core/widget/cat/cat_gaze.dart';
import 'package:hiddify/core/widget/cat/paw_prints_background.dart';
import 'package:hiddify/core/widget/cat/tappable_cat.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    // final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        // leading: (RootScaffold.stateKey.currentState?.hasDrawer ?? false) && showDrawerButton(context)
        //     ? DrawerButton(
        //         onPressed: () {
        //           RootScaffold.stateKey.currentState?.openDrawer();
        //         },
        //       )
        //     : null,
        title: Row(
          children: [
            // the logo; the home cat below does the moving, so this one keeps still
            TappableCat(
              mood: CatMood.purring,
              size: 36,
              alive: false,
              meow: t.cat.meow,
              onTap: ref.read(hapticServiceProvider.notifier).lightImpact,
            ),
            const Gap(8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: t.common.appTitle),
                  const TextSpan(text: " "),
                  const WidgetSpan(child: AppVersionLabel(), alignment: PlaceholderAlignment.middle),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // IconButton(
          //     onPressed: () => const QuickSettingsRoute().push(context),
          //     icon: const Icon(FluentIcons.options_24_filled),
          //     material: (context, platform) => MaterialIconButtonData(
          //           tooltip: t.config.quickSettings,
          //         )),
          // IconButton(
          //     onPressed: () => const AddProfileRoute().push(context),
          //     icon: const Icon(FluentIcons.add_circle_24_filled),
          //     material: (context, platform) => MaterialIconButtonData(
          //           tooltip: t.profile.add.buttonText,
          //         )),
          Semantics(
            key: const ValueKey("profile_add_button"),
            label: t.pages.profiles.add,
            child: IconButton(
              icon: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
              onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
            ),
          ),
          const Gap(8),
        ],
      ),
      // a cat walked across the page; the home cat's eyes follow the pointer
      body: CatGazeRegion(
        child: PawPrintsBackground(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600, // Set the maximum width here
                  ),
                  child: CustomScrollView(
                    slivers: [
                      // switch (activeProfile) {
                      // AsyncData(value: final profile?) =>
                      MultiSliver(
                        children: [
                          // const Gap(100),
                          switch (activeProfile) {
                            AsyncData(value: final profile?) => ProfileTile(
                              profile: profile,
                              isMain: true,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            _ => const Text(""),
                          },
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [ConnectionButton(), ActiveProxyDelayIndicator()],
                                  ),
                                ),
                                ActiveProxyFooter(),
                                Gap(32),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // AsyncData() => switch (hasAnyProfile) {
                      //     AsyncData(value: true) => const EmptyActiveProfileHomeBody(),
                      //     _ => const EmptyProfilesHomeBody(),
                      //   },
                      // AsyncError(:final error) => SliverErrorBodyPlaceholder(t.presentShortError(error)),
                      // _ => const SliverToBoxAdapter(),
                      // },
                    ],
                  ),
                ),
              ),
              if (ref.watch(hasAnyProfileProvider).value ?? false)
                Positioned(
                  right: 0,
                  left: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Material(
                        color: theme.colorScheme.primaryContainer,
                        shape: CatEarsBorder(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          earHeight: 9,
                          earWidth: 13,
                          earInset: 18,
                          innerEarColor: CatTheme.of(context).innerEar,
                        ),
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          onTap: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t.pages.home.quickSettings),
                                const Gap(4),
                                const Icon(Icons.arrow_drop_up_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.common.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
        ),
      ),
    );
  }
}
