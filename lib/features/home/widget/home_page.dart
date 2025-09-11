import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
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
    // Safely watch translations with error handling
    final t = ref.watch(translationsProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    // Get current screen width with proper handling for different sizes
    final screenWidth = MediaQuery.of(context).size.width;

    // Memoize app title to prevent rebuilds
    final appTitle = useMemoized(
        () => Text.rich(
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
        [t.general.appTitle]);

    // Memoize action buttons
    final actionButtons = useMemoized(
        () => [
              IconButton(
                onPressed: () => const QuickSettingsRoute().push(context),
                icon: Icon(
                  FluentIcons.settings_24_filled,
                  size: 26,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: t.config.quickSettings,
              ),
              IconButton(
                onPressed: () => const AddProfileRoute().push(context),
                icon: Icon(
                  FluentIcons.add_circle_24_filled,
                  size: 26,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: t.profile.add.buttonText,
              ),
            ],
        [t.config.quickSettings, t.profile.add.buttonText]);

    final activeProfileState = useMemoized(
        () => switch (activeProfile) {
              AsyncData(value: final profile?) => MultiSliver(
                  children: [
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
                          if (screenWidth < kDesktopBreakpoint)
                            const RepaintBoundary(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: ActiveProxyFooter(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              AsyncData() => switch (hasAnyProfile) {
                  AsyncData(value: true) => const EmptyActiveProfileHomeBody(),
                  AsyncLoading() => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  AsyncError(:final error) => SliverErrorBodyPlaceholder(t.presentShortError(error)),
                  _ => const EmptyProfilesHomeBody(),
                },
              AsyncError(:final error) => SliverErrorBodyPlaceholder(t.presentShortError(error)),
              AsyncLoading() => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              _ => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            },
        [activeProfile]);

    // Render the full page as before, but keep heavy actions deferred to next frame via onTap wrappers
    return Scaffold(
      body: RepaintBoundary(
        child: CustomScrollView(
          slivers: [
            NestedAppBar(
              title: appTitle,
              actions: actionButtons,
            ),
            Builder(
              builder: (context) {
                return activeProfileState;
              },
            ),
          ],
        ),
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

    final appInfoAsync = ref.watch(appInfoProvider);

    return appInfoAsync.when(
      data: (appInfo) {
        final version = appInfo.presentVersion;
        if (version.isEmpty) return const SizedBox();

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
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}
