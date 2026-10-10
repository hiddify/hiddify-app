import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/widget/cat/paw_spinner.dart';
import 'package:hiddify/features/app_based_routing/model/app_package_info.dart';
import 'package:hiddify/features/app_based_routing/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/route_rules/notifier/rule_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:installed_apps/index.dart';

/// Picks the apps of a route rule. Apps that App-based routing keeps out of the VPN never reach the rules:
/// they can still be picked, but carry a mark, and a picked one says the rule won't apply to it.
class PackageNamesPage extends HookConsumerWidget {
  const PackageNamesPage({super.key, this.ruleListOrder});

  final int? ruleListOrder;

  Future<List<AppPackageInfo>> _getApps(bool hideSystem) async {
    if (!PlatformUtils.isAndroid) return [];
    return (await InstalledApps.getInstalledApps(
      hideSystem,
      true,
    )).map((e) => AppPackageInfo(packageName: e.packageName, name: e.name, icon: e.icon)).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final appBasedRouting = t.pages.settings.routing.appBasedRouting;
    final rule = ruleNotifierProvider(ruleListOrder);
    final selected = ref.watch(rule.select((value) => value.packageNames)).toList();

    final hideSystemApps = useState(false);
    final isSearching = useState(false);
    final searchQuery = useState('');
    final allApps = useFuture(useMemoized(() => _getApps(false))).data;
    final userApps = useFuture(useMemoized(() => _getApps(true))).data;
    final shownApps = hideSystemApps.value ? userApps : allApps;

    // The order is set when the list loads, so a tap doesn't move the row. Picked apps come first.
    final pickedAtStart = useMemoized(() => selected.toSet());
    final rows = useMemoized<List<(String, AppPackageInfo?)>?>(() {
      if (allApps == null || shownApps == null) return null;
      final installed = {for (final app in allApps) app.packageName};
      return [
        for (final pkg in pickedAtStart)
          if (!installed.contains(pkg)) (pkg, null),
        for (final app in shownApps)
          if (pickedAtStart.contains(app.packageName)) (app.packageName, app),
        for (final app in shownApps)
          if (!pickedAtStart.contains(app.packageName)) (app.packageName, app),
      ];
    }, [allApps, shownApps]);
    final query = searchQuery.value.toLowerCase();
    final shownRows = rows
        ?.filter(
          (row) =>
              query.isEmpty ||
              row.$1.toLowerCase().contains(query) ||
              (row.$2?.name.toLowerCase().contains(query) ?? false),
        )
        .toList();

    final appBasedRoutingMode = ref.watch(Preferences.perAppProxyModeInUse);
    final listedApps = switch (appBasedRoutingMode) {
      AppProxyMode.include => ref.watch(Preferences.includeApps).toSet(),
      AppProxyMode.exclude => ref.watch(Preferences.excludeApps).toSet(),
      null => const <String>{},
    };
    bool outsideVpn(String pkg) => switch (appBasedRoutingMode) {
      // with no app listed, Android lets every app into the VPN
      AppProxyMode.include => listedApps.isNotEmpty && !listedApps.contains(pkg),
      AppProxyMode.exclude => listedApps.contains(pkg),
      null => false,
    };

    void save(List<String> packages) => ref.read(rule.notifier).update<List<dynamic>>(RuleEnum.packageName, packages);

    // the same chip row as the app list
    final chips = PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // centered rather than stretched to the row: a chip squeezed or stretched draws its label off center;
          // 6 dp above and below the label makes the 32 dp chip of M3, where Flutter's 8 dp gives about 37
          children: [
            Center(
              child: ChoiceChip(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                label: Text(appBasedRouting.hideSysApps),
                selected: hideSystemApps.value,
                onSelected: (value) => hideSystemApps.value = value,
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: isSearching.value
          ? AppBar(
              title: TextFormField(
                onChanged: (value) => searchQuery.value = value.trim(),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "${localizations.searchFieldLabel}...",
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
              leading: IconButton(
                onPressed: () {
                  searchQuery.value = '';
                  isSearching.value = false;
                },
                icon: const Icon(Icons.close),
                tooltip: localizations.cancelButtonLabel,
              ),
              bottom: chips,
            )
          : AppBar(
              title: Text(RuleEnum.packageName.present(t)),
              actions: [
                IconButton(
                  icon: const Icon(FluentIcons.search_24_regular),
                  onPressed: () => isSearching.value = true,
                  tooltip: localizations.searchFieldLabel,
                ),
                PopupMenuButton<void>(
                  icon: const Icon(Icons.more_vert_rounded),
                  itemBuilder: (_) => <PopupMenuEntry<void>>[
                    PopupMenuItem(
                      enabled: selected.isNotEmpty,
                      onTap: () => save([]),
                      child: Text(appBasedRouting.options.clearAllSelections),
                    ),
                  ],
                ),
              ],
              bottom: chips,
            ),
      body: shownRows == null
          ? const Center(child: PawSpinner())
          : ListView.builder(
              itemCount: shownRows.length,
              itemBuilder: (context, index) {
                final (pkg, app) = shownRows[index];
                final isSelected = selected.contains(pkg);
                final outside = app != null && outsideVpn(pkg);
                final warn = outside && isSelected;
                final markColor = warn ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant;
                return CheckboxListTile.adaptive(
                  value: isSelected,
                  onChanged: (_) => save(isSelected ? [...selected.where((e) => e != pkg)] : [...selected, pkg]),
                  secondary: app?.icon == null
                      ? const SizedBox.square(dimension: 48, child: Icon(Icons.android_rounded))
                      : Image.memory(app!.icon!, width: 48, height: 48, cacheWidth: 48, cacheHeight: 48),
                  title: Row(
                    children: [
                      Flexible(child: Text(app?.name ?? pkg, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (outside) ...[
                        const Gap(4),
                        Tooltip(
                          message: appBasedRouting.outsideVpn,
                          child: Icon(Icons.remove_moderator_outlined, size: 16, color: markColor),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    warn
                        ? appBasedRouting.ruleWontApply
                        : app == null
                        ? appBasedRouting.notInstalled
                        : pkg,
                    style: theme.textTheme.bodySmall?.copyWith(color: warn ? markColor : null),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
    );
  }
}
