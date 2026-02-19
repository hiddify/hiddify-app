import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/route_rules/notifier/android_apps_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:installed_apps/app_info.dart';

class AndroidAppsPage extends HookConsumerWidget {
  const AndroidAppsPage({super.key, this.ruleListOrder});

  final int? ruleListOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final searchController = useTextEditingController();
    ref.listen(searchQueryNotifierProvider, (_, next) => searchController.text = next);
    final focusNode = useFocusNode();
    ref.watch(appPackagesProvider);
    final selectedNotifier = SelectedPackagesNotifierProvider(ruleListOrder);
    final selected = ref.watch(selectedNotifier);
    final combinedList = ref.watch(FilterBySearchProvider(ruleListOrder));

    final menuItems = <PopupMenuItem>[
      if (ref.watch(hideSystemNotifierProvider))
        PopupMenuItem(
          onTap: ref.read(hideSystemNotifierProvider.notifier).show,
          child: Text(t.pages.settings.routing.routeRule.androidApps.showSystemApps),
        )
      else
        PopupMenuItem(
          onTap: ref.read(hideSystemNotifierProvider.notifier).hide,
          child: Text(t.pages.settings.routing.routeRule.androidApps.hideSystemApps),
        ),
      PopupMenuItem(
        onTap: ref.read(selectedNotifier.notifier).clearSelection,
        child: Text(t.pages.settings.routing.routeRule.androidApps.clearSelection),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.routing.routeRule.androidApps.pageTitle),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (_) => selected.isEmpty ? [menuItems.first] : menuItems,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kMinInteractiveDimension),
          child: TextField(
            focusNode: focusNode,
            controller: searchController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              label: Text(t.common.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        ref.read(searchQueryNotifierProvider.notifier).clear();
                        focusNode.unfocus();
                      },
                      icon: const Icon(Icons.cancel_outlined),
                    )
                  : null,
            ),
            onChanged: (value) => ref.read(searchQueryNotifierProvider.notifier).setQuery(value),
          ),
        ),
      ),
      body: combinedList.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is AppInfo) {
              final appInfo = item;
              return CheckboxListTile(
                title: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircleAvatar(backgroundColor: Colors.transparent, child: Image.memory(appInfo.icon!)),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appInfo.name, style: theme.textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
                          Text(appInfo.packageName, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                value: selected.contains(item.packageName),
                onChanged: (_) => ref.read(selectedNotifier.notifier).onChanged(item.packageName),
              );
            } else if (item is String) {
              final packageName = item;
              return CheckboxListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(size: 16, Icons.warning_rounded, color: Colors.amber),
                        const Gap(4),
                        Text(
                          t.pages.settings.routing.routeRule.androidApps.uninstalled,
                          style: theme.textTheme.bodyLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Text(packageName, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                  ],
                ),
                value: selected.contains(packageName),
                onChanged: (_) => ref.read(selectedNotifier.notifier).onChanged(packageName),
              );
            } else {
              throw Exception('Data type is not supported');
            }
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
