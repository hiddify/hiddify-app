import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/widget/shimmer_skeleton.dart';
import 'package:hiddify/features/app_based_routing/data/auto_selection_repository.dart';
import 'package:hiddify/features/app_based_routing/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/app_based_routing/model/pkg_flag.dart';
import 'package:hiddify/features/app_based_routing/overview/app_based_routing_notifier.dart';
import 'package:hiddify/features/app_based_routing/overview/app_list_notifier.dart';
import 'package:hiddify/features/app_based_routing/overview/auto_selection_notifier.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/features/route_rules/widget/rule_tile.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RoutingOptionsPage extends HookConsumerWidget {
  const RoutingOptionsPage({super.key, required this.routeRule});

  // Import route rule from deep link
  final String? routeRule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final rules = ref.watch(rulesNotifierProvider);

    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (routeRule != null && context.mounted) {
          await ref.read(rulesNotifierProvider.notifier).importRulesFromDeepLink(routeRule!);
        }
      });
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.routing.title),
        actions: [
          const _RegionChip(),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (_) {
              final notifier = ref.read(rulesNotifierProvider.notifier);
              final options = t.pages.settings.routing.routeRule.options;
              return <PopupMenuEntry>[
                PopupMenuItem(onTap: notifier.importRulesFromClipboard, child: Text(options.import.clipboard)),
                PopupMenuItem(onTap: notifier.importRulesFromJsonFile, child: Text(options.import.file)),
                const PopupMenuDivider(),
                PopupMenuItem(onTap: notifier.exportJsonToClipboard, child: Text(options.export.clipboard)),
                PopupMenuItem(onTap: notifier.saveRulesAsJsonFile, child: Text(options.export.file)),
                const PopupMenuDivider(),
                PopupMenuItem(onTap: notifier.resetRules, child: Text(options.reset)),
              ];
            },
          ),
          const Gap(8),
        ],
      ),
      // the built-in rules are always there, so the list is never empty
      body: ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 56 + 16 + 16),
        buildDefaultDragHandles: false,
        header: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // native, so it applies before every rule
            if (PlatformUtils.isAndroid) const _AppBasedRoutingSection(),
            const _PinnedOptions(),
          ],
        ),
        onReorder: ref.read(rulesNotifierProvider.notifier).reorder,
        itemBuilder: (context, index) => RuleTile(key: Key('$index'), index: index, rule: rules[index]),
        itemCount: rules.length,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: t.pages.settings.routing.routeRule.add,
        onPressed: () => context.goNamed('rule', pathParameters: {'orderId': 'new'}),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

/// The region decides the region rule and auto selection, so it stays in sight; the flag shows which one.
class _RegionChip extends ConsumerWidget {
  const _RegionChip();

  static const _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final region = ref.watch(ConfigOptions.region);
    final colorScheme = theme.colorScheme;
    // a popup menu, so back closes it and not the page
    return PopupMenuButton<Region>(
      tooltip: region.presentName(t),
      position: PopupMenuPosition.under,
      borderRadius: _radius,
      onSelected: ref.read(ConfigOptions.region.notifier).update,
      itemBuilder: (_) => [
        for (final option in Region.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                _RegionFlag(option),
                const Gap(12),
                Expanded(child: Text(option.presentName(t))),
                if (option == region) const Icon(Icons.check_rounded),
              ],
            ),
          ),
      ],
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: _radius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // as tall as the chip: its outer corners follow the line's, its inner ones meet the word
            _RegionFlag(
              region,
              size: 30,
              borderRadius: const BorderRadiusDirectional.horizontal(start: Radius.circular(7)),
            ),
            const Gap(8),
            Text(
              t.pages.settings.routing.region,
              style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
            ),
            Icon(Icons.arrow_drop_down_rounded, size: 20, color: colorScheme.onSurfaceVariant),
            const Gap(4),
          ],
        ),
      ),
    );
  }
}

/// Square, like the other flags in the app; Other has a gray tile with a globe in the same shape.
class _RegionFlag extends StatelessWidget {
  const _RegionFlag(this.region, {this.size = 24, this.borderRadius = const BorderRadius.all(Radius.circular(6))});

  final Region region;
  final double size;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    if (region == Region.other) {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        width: size,
        height: size,
        // a tint of the text color, so it shows on any background
        decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: borderRadius),
        child: Icon(Icons.public_rounded, size: size * 2 / 3, color: colorScheme.onSurfaceVariant),
      );
    }
    return CircleFlag(
      // the lion and sun, as for the IP's country
      region == Region.ir ? 'ir-shir' : region.name,
      size: size,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
    );
  }
}

