import 'package:flutter/material.dart';
import 'package:hiddify/core/core.dart';
import 'package:hiddify/features/settings/settings.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ResourceManagerPage extends HookConsumerWidget {
  const ResourceManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resourceManager = ref.watch(resourceManagerProvider);
    final resourceStatus = ref.watch(resourceStatusProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Resource Manager'),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () async {
                  await resourceManager.checkForUpdates();
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!resourceManager.allRequiredAvailable)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Some required resources are missing',
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () async {
                            await resourceManager.downloadAllRequired();
                          },
                          child: const Text('Download All'),
                        ),
                      ],
                    ),
                  ),
                const AppSectionHeader(
                  title: 'Routing Assets',
                  icon: Icons.public_rounded,
                ),
                const SizedBox(height: 12),
                _ResourceCard(
                  name: 'GeoIP Database',
                  description: 'IP geolocation for routing decisions',
                  icon: Icons.location_on_rounded,
                  colorScheme: colorScheme,
                  status: resourceStatus.when(
                    data: (Map<ResourceType, ResourceInfo> data) =>
                        data[ResourceType.geoip]?.status ??
                        ResourceStatus.notDownloaded,
                    loading: () => ResourceStatus.notDownloaded,
                    error: (Object _, StackTrace _) => ResourceStatus.error,
                  ),
                  progress: resourceStatus.when(
                    data: (Map<ResourceType, ResourceInfo> data) => data[ResourceType.geoip]?.progress ?? 0,
                    loading: () => 0,
                    error: (Object _, StackTrace _) => 0,
                  ),
                  onDownload: () =>
                      resourceManager.downloadResource(ResourceType.geoip),
                  onDelete: () =>
                      resourceManager.deleteResource(ResourceType.geoip),
                ),
                const SizedBox(height: 12),
                _ResourceCard(
                  name: 'GeoSite Database',
                  description: 'Domain categorization for routing',
                  icon: Icons.domain_rounded,
                  colorScheme: colorScheme,
                  status: resourceStatus.when(
                    data: (Map<ResourceType, ResourceInfo> data) =>
                        data[ResourceType.geosite]?.status ??
                        ResourceStatus.notDownloaded,
                    loading: () => ResourceStatus.notDownloaded,
                    error: (Object _, StackTrace _) => ResourceStatus.error,
                  ),
                  progress: resourceStatus.when(
                    data: (Map<ResourceType, ResourceInfo> data) => data[ResourceType.geosite]?.progress ?? 0,
                    loading: () => 0,
                    error: (Object _, StackTrace _) => 0,
                  ),
                  onDownload: () =>
                      resourceManager.downloadResource(ResourceType.geosite),
                  onDelete: () =>
                      resourceManager.deleteResource(ResourceType.geosite),
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Core Components',
                  icon: Icons.memory_rounded,
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Xray Core',
                  subtitle: 'Bundled with application',
                  icon: Icons.check_circle_rounded,
                  iconColor: Colors.green,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Region Settings',
                  icon: Icons.flag_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Your Region',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This helps optimize routing rules and download region-specific assets.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _RegionChip(label: 'Iran 🇮🇷', value: 'ir'),
                              _RegionChip(label: 'China 🇨🇳', value: 'cn'),
                              _RegionChip(label: 'Russia 🇷🇺', value: 'ru'),
                              _RegionChip(label: 'Turkey 🇹🇷', value: 'tr'),
                              _RegionChip(label: 'Global 🌍', value: 'global'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Update Settings',
                  icon: Icons.update_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Auto-update resources',
                      subtitle: 'Download updates automatically',
                      icon: Icons.autorenew_rounded,
                      trailing: Switch(
                        value: ref.watch(ResourcePreferences.autoUpdateResources),
                        onChanged: (v) => ref
                            .read(
                              ResourcePreferences.autoUpdateResources.notifier,
                            )
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Use beta versions',
                      subtitle: 'Get early access to new features',
                      icon: Icons.science_rounded,
                      trailing: Switch(
                        value: ref.watch(ResourcePreferences.useBetaVersions),
                        onChanged: (v) => ref
                            .read(ResourcePreferences.useBetaVersions.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Update frequency',
                      subtitle: ref
                          .watch(ResourcePreferences.updateFrequency)
                          .toUpperCase(),
                      icon: Icons.schedule_rounded,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (context) => Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Update Frequency',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                for (final freq in [
                                  'daily',
                                  'weekly',
                                  'monthly',
                                ])
                                  ListTile(
                                    title: Text(freq.toUpperCase()),
                                    trailing: ref.watch(
                                              ResourcePreferences
                                                  .updateFrequency,
                                            ) ==
                                            freq
                                        ? const Icon(Icons.check_circle_rounded)
                                        : null,
                                    onTap: () {
                                      ref
                                          .read(
                                            ResourcePreferences
                                                .updateFrequency.notifier,
                                          )
                                          .update(freq);
                                      Navigator.pop(context);
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.colorScheme,
    required this.status,
    required this.progress,
    required this.onDownload,
    required this.onDelete,
  });

  final String name;
  final String description;
  final IconData icon;
  final ColorScheme colorScheme;
  final ResourceStatus status;
  final double progress;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status, colorScheme: colorScheme),
            ],
          ),
          if (status == ResourceStatus.downloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == ResourceStatus.downloaded)
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              const SizedBox(width: 8),
              if (status != ResourceStatus.downloading)
                FilledButton.icon(
                  onPressed: onDownload,
                  icon: Icon(
                    status == ResourceStatus.downloaded
                        ? Icons.refresh_rounded
                        : Icons.download_rounded,
                  ),
                  label: Text(
                    status == ResourceStatus.downloaded ? 'Update' : 'Download',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.colorScheme});

  final ResourceStatus status;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    IconData icon;
    String text;

    switch (status) {
      case ResourceStatus.downloaded:
        bgColor = Colors.green.withValues(alpha: 0.2);
        fgColor = Colors.green;
        icon = Icons.check_circle_rounded;
        text = 'Ready';
      case ResourceStatus.downloading:
        bgColor = colorScheme.primaryContainer;
        fgColor = colorScheme.onPrimaryContainer;
        icon = Icons.downloading_rounded;
        text = 'Downloading';
      case ResourceStatus.updateAvailable:
        bgColor = Colors.orange.withValues(alpha: 0.2);
        fgColor = Colors.orange;
        icon = Icons.update_rounded;
        text = 'Update Available';
      case ResourceStatus.error:
        bgColor = colorScheme.errorContainer;
        fgColor = colorScheme.onErrorContainer;
        icon = Icons.error_rounded;
        text = 'Error';
      default:
        bgColor = colorScheme.surfaceContainerHigh;
        fgColor = colorScheme.onSurfaceVariant;
        icon = Icons.download_rounded;
        text = 'Not Downloaded';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.colorScheme,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: false,
      onSelected: (selected) {},
    );
  }
}
