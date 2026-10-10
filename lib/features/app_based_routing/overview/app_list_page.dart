import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/widget/cat/paw_spinner.dart';
import 'package:hiddify/features/app_based_routing/data/selected_data_provider.dart';
import 'package:hiddify/features/app_based_routing/model/app_package_info.dart';
import 'package:hiddify/features/app_based_routing/model/pkg_flag.dart';
import 'package:hiddify/features/app_based_routing/overview/app_list_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:installed_apps/index.dart';

class AppListPage extends HookConsumerWidget with PresLogger {
  const AppListPage({super.key});

  int _getPriority(AppPackageInfo app, Map<String, int> selected) {
    final flag = selected[app.packageName];
    if (flag == null) return 4;
    if (PkgFlag.userSelection.check(flag)) {
      return 1;
    } else if (PkgFlag.autoSelection.check(flag) && !PkgFlag.forceDeselection.check(flag)) {
      return 2;
    } else {
      return 3;
    }
  }

  Future<Set<AppPackageInfo>> getApps(bool hideSystem) async {
    if (!PlatformUtils.isAndroid) return {};
    return (await InstalledApps.getInstalledApps(
      hideSystem,
      true,
    )).map((e) => AppPackageInfo(packageName: e.packageName, name: e.name, icon: e.icon)).toSet();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final localizations = MaterialLocalizations.of(context);

    final mode = ref.watch(Preferences.perAppProxyModeInUse);
    final selectedApps = ref.watch(AppListProvider(mode));

    final hideSystemApps = useState(false);
    final isSearching = useState(false);
    final searchQuery = useState("");
    final sortListener = useState(false);

    final asyncApps = useFuture(useMemoized(() => getApps(false)));
    final asyncAppsHideSys = useFuture(useMemoized(() => getApps(true)));

    final asyncFilteredApps = hideSystemApps.value ? asyncAppsHideSys : asyncApps;

    final displayedApps = useMemoized<AsyncValue<List<AppPackageInfo>>>(
      () {
        if (!(selectedApps.hasValue &&
            selectedApps is AsyncData &&
            asyncFilteredApps.hasData &&
            asyncFilteredApps.connectionState == ConnectionState.done)) {
          return const AsyncValue.loading();
        }
        final appsList = asyncFilteredApps.requireData.toList();
        if (searchQuery.value.isBlank) {
          appsList.sort((a, b) {
            final priorityA = _getPriority(a, selectedApps.requireValue);
            final priorityB = _getPriority(b, selectedApps.requireValue);
            return priorityA.compareTo(priorityB);
          });
          return AsyncValue.data(appsList);
        }
        final query = searchQuery.value.toLowerCase();
        final filteredAppsList = appsList
            .filter((e) => e.name.toLowerCase().contains(query) || e.packageName.toLowerCase().contains(query))
            .toList();
        return AsyncValue.data(filteredAppsList);
      },
      [
        asyncFilteredApps.connectionState == ConnectionState.done,
        hideSystemApps.value,
        selectedApps.hasValue,
        searchQuery.value,
        sortListener.value,
      ],
    );

    if (mode != null) {
      ref.listen(AppListProvider(mode), (previous, next) {
        if (previous != null) {
          if ((previous, next) case (AsyncData(value: final prevData), AsyncData(value: final nextData))) {
            if (nextData.isNotEmpty) {
              if ((nextData.length - prevData.length).abs() > 1) sortListener.value = !sortListener.value;
            }
          }
        }
      });
    }

    final scrollController = useScrollController();
    const double scrollThreshold = 300.0;
    final showScrollToTop = useState<bool>(false);
    useEffect(() {
      void listener() {
        showScrollToTop.value = scrollController.offset > scrollThreshold;
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, []);
    useEffect(() {
      showScrollToTop.value = false;
      return null;
    }, [displayedApps]);

    final appBasedRouting = t.pages.settings.routing.appBasedRouting;
    // the auto picks you removed: the chip brings them back, and the toast can take that back
    final removed = [
      for (final entry in (selectedApps.valueOrNull ?? const <String, int>{}).entries)
        if (PkgFlag.autoSelection.check(entry.value) && PkgFlag.forceDeselection.check(entry.value)) entry.key,
    ];
    Future<void> restoreRemoved() async {
      final dataSource = ref.read(appProxyDataSourceProvider);
      final restoredMode = mode!;
      await dataSource.revertForceDeselection(mode: restoredMode);
      ref
          .read(inAppNotificationControllerProvider)
          .showSuccessToast(
            appBasedRouting.autoSelection.restored(n: removed.length),
            action: (
              label: t.common.undo,
              // removes them again, as a tap on each would
              onPressed: () async {
                for (final pkg in removed) {
                  await dataSource.updatePkg(pkg: pkg, mode: restoredMode);
                }
              },
            ),
          );
    }

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
            if (removed.isNotEmpty) ...[
              const Gap(8),
              Center(
                child: ActionChip(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  avatar: const Icon(Icons.undo_rounded),
                  label: Text(appBasedRouting.autoSelection.restore(n: removed.length)),
                  onPressed: restoreRemoved,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // the apps you added that auto selection didn't pick; with the removed auto picks, this is what Share sends
    final added = [
      for (final entry in (selectedApps.valueOrNull ?? const <String, int>{}).entries)
        if (PkgFlag.userSelection.check(entry.value) && !PkgFlag.autoSelection.check(entry.value)) entry.key,
    ];
    final autoOn = ref.watch(Preferences.autoAppsSelectionRegion) != null;
    Future<void> openShare() => ref
        .read(bottomSheetsNotifierProvider.notifier)
        .showAppListShare(
          added: added,
          removed: removed,
          apps: {for (final app in asyncApps.data ?? const <AppPackageInfo>{}) app.packageName: app},
        );

    return Scaffold(
      // only while your list differs from the region's list: the bar counts how, Share shows what gets sent;
      // it steps aside for the keyboard, which would push it up over the list
      bottomNavigationBar:
          autoOn && (added.isNotEmpty || removed.isNotEmpty) && MediaQuery.viewInsetsOf(context).bottom == 0
          ? _ShareBar(
              title: appBasedRouting.share.invite,
              counts: [
                if (removed.isNotEmpty) appBasedRouting.share.removed(n: removed.length),
                if (added.isNotEmpty) appBasedRouting.share.added(n: added.length),
              ].join(' · '),
              label: t.common.share,
              onShare: openShare,
            )
          : null,
      appBar: isSearching.value
          ? AppBar(
              title: TextFormField(
                onChanged: (value) => searchQuery.value = value,
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
                  searchQuery.value = "";
                  isSearching.value = false;
                },
                icon: const Icon(Icons.close),
                tooltip: localizations.cancelButtonLabel,
              ),
              bottom: chips,
            )
          : AppBar(
              title: Text(mode?.listTitle(t) ?? t.pages.settings.routing.appBasedRouting.title),
              actions: [
                IconButton(
                  icon: const Icon(FluentIcons.search_24_regular),
                  onPressed: () => isSearching.value = true,
                  tooltip: localizations.searchFieldLabel,
                ),
                MenuAnchor(
                  menuChildren: <Widget>[
                    SubmenuButton(
                      menuChildren: <Widget>[
                        MenuItemButton(
                          child: Text(t.pages.settings.routing.appBasedRouting.options.import.clipboard),
                          onPressed: () async => await ref
                              .read(dialogNotifierProvider.notifier)
                              .showConfirmation(
                                title: t.common.msg.import.confirm,
                                message: t.dialogs.confirmation.appList.import.msg,
                              )
                              .then((shouldImport) async {
                                if (shouldImport) await ref.read(AppListProvider(mode).notifier).importClipboard();
                              }),
                        ),
                        MenuItemButton(
                          child: Text(t.pages.settings.routing.appBasedRouting.options.import.file),
                          onPressed: () async => await ref
                              .read(dialogNotifierProvider.notifier)
                              .showConfirmation(
                                title: t.pages.settings.routing.appBasedRouting.options.import.file,
                                message: t.pages.settings.routing.appBasedRouting.options.import.msg,
                              )
                              .then((shouldImport) async {
                                if (shouldImport) await ref.read(AppListProvider(mode).notifier).importFile();
                              }),
                        ),
                      ],
                      child: Text(t.common.import),
                    ),
                    SubmenuButton(
                      menuChildren: <Widget>[
                        MenuItemButton(
                          child: Text(t.pages.settings.routing.appBasedRouting.options.export.clipboard),
                          onPressed: () async => await ref.read(AppListProvider(mode).notifier).exportClipboard(),
                        ),
                        MenuItemButton(
                          child: Text(t.pages.settings.routing.appBasedRouting.options.export.file),
                          onPressed: () async => await ref.read(AppListProvider(mode).notifier).exportFile(),
                        ),
                      ],
                      child: Text(t.common.export),
                    ),
                    const PopupMenuDivider(),
                    MenuItemButton(
                      child: Text(t.pages.settings.routing.appBasedRouting.options.clearAllSelections),
                      onPressed: () => ref.read(AppListProvider(mode).notifier).clearAll(),
                    ),
                  ],
                  builder: (context, controller, child) => IconButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ),
              ],
              bottom: chips,
            ),
      floatingActionButton: showScrollToTop.value
          ? FloatingActionButton(
              onPressed: () =>
                  scrollController.animateTo(0.0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut),
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            )
          : null,
      body: displayedApps.when(
        data: (packages) => ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          controller: scrollController,
          itemBuilder: (context, index) {
            final package = packages[index];
            final flag = selectedApps.requireValue[package.packageName];
            return CheckboxListTile.adaptive(
              title: Row(
                children: [
                  Flexible(child: Text(package.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (flag != null && PkgFlag.autoSelection.check(flag)) ...[
                    const Gap(6),
                    Text(
                      t.pages.settings.routing.appBasedRouting.autoTag,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                package.packageName,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: flag == null ? false : PkgFlag.checkboxValue(flag),
              tristate: true,
              onChanged: (_) => ref.read(AppListProvider(mode).notifier).updatePkg(package.packageName),
              secondary: package.icon == null
                  ? null
                  : Image.memory(package.icon!, width: 48, height: 48, cacheWidth: 48, cacheHeight: 48),
            );
          },
          itemCount: packages.length,
        ),
        error: (error, _) => SliverErrorBodyPlaceholder(error.toString()),
        loading: () => const Center(child: PawSpinner()),
      ),
    );
  }
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.title, required this.counts, required this.label, required this.onShare});

  final String title;
  final String counts;
  final String label;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSecondaryContainer;
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(color: color)),
                    Text(counts, style: theme.textTheme.bodySmall?.copyWith(color: color)),
                  ],
                ),
              ),
              const Gap(8),
              FilledButton(onPressed: onShare, child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}
