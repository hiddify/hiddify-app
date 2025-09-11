import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/widget/adaptive_icon.dart';
import 'package:hiddify/features/per_app_proxy/model/installed_package_info.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/per_app_proxy/overview/per_app_proxy_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class PerAppProxyPage extends HookConsumerWidget with PresLogger {
  const PerAppProxyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final localizations = MaterialLocalizations.of(context);

    final asyncPackages = ref.watch(installedPackagesInfoProvider);
    final perAppProxyMode = ref.watch(Preferences.perAppProxyMode);
    final perAppProxyList = ref.watch(perAppProxyListProvider);

    final showSystemApps = useState(true);
    final isSearching = useState(false);
    final searchQuery = useState("");

    final filteredPackages = useMemoized(
      () {
        if (showSystemApps.value && searchQuery.value.isBlank) {
          return asyncPackages;
        }
        return asyncPackages.whenData(
          (value) {
            Iterable<InstalledPackageInfo> result = value;
            if (!showSystemApps.value) {
              result = result.filter((e) => !e.isSystemApp);
            }
            if (!searchQuery.value.isBlank) {
              result = result.filter(
                (e) => e.name
                    .toLowerCase()
                    .contains(searchQuery.value.toLowerCase()),
              );
            }
            return result.toList();
          },
        );
      },
      [asyncPackages, showSystemApps.value, searchQuery.value],
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
                PopupMenuButton(
                  icon: Icon(AdaptiveIcon(context).more),
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        child: Text(
                          showSystemApps.value
                              ? t.settings.network.hideSystemApps
                              : t.settings.network.showSystemApps,
                        ),
                        onTap: () =>
                            showSystemApps.value = !showSystemApps.value,
                      ),
                      PopupMenuItem(
                        child: Text(t.settings.network.clearSelection),
                        onTap: () => ref
                            .read(perAppProxyListProvider.notifier)
                            .update([]),
                      ),
                    ];
                  },
                ),
              ],
            ),
      body: CustomScrollView(
        slivers: [
          SliverPinnedHeader(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(
                children: [
                  ...PerAppProxyMode.values.map(
                    (e) => RadioListTile<PerAppProxyMode>(
                      title: Text(e.present(t).message),
                      dense: true,
                      value: e,
                      groupValue: perAppProxyMode,
                      onChanged: (value) async {
                        await ref
                            .read(Preferences.perAppProxyMode.notifier)
                            .update(e);
                        if (e == PerAppProxyMode.off && context.mounted) {
                          context.pop();
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
          switch (filteredPackages) {
            AsyncData(value: final packages) => SliverList.builder(
                itemBuilder: (context, index) {
                  final package = packages[index];
                  final selected =
                      perAppProxyList.contains(package.packageName);
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
                        newSelection = perAppProxyList
                            .exceptElement(package.packageName)
                            .toList();
                      } else {
                        newSelection = [
                          ...perAppProxyList,
                          package.packageName,
                        ];
                      }
                      await ref
                          .read(perAppProxyListProvider.notifier)
                          .update(newSelection);
                    },
                    secondary: SizedBox(
                      width: 48,
                      height: 48,
                      child: ref
                          .watch(packageIconProvider(package.packageName))
                          .when(
                            data: (data) => Image(image: data),
                            error: (error, _) =>
                                const Icon(FluentIcons.error_circle_24_regular),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                    ),
                  );
                },
                itemCount: packages.length,
              ),
            AsyncLoading() => const SliverLoadingBodyPlaceholder(),
            AsyncError(:final error) =>
              SliverErrorBodyPlaceholder(error.toString()),
            _ => const SliverToBoxAdapter(),
          },
        ],
      ),
    );
  }
}