/// App-based routing works through the Android VPN app list, so it sits above the rules and can't be moved.
class _AppBasedRoutingSection extends ConsumerWidget {
  const _AppBasedRoutingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final appBasedRouting = t.pages.settings.routing.appBasedRouting;
    final mode = ref.watch(Preferences.perAppProxyModeInUse);
    final region = ref.watch(ConfigOptions.region);
    final service = ref.read(appBasedRoutingProvider.notifier);
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // both modes sit under the name, the other one a tap away; only the switch turns it off
          ListTile(
            title: Text(appBasedRouting.title),
            subtitle: mode == null
                ? null
                // the pills start where the title starts, a little below it
                : Transform.translate(
                    offset: const Offset(0, 2),
                    child: Wrap(
                      spacing: 4,
                      children: [
                        for (final option in const [AppProxyMode.exclude, AppProxyMode.include])
                          _ModeOption(
                            label: option.present(t),
                            selected: option == mode,
                            onTap: () => service.changeMode(option),
                          ),
                      ],
                    ),
                  ),
            onTap: mode == null ? () => service.setEnabled(true) : null,
            trailing: Switch(value: mode != null, onChanged: service.setEnabled),
          ),
          if (mode != null) ...[
            _AppListRow(mode: mode),
            if (region != Region.other) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _AutoSelection(region: region),
            ],
          ],
          const Divider(height: 3, thickness: 3),
        ],
      ),
    );
  }
}

/// A mode under the section's name: the current one sits in a tinted pill, the other is a tap away.
class _ModeOption extends StatelessWidget {
  const _ModeOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(12));
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: selected ? BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: radius) : null,
          child: Text(
            label,
            style: TextStyle(color: selected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _AppListRow extends ConsumerWidget {
  const _AppListRow({required this.mode});

  final AppProxyMode mode;

  static const _maxLogos = 10;
  static const _loadingLogo = ClipOval(child: ShimmerSkeleton(width: 24, height: 24));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final appBasedRouting = t.pages.settings.routing.appBasedRouting;
    final flags = ref.watch(AppListProvider(mode)).valueOrNull;
    // the text sits close to the logos and is smaller than a list title; the row is 48 dp, like auto selection
    ListTile row({required Widget leading, required Widget title}) => ListTile(
      minTileHeight: 48,
      horizontalTitleGap: 8,
      titleTextStyle: theme.textTheme.bodyMedium,
      leading: leading,
      title: title,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.goNamed('appList'),
    );

    // placeholders until the list loads, at the loaded row's height, so nothing jumps
    if (flags == null) {
      return row(
        leading: _LogoStack(children: List.filled(3, _loadingLogo)),
        title: const Align(alignment: AlignmentDirectional.centerStart, child: ShimmerSkeleton(width: 56, height: 14)),
      );
    }
    bool active(int flag) => !PkgFlag.forceDeselection.check(flag);
    // your own picks get a logo first
    final apps = [
      for (final entry in flags.entries)
        if (active(entry.value) && PkgFlag.userSelection.check(entry.value)) entry.key,
      for (final entry in flags.entries)
        if (active(entry.value) && !PkgFlag.userSelection.check(entry.value)) entry.key,
    ];
    if (apps.isEmpty) {
      final color = theme.colorScheme.primary;
      return row(
        // an empty slot the size of a logo
        leading: _LogoStack(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(Icons.add_rounded, size: 16, color: color),
            ),
          ],
        ),
        title: Text(appBasedRouting.chooseApps, style: TextStyle(color: color)),
      );
    }
    final logoApps = apps.take(_maxLogos).toList();
    // decoded at the screen's density, so the logos stay sharp
    final logoPx = (24 * MediaQuery.devicePixelRatioOf(context)).round();
    return row(
      // each logo fills its place when it loads; the text is final already
      leading: _LogoStack(
        children: [
          for (final pkg in logoApps)
            switch (ref.watch(appLogoProvider(pkg))) {
              AsyncData(value: final icon?) => ClipOval(
                child: Image.memory(icon, width: 24, height: 24, cacheWidth: logoPx, cacheHeight: logoPx),
              ),
              AsyncLoading() => _loadingLogo,
              _ => const Icon(Icons.android_rounded),
            },
        ],
      ),
      // the logos stand for the first apps, so the text counts only the rest
      title: Text(
        apps.length > logoApps.length
            ? appBasedRouting.moreApps(n: apps.length - logoApps.length)
            : appBasedRouting.apps(n: apps.length),
      ),
    );
  }
}

/// App logos laid over each other, each in a ring of the page color so it stays clear.
class _LogoStack extends StatelessWidget {
  const _LogoStack({required this.children});

  final List<Widget> children;

  // a 24 dp logo in a 2 dp ring
  static const _size = 28.0;
  static const _step = 16.0;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      width: _size + (children.length - 1) * _step,
      height: _size,
      child: Stack(
        children: [
          for (final (index, child) in children.indexed)
            PositionedDirectional(
              start: index * _step,
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
                child: child,
              ),
            ),
        ],
      ),
    );
  }
}

