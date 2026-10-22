import 'package:dartx/dartx.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/theme/blizzard_theme.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_scene.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_card.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blizzard =
        BlizzardPresentation.isActive(context) ||
        (Theme.of(context).extension<BlizzardEligibility>()?.applied ?? false);
    final theme = BlizzardPresentation.themeOf(context);
    final t = ref.watch(translationsProvider).requireValue;
    // final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return BlizzardPresentation(
      child: Scaffold(
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
              // Keep this decorative slot stable across appearance changes.
              // ignore: prefer_if_elements_to_conditional_expressions
              blizzard ? const SizedBox.shrink() : Assets.images.logo.svg(height: 24),
              blizzard ? const SizedBox.shrink() : const Gap(8),
              const Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: "Blizzard"),
                      TextSpan(text: " "),
                      WidgetSpan(child: AppVersionLabel(), alignment: PlaceholderAlignment.middle),
                    ],
                  ),
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
              key: const ValueKey("profile_quick_settings"),
              label: t.pages.home.quickSettings,
              child: IconButton(
                icon: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                onPressed: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
              ),
            ),
            const Gap(8),
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
        body: Container(
          decoration: BoxDecoration(
            image: blizzard
                ? null
                : DecorationImage(
                    image: const AssetImage('assets/images/world_map.png'), // Replace with your image path
                    fit: BoxFit.cover,
                    opacity: 0.09,
                    colorFilter: theme.brightness == Brightness.dark
                        ? ColorFilter.mode(Colors.white.withValues(alpha: .15), BlendMode.srcIn) //
                        : ColorFilter.mode(
                            Colors.grey.withValues(alpha: 1),
                            BlendMode.srcATop,
                          ), // Apply white tint in dark mode
                  ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: blizzard ? const BlizzardScene() : const SizedBox.shrink(),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600, // Set the maximum width here
                  ),
                  child: CustomScrollView(
                    slivers: blizzard
                        ? [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    const ConnectionButton(),
                                    const SizedBox(height: 8),
                                    const ActiveProxyFooter(),
                                    const SizedBox(height: 18),
                                    switch (activeProfile) {
                                      AsyncData(value: final profile?) => ConstrainedBox(
                                        constraints: const BoxConstraints(minHeight: 76),
                                        child: ProfileTile(
                                          profile: profile,
                                          isMain: true,
                                          color: Theme.of(context).colorScheme.surfaceContainer,
                                        ),
                                      ),
                                      _ => const SizedBox.shrink(),
                                    },
                                  ],
                                ),
                              ),
                            ),
                          ]
                        : [
                            MultiSliver(
                              children: [
                                switch (activeProfile) {
                                  AsyncData(value: final profile?) => ProfileTile(
                                    profile: profile,
                                    isMain: true,
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: Theme.of(context).colorScheme.surfaceContainer,
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                  ),
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

    final version = ref.watch(appInfoProvider).requireValue.presentVersionWithBuild;
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
