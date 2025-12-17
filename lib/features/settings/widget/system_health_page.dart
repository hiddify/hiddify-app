import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


class SystemHealthPage extends HookConsumerWidget {
  const SystemHealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final healthService = ref.watch(systemHealthProvider);
    final processManager = ref.watch(processManagerProvider);
    final processList = ref.watch(processListProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('System Health'),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Run Health Check',
                onPressed: () async {
                  await healthService.runFullHealthCheck();
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.health_and_safety_rounded,
                        title: 'Run Health Check',
                        color: Colors.green,
                        onTap: () async {
                          final results = await healthService
                              .runFullHealthCheck();
                          if (context.mounted) {
                            _showHealthResults(context, results);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.cleaning_services_rounded,
                        title: 'Clear Cache',
                        color: Colors.orange,
                        onTap: () {
                          PaintingBinding.instance.imageCache.clear();
                          PaintingBinding.instance.imageCache.clearLiveImages();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cache cleared')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Process Monitor',
                  icon: Icons.monitor_rounded,
                ),
                const SizedBox(height: 12),
                processList.when(
                  data: (Map<String, ProcessInfo> processes) => Column(
                    children: processes.entries.map((
                      MapEntry<String, ProcessInfo> entry,
                    ) {
                      final process = entry.value;
                      return _ProcessCard(
                        name: process.name,
                        status: process.status,
                        uptime: process.uptimeFormatted,
                        memory: process.memoryFormatted,
                        colorScheme: colorScheme,
                        onKill: () => processManager.killProcess(entry.key),
                      );
                    }).toList(),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (Object e, StackTrace _) => Text('Error: $e'),
                ),
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Debug Settings',
                  icon: Icons.bug_report_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'Debug Mode',
                      subtitle: 'Enable advanced debugging features',
                      icon: Icons.bug_report_rounded,
                      trailing: Switch(
                        value: ref.watch(DebugSettings.debugMode),
                        onChanged: (bool v) => ref
                            .read(DebugSettings.debugMode.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Verbose Logging',
                      subtitle: 'Log all system events',
                      icon: Icons.notes_rounded,
                      trailing: Switch(
                        value: ref.watch(DebugSettings.verboseLogging),
                        onChanged: (bool v) => ref
                            .read(DebugSettings.verboseLogging.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Performance Monitoring',
                      subtitle: 'Track CPU and memory usage',
                      icon: Icons.speed_rounded,
                      trailing: Switch(
                        value: ref.watch(DebugSettings.performanceMonitoring),
                        onChanged: (bool v) => ref
                            .read(
                              DebugSettings.performanceMonitoring.notifier,
                            )
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Log Network Requests',
                      subtitle: 'Debug network traffic',
                      icon: Icons.network_check_rounded,
                      trailing: Switch(
                        value: ref.watch(DebugSettings.logNetworkRequests),
                        onChanged: (bool v) => ref
                            .read(DebugSettings.logNetworkRequests.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Log DNS Queries',
                      subtitle: 'Debug DNS resolution',
                      icon: Icons.dns_rounded,
                      trailing: Switch(
                        value: ref.watch(DebugSettings.logDnsQueries),
                        onChanged: (bool v) => ref
                            .read(DebugSettings.logDnsQueries.notifier)
                            .update(v),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Log Routing Decisions',
                      subtitle: 'Debug traffic routing',
                      icon: Icons.alt_route_rounded,
                      trailing: Switch(
                        value: ref.watch(DebugSettings.logRoutingDecisions),
                        onChanged: (bool v) => ref
                            .read(DebugSettings.logRoutingDecisions.notifier)
                            .update(v),
                      ),
                    ),
                  ],
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  const AppSectionHeader(
                    title: 'Advanced Debug (Dev Only)',
                    icon: Icons.developer_mode_rounded,
                  ),
                  const SizedBox(height: 12),
                  AppSettingsCard(
                    children: [
                      AppSettingsTile(
                        title: 'Dump Memory',
                        subtitle: 'Export memory snapshot',
                        icon: Icons.memory_rounded,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 56),
                      AppSettingsTile(
                        title: 'Network Diagnostics',
                        subtitle: 'Run network tests',
                        icon: Icons.network_check_rounded,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 56),
                      AppSettingsTile(
                        title: 'Core Console',
                        subtitle: 'Direct core command interface',
                        icon: Icons.terminal_rounded,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 56),
                      AppSettingsTile(
                        title: 'Export Config JSON',
                        subtitle: 'Export current configuration',
                        icon: Icons.data_object_rounded,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 56),
                      AppSettingsTile(
                        title: 'Force Crash',
                        subtitle: 'Test crash reporting',
                        icon: Icons.warning_rounded,
                        isDanger: true,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.error,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const AppSectionHeader(
                  title: 'Logs',
                  icon: Icons.article_rounded,
                ),
                const SizedBox(height: 12),
                AppSettingsCard(
                  children: [
                    AppSettingsTile(
                      title: 'View Logs',
                      subtitle: 'Open log viewer',
                      icon: Icons.folder_open_rounded,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext _) => const LogViewerPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Export Logs',
                      subtitle: 'Share logs for debugging',
                      icon: Icons.share_rounded,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        try {
                          await ref.read(logServiceProvider).exportLogs();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to export logs: $e'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    AppSettingsTile(
                      title: 'Clear Logs',
                      subtitle: 'Delete all log files',
                      icon: Icons.delete_sweep_rounded,
                      isDanger: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await ref.read(logServiceProvider).clearLogs();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logs cleared')),
                          );
                        }
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

  void _showHealthResults(
    BuildContext context,
    List<HealthCheckResult> results,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      builder: (BuildContext context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) =>
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Health Check Results',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    itemBuilder: (BuildContext context, int index) {
                      final result = results[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            result.passed
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            color: result.passed
                                ? Colors.green
                                : colorScheme.error,
                          ),
                          title: Text(result.name),
                          subtitle: Text(result.message),
                          trailing: result.details != null
                              ? IconButton(
                                  icon: const Icon(Icons.info_outline_rounded),
                                  onPressed: () {
                                    showDialog<void>(
                                      context: context,
                                      builder: (BuildContext _) => AlertDialog(
                                        title: Text(result.name),
                                        content: Text(result.details!),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  const _ProcessCard({
    required this.name,
    required this.status,
    required this.uptime,
    required this.memory,
    required this.colorScheme,
    required this.onKill,
  });

  final String name;
  final ProcessStatus status;
  final String uptime;
  final String memory;
  final ColorScheme colorScheme;
  final VoidCallback onKill;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (status) {
      case ProcessStatus.running:
        statusColor = Colors.green;
        statusText = 'Running';
      case ProcessStatus.starting:
        statusColor = Colors.orange;
        statusText = 'Starting';
      case ProcessStatus.stopping:
        statusColor = Colors.orange;
        statusText = 'Stopping';
      case ProcessStatus.error:
        statusColor = colorScheme.error;
        statusText = 'Error';
      default:
        statusColor = colorScheme.onSurfaceVariant;
        statusText = 'Stopped';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$statusText • Uptime: $uptime • Memory: $memory',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (status == ProcessStatus.running)
              IconButton(
                icon: Icon(Icons.stop_rounded, color: colorScheme.error),
                onPressed: onKill,
                tooltip: 'Stop Process',
              ),
          ],
        ),
      ),
    );
  }
}
