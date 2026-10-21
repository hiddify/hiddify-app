import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/app_based_routing/model/app_package_info.dart';
import 'package:hiddify/features/app_based_routing/overview/app_list_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Shows exactly what Share sends and where, before anything leaves the app.
class AppListShareModal extends ConsumerWidget {
  const AppListShareModal({super.key, required this.added, required this.removed, required this.apps});

  final List<String> added;
  final List<String> removed;
  final Map<String, AppPackageInfo> apps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final share = t.pages.settings.routing.appBasedRouting.share;
    final theme = Theme.of(context);
    final region = ref.watch(ConfigOptions.region);
    final mode = ref.watch(Preferences.perAppProxyMode);
    // decoded at the screen's density, so the icons stay sharp
    final iconPx = (32 * MediaQuery.devicePixelRatioOf(context)).round();

    Widget section(String title, List<String> pkgs) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 4),
          child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
        ),
        for (final pkg in pkgs)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
            leading: apps[pkg]?.icon == null
                ? const Icon(Icons.android_rounded)
                : Image.memory(apps[pkg]!.icon!, width: 32, height: 32, cacheWidth: iconPx, cacheHeight: iconPx),
            title: Text(apps[pkg]?.name ?? pkg),
            subtitle: Text(pkg),
          ),
      ],
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .6,
      maxChildSize: .9,
      builder: (context, scrollController) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(top: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(share.title, style: theme.textTheme.titleLarge),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '${region.presentName(t)} · ${mode.present(t)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                if (added.isNotEmpty) section(share.added(n: added.length), added),
                if (removed.isNotEmpty) section(share.removed(n: removed.length), removed),
              ],
            ),
          ),
          // the destination stays in view under any number of apps
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.public_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          share.where,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final appList = ref.read(AppListProvider(mode).notifier);
                        Navigator.of(context).pop();
                        await appList.shareOnGithub(added: added, removed: removed);
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(share.action),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