class _AutoSelection extends ConsumerWidget {
  const _AutoSelection({required this.region});

  final Region region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final autoSelection = t.pages.settings.routing.appBasedRouting.autoSelection;
    final theme = Theme.of(context);
    final service = ref.read(appBasedRoutingProvider.notifier);
    final loading = ref.watch(autoSelectionLoadingProvider);
    final isOn = ref.watch(Preferences.autoAppsSelectionRegion) != null;
    final lastUpdate = ref.watch(Preferences.autoAppsSelectionLastUpdate);
    final issue = ref.watch(autoSelectionIssueProvider);

    final Widget? status = switch (issue) {
      AutoSelectionResult.notFound => _AutoSelectionIssue(
        icon: Icons.cloud_off_rounded,
        text: autoSelection.noList,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      AutoSelectionResult.failure => _AutoSelectionIssue(
        icon: Icons.error_outline_rounded,
        text: autoSelection.loadFailed,
        color: theme.colorScheme.error,
      ),
      _ when isOn && lastUpdate != null => Text(
        // in hours, since the day a clock change falls in has 23 or 25 of them
        autoSelection.updated(
          n: (DateUtils.dateOnly(DateTime.now()).difference(DateUtils.dateOnly(lastUpdate)).inHours / 24).round(),
        ),
      ),
      _ => null,
    };

    // the switch already spaces the row, so the status is its subtitle and refresh sits beside it;
    // smaller text and padding keep the row 48 dp with or without the status, so turning it on moves nothing
    return ListTile(
      minTileHeight: 48,
      minVerticalPadding: 6,
      titleTextStyle: theme.textTheme.bodyMedium,
      subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      title: Text(autoSelection.title(region: region.presentName(t))),
      subtitle: status,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOn)
            IconButton(
              tooltip: autoSelection.performNow,
              onPressed: loading ? null : service.updateAutoSelection,
              icon: const Icon(Icons.sync_rounded),
            ),
          // the bar takes the switch's place and keeps its space, so nothing moves
          Stack(
            alignment: Alignment.center,
            children: [
              Visibility(
                visible: !loading,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Switch(value: isOn, onChanged: service.setAutoSelection),
              ),
              if (loading)
                const SizedBox(
                  width: 52,
                  child: LinearProgressIndicator(borderRadius: BorderRadius.all(Radius.circular(2))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AutoSelectionIssue extends StatelessWidget {
  const _AutoSelectionIssue({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const Gap(4),
        Flexible(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}

/// Options for every rule, so they head the rules and can't be moved.
class _PinnedOptions extends ConsumerWidget {
  const _PinnedOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final routing = t.pages.settings.routing;
    const divider = Divider(height: 1, indent: 16, endIndent: 16);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MenuOption(
          title: routing.balancerStrategy.title,
          selected: ref.watch(ConfigOptions.balancerStrategy),
          choices: BalancerStrategy.values,
          present: (value) => value.present(t),
          onSelected: ref.read(ConfigOptions.balancerStrategy.notifier).update,
        ),
        divider,
        SwitchListTile.adaptive(
          title: Text(routing.resolveDestination),
          value: ref.watch(ConfigOptions.resolveDestination),
          onChanged: ref.read(ConfigOptions.resolveDestination.notifier).update,
        ),
        divider,
        _MenuOption(
          title: routing.ipv6Route,
          selected: ref.watch(ConfigOptions.ipv6Mode),
          choices: IPv6Mode.values,
          present: (value) => value.present(t),
          onSelected: ref.read(ConfigOptions.ipv6Mode.notifier).update,
        ),
        const Divider(height: 3, thickness: 3),
      ],
    );
  }
}

/// A choice on one line: the value sits at the end, and its menu opens there.
class _MenuOption<T> extends HookWidget {
  const _MenuOption({
    required this.title,
    required this.selected,
    required this.choices,
    required this.present,
    required this.onSelected,
  });

  final String title;
  final T selected;
  final List<T> choices;
  final String Function(T value) present;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final menu = useMemoized(GlobalKey<PopupMenuButtonState<T>>.new);
    return ListTile(
      title: Text(title),
      // the row takes the tap, so all of it ripples
      onTap: () => menu.currentState?.showButtonMenu(),
      trailing: IgnorePointer(
        // a popup menu, so back closes it and not the page
        child: PopupMenuButton<T>(
          key: menu,
          position: PopupMenuPosition.under,
          onSelected: onSelected,
          itemBuilder: (_) => [
            for (final choice in choices)
              PopupMenuItem(
                value: choice,
                child: Row(
                  children: [
                    Expanded(child: Text(present(choice))),
                    if (choice == selected) const Icon(Icons.check_rounded),
                  ],
                ),
              ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(present(selected), style: theme.textTheme.bodyMedium?.copyWith(color: color)),
              Icon(Icons.arrow_drop_down_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
