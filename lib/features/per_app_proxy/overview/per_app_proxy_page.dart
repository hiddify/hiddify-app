import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/per_app_proxy/overview/per_app_proxy_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:installed_apps/index.dart';

class PerAppProxyPage extends HookConsumerWidget with PresLogger {
  const PerAppProxyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final localizations = MaterialLocalizations.of(context);

    final apps = ref.watch(appsProvider);
    final appsHideSystem = ref.watch(appsHideSystemProvider);

    final selectedApps = ref.watch(selectedAppsFilteredByModeProvider);
    final mode = ref.watch(Preferences.perAppProxyMode);

    final hideSystemApps = useState(false);
    final isSearching = useState(false);
    final searchQuery = useState("");

    final filteredPackages = useMemoized<AsyncValue<List<AppInfo>>>(
      () {
        final appsFilteredByHideSystem = hideSystemApps.value ? appsHideSystem : apps;
        if (searchQuery.value.isBlank) {
          return appsFilteredByHideSystem.whenData(
            (value) {
              value.sort(
                (a, b) {
                  final aInSelected = selectedApps.contains(a.packageName);
                  final bInSelected = selectedApps.contains(b.packageName);
                  if (aInSelected && !bInSelected) return -1;
                  if (!aInSelected && bInSelected) return 1;
                  return 0;
                },
              );
              return value;
            },
          );
        }
        return appsFilteredByHideSystem.whenData(
          (value) {
            Iterable<AppInfo> result = value;
            if (!searchQuery.value.isBlank) {
              result = result.filter(
                (e) => e.name.toLowerCase().contains(searchQuery.value.toLowerCase()),
              );
            }
            return result.toList();
          },
        );
      },
      [
        apps,
        appsHideSystem,
        hideSystemApps.value,
        searchQuery.value,
        mode,
      ],
    );

    return Scaffold(
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
            )
          : AppBar(
              title: Text(t.settings.network.perAppProxyPageTitle),
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
                          child: Text(t.settings.network.import.Clipboard),
                          onPressed: () async => await ref.read(selectedAppsFilteredByModeProvider.notifier).importFromClipboard(),
                        ),
                        MenuItemButton(
                          child: Text(t.settings.network.import.JsonFile),
                          onPressed: () async => await ref.read(selectedAppsFilteredByModeProvider.notifier).importFromJsonFile(),
                        ),
                      ],
                      child: Text(t.general.import),
                    ),
                    SubmenuButton(
                      menuChildren: <Widget>[
                        MenuItemButton(
                          child: Text(t.settings.network.export.Clipboard),
                          onPressed: () async => await ref.read(selectedAppsFilteredByModeProvider.notifier).exportJsonClipboard(),
                        ),
                        MenuItemButton(
                          child: Text(t.settings.network.export.JsonFile),
                          onPressed: () async => await ref.read(selectedAppsFilteredByModeProvider.notifier).exportJsonFile(),
                        ),
                      ],
                      child: Text(t.general.export),
                    ),
                    if (ref.watch(ConfigOptions.region) != Region.other) ...[
                      MenuItemButton(
                        child: Text(t.general.share),
                        onPressed: () async => await ref.read(selectedAppsFilteredByModeProvider.notifier).share(),
                      ),
                      const PopupMenuDivider(),
                      MenuItemButton(
                        child: Text(t.settings.network.autoSelection.title),
                        onPressed: () async => await ref.read(selectedAppsFilteredByModeProvider.notifier).autoSelection(),
                      ),
                    ],
                    MenuItemButton(
                      child: Text(t.settings.network.clearSelection),
                      onPressed: () => ref.read(selectedAppsFilteredByModeProvider.notifier).clearSelection(),
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      PopupMenuButton(
                        borderRadius: BorderRadius.circular(8),
                        position: PopupMenuPosition.under,
                        tooltip: mode.present(t).message,
                        initialValue: mode,
                        onSelected: (e) async {
                          await ref.read(Preferences.perAppProxyMode.notifier).update(e);
                          if (e == PerAppProxyMode.off && context.mounted) {
                            context.pop();
                          }
                        },
                        itemBuilder: (context) => PerAppProxyMode.values
                            .map(
                              (e) => PopupMenuItem(
                                value: e,
                                child: Text(e.present(t).message),
                              ),
                            )
                            .toList(),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: theme.colorScheme.surface,
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              )),
                          child: Row(
                            children: [
                              const Gap(16),
                              Text(mode.present(t).title),
                              const Gap(4),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const Gap(8),
                            ],
                          ),
                        ),
                      ),
                      const Gap(8),
                      ChoiceChip(
                        label: Text(t.settings.network.hideSystemApps),
                        selected: hideSystemApps.value,
                        onSelected: (value) => hideSystemApps.value = value,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: filteredPackages.when(
        data: (packages) => ListView.builder(
          itemBuilder: (context, index) {
            final package = packages[index];
            final selected = selectedApps.contains(package.packageName);
            return CheckboxListTile(
              title: Text(
                package.name,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                package.packageName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: selected,
              onChanged: (value) async {
                final List<String> newSelection;
                if (selected) {
                  newSelection = selectedApps.exceptElement(package.packageName).toList();
                } else {
                  newSelection = [
                    ...selectedApps,
                    package.packageName,
                  ];
                }
                await ref.read(selectedAppsFilteredByModeProvider.notifier).update(newSelection);
              },
              secondary: package.icon == null
                  ? null
                  : Image.memory(
                      package.icon!,
                      width: 48,
                      height: 48,
                      cacheWidth: 48,
                      cacheHeight: 48,
                    ),
            );
          },
          itemCount: packages.length,
        ),
        error: (error, _) => SliverErrorBodyPlaceholder(error.toString()),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
