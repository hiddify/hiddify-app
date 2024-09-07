import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/empty_profiles_home_body.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_footer.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return PlatformScaffold(
      iosContentPadding: true,
      appBar: PlatformAppBar(
        leading: (RootScaffold.stateKey.currentState?.hasDrawer ?? false) && showDrawerButton(context)
            ? DrawerButton(
                onPressed: () {
                  RootScaffold.stateKey.currentState?.openDrawer();
                },
              )
            : (Navigator.of(context).canPop()
                ? PlatformIconButton(
                    icon: Icon(context.isRtl ? Icons.arrow_forward : Icons.arrow_back),
                    padding: EdgeInsets.only(right: context.isRtl ? 50 : 0),
                    onPressed: () {
                      Navigator.of(context).pop(); // Pops the current route off the navigator stack
                    },
                  )
                : null),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: t.general.appTitle),
              const TextSpan(text: " "),
              const WidgetSpan(
                child: AppVersionLabel(),
                alignment: PlaceholderAlignment.middle,
              ),
            ],
          ),
        ),
        trailingActions: [
          // PlatformIconButton(
          //     onPressed: () => const QuickSettingsRoute().push(context),
          //     icon: const Icon(FluentIcons.options_24_filled),
          //     material: (context, platform) => MaterialIconButtonData(
          //           tooltip: t.config.quickSettings,
          //         )),
          // PlatformIconButton(
          //     onPressed: () => const AddProfileRoute().push(context),
          //     icon: const Icon(FluentIcons.add_circle_24_filled),
          //     material: (context, platform) => MaterialIconButtonData(
          //           tooltip: t.profile.add.buttonText,
          //         )),
          PlatformTextButton(
            material: (context, platform) => MaterialTextButtonData(
              child: TextButton.icon(onPressed: () => const AddProfileRoute().push(context), label: Text(t.profile.add.buttonText)),
            ),
            cupertino: (context, platform) => CupertinoTextButtonData(
              child: PlatformText(t.profile.add.buttonText, style: CupertinoTheme.of(context).textTheme.navActionTextStyle.copyWith(fontSize: 12)),

              onPressed: () => const AddProfileRoute().push(context),
              // icon: const Icon(FluentIcons.add_circle_24_filled),
              //       material: (context, platform) => MaterialIconButtonData(
              //             tooltip: t.profile.add.buttonText,
            ),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomScrollView(
            slivers: [
              switch (activeProfile) {
                AsyncData(value: final profile?) => MultiSliver(
                    children: [
                      // const Gap(100),
                      ProfileTile(profile: profile, isMain: true),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ConnectionButton(),
                                  ActiveProxyDelayIndicator(),
                                ],
                              ),
                            ),
                            if (MediaQuery.sizeOf(context).width < 840) const ActiveProxyFooter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                AsyncData() => switch (hasAnyProfile) {
                    AsyncData(value: true) => const EmptyActiveProfileHomeBody(),
                    _ => const EmptyProfilesHomeBody(),
                  },
                AsyncError(:final error) => SliverErrorBodyPlaceholder(t.presentShortError(error)),
                _ => const SliverToBoxAdapter(),
              },
            ],
          ),
        ],
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.about.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 1,
        ),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
