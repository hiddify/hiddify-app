import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/core.dart' hide AppInfo;
import 'package:hiddify/features/per_app_proxy/per_app_proxy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PerAppProxyPage extends HookConsumerWidget {
  const PerAppProxyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perAppProxyMode = ref.watch(Preferences.perAppProxyMode);
    final installedAppsAsync = ref.watch(installedAppsProvider);
    final searchController = useTextEditingController();
    final searchTerm = useState('');

    useEffect(() {
      searchController.addListener(() {
        searchTerm.value = searchController.text.toLowerCase();
      });
      return null;
    }, [searchController]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Per-App Proxy'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              controller: searchController,
              leading: const Icon(Icons.search),
              hintText: 'Search apps...',
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<PerAppProxyMode>(
              segments: const [
                ButtonSegment(
                  value: PerAppProxyMode.off,
                  label: Text('Off'),
                  icon: Icon(Icons.power_off_rounded),
                ),
                ButtonSegment(
                  value: PerAppProxyMode.include,
                  label: Text('Include'),
                  icon: Icon(Icons.check_circle_outline_rounded),
                ),
                ButtonSegment(
                  value: PerAppProxyMode.exclude,
                  label: Text('Exclude'),
                  icon: Icon(Icons.block_rounded),
                ),
              ],
              selected: {perAppProxyMode},
              onSelectionChanged: (Set<PerAppProxyMode> newSelection) {
                ref
                    .read(Preferences.perAppProxyMode.notifier)
                    .update(newSelection.first);
              },
            ),
          ),
          if (perAppProxyMode != PerAppProxyMode.off)
            Expanded(
              child: installedAppsAsync.when(
                data: (apps) {
                  final filteredApps = apps.where((app) {
                    return app.name.toLowerCase().contains(searchTerm.value) ||
                        app.packageName.toLowerCase().contains(searchTerm.value);
                  }).toList();

                  if (filteredApps.isEmpty) {
                    return const Center(child: Text('No apps found'));
                  }

                  return ListView.builder(
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      return _AppListTile(app: app);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppListTile extends HookConsumerWidget {
  const _AppListTile({required this.app});

  final AppInfo app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyList = ref.watch(perAppProxyListProvider);
    final isSelected = proxyList.contains(app.packageName);
    final iconAsync = ref.watch(appIconProvider(app.packageName));

    return ListTile(
      leading: iconAsync.when(
        data: (icon) => icon != null
            ? Image.memory(icon, width: 40, height: 40)
            : const Icon(Icons.android),
        loading: () => const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, s) => const Icon(Icons.android),
      ),
      title: Text(app.name),
      subtitle: Text(app.packageName),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (bool? value) {
          final listNotifier = ref.read(perAppProxyListProvider.notifier);
          final currentList = [...proxyList];
          if (value == true) {
            currentList.add(app.packageName);
          } else {
            currentList.remove(app.packageName);
          }
          listNotifier.update(currentList);
        },
      ),
      onTap: () {
        final listNotifier = ref.read(perAppProxyListProvider.notifier);
        final currentList = [...proxyList];
        if (isSelected) {
          currentList.remove(app.packageName);
        } else {
          currentList.add(app.packageName);
        }
        listNotifier.update(currentList);
      },
    );
  }
}

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) {
  final service = ref.watch(perAppProxyServiceProvider);
  return service.getInstalledPackages();
});

final appIconProvider = FutureProvider.family<Uint8List?, String>((ref, packageName) {
  final service = ref.watch(perAppProxyServiceProvider);
  return service.getPackageIcon(packageName);
});
