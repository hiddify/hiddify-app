import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/empty_profiles_home_body.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_footer.dart';
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          NestedAppBar(
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                onPressed: () => const QuickSettingsRoute().push(context),
                icon: const Icon(FluentIcons.options_24_filled),
                tooltip: t.config.quickSettings,
              ),
              IconButton(
                onPressed: () => const AddProfileRoute().push(context),
                icon: const Icon(FluentIcons.add_circle_24_filled),
                tooltip: t.profile.add.buttonText,
              ),
            ],
          ),
          switch (activeProfile) {
            AsyncData(value: final profile?) => SliverToBoxAdapter(
              child: Column(
                children: [
                  ProfileTile(profile: profile, isMain: true),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        if (MediaQuery.sizeOf(context).width < 840)
                          const ActiveProxyFooter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AsyncData() => switch (hasAnyProfile) {
              AsyncData(value: true) => const EmptyActiveProfileHomeBody(),
              _ => const EmptyProfilesHomeBody(),
            },
            AsyncError(:final error) => SliverErrorBodyPlaceholder(
              t.presentShortError(error),
            ),
            _ => const SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          },
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
    if (version.isBlank) return const SizedBox.shrink();

    return Semantics(
      label: t.about.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
