import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/features/stats/widget/stats_card.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/number_formatters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TrafficDashboardPage extends HookConsumerWidget with InfraLogger {
  const TrafficDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final stats = ref.watch(statsNotifierProvider);
    final systemInfo = stats.asData?.value ?? SystemInfo.create();
    final connectionState = ref.watch(
      connectionNotifierProvider.select((value) => value.valueOrNull),
    );
    final isConnected = connectionState is Connected;
    final activeProxy = ref.watch(activeProxyNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.dashboard.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Card
            _ConnectionStatusCard(
              isConnected: isConnected,
              activeProxy: activeProxy,
              currentOutbound: systemInfo.currentOutbound,
              currentProfile: systemInfo.currentProfile,
            ),
            const Gap(12),

            // Real-time Speed Section
            Text(
              t.pages.dashboard.realtimeSpeed,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            Row(
              children: [
                Expanded(
                  child: _SpeedCard(
                    icon: const Icon(FluentIcons.arrow_upload_16_regular),
                    label: t.components.stats.uplink,
                    value: systemInfo.uplink.toInt().speed(),
                    color: Colors.green,
                    isConnected: isConnected,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _SpeedCard(
                    icon: const Icon(FluentIcons.arrow_download_16_regular),
                    label: t.components.stats.downlink,
                    value: systemInfo.downlink.toInt().speed(),
                    color: Colors.blue,
                    isConnected: isConnected,
                  ),
                ),
              ],
            ),
            const Gap(12),

            // Total Traffic Section
            Text(
              t.components.stats.trafficTotal,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            StatsCard(
              stats: [
                (
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(FluentIcons.arrow_upload_16_regular, size: 14, color: Colors.green),
                      const Gap(4),
                      Text(t.components.stats.uplink, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  data: Text(
                    systemInfo.uplinkTotal.toInt().size(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  semanticLabel: t.components.stats.uplink,
                ),
                (
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(FluentIcons.arrow_download_16_regular, size: 14, color: Colors.blue),
                      const Gap(4),
                      Text(t.components.stats.downlink, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  data: Text(
                    systemInfo.downlinkTotal.toInt().size(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  semanticLabel: t.components.stats.downlink,
                ),
              ],
            ),
            const Gap(12),

            // System Info Section
            Text(
              t.pages.dashboard.systemInfo,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            _SystemInfoCard(systemInfo: systemInfo),
            const Gap(12),

            // Traffic Progress Bar
            if (systemInfo.trafficAvailable && systemInfo.uplinkTotal > 0)
              _TrafficBarCard(systemInfo: systemInfo),
          ],
        ),
      ),
    );
  }
}

class _ConnectionStatusCard extends HookConsumerWidget {
  const _ConnectionStatusCard({
    required this.isConnected,
    this.activeProxy,
    required this.currentOutbound,
    required this.currentProfile,
  });

  final bool isConnected;
  final OutboundInfo? activeProxy;
  final String currentOutbound;
  final String currentProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.green : Colors.grey,
                  ),
                ),
                const Gap(8),
                Text(
                  isConnected ? t.pages.dashboard.connected : t.pages.dashboard.disconnected,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (activeProxy != null) ...[
                  IPCountryFlag(
                    countryCode: activeProxy!.ipinfo.countryCode,
                    organization: activeProxy!.ipinfo.org,
                    size: 24,
                  ),
                ],
              ],
            ),
            if (isConnected) ...[
              const Gap(12),
              if (currentOutbound.isNotEmpty)
                _InfoRow(
                  icon: const Icon(FluentIcons.arrow_routing_20_regular, size: 16),
                  label: t.pages.dashboard.currentOutbound,
                  value: activeProxy?.tagDisplay ?? currentOutbound,
                ),
              if (currentProfile.isNotEmpty) ...[
                const Gap(4),
                _InfoRow(
                  icon: const Icon(FluentIcons.person_20_regular, size: 16),
                  label: t.pages.dashboard.currentProfile,
                  value: currentProfile,
                ),
              ],
              if (activeProxy?.ipinfo.ip.isNotEmpty == true) ...[
                const Gap(4),
                _InfoRow(
                  icon: const Icon(FluentIcons.globe_20_regular, size: 16),
                  label: t.pages.proxies.ipInfo.address,
                  value: activeProxy!.ipinfo.ip,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        icon,
        const Gap(8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _SpeedCard extends StatelessWidget {
  const _SpeedCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isConnected,
  });

  final Widget icon;
  final String label;
  final String value;
  final Color color;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTheme(data: IconThemeData(color: color, size: 18), child: icon),
                const Gap(6),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
            const Gap(8),
            Text(
              isConnected ? value : '--',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemInfoCard extends HookConsumerWidget {
  const _SystemInfoCard({required this.systemInfo});

  final SystemInfo systemInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SystemInfoRow(
              icon: const Icon(FluentIcons.plug_connected_20_regular, size: 16),
              label: t.pages.dashboard.connectionsIn,
              value: '${systemInfo.connectionsIn}',
            ),
            const Gap(6),
            _SystemInfoRow(
              icon: const Icon(FluentIcons.plug_disconnected_20_regular, size: 16),
              label: t.pages.dashboard.connectionsOut,
              value: '${systemInfo.connectionsOut}',
            ),
            const Gap(6),
            _SystemInfoRow(
              icon: const Icon(FluentIcons.ram_20_regular, size: 16),
              label: t.pages.dashboard.memoryUsage,
              value: systemInfo.memory.toInt().size(),
            ),
            const Gap(6),
            _SystemInfoRow(
              icon: const Icon(FluentIcons.settings_20_regular, size: 16),
              label: t.pages.dashboard.goroutines,
              value: '${systemInfo.goroutines}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemInfoRow extends StatelessWidget {
  const _SystemInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const Gap(8),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontFamily: 'monospace')),
      ],
    );
  }
}

class _TrafficBarCard extends HookConsumerWidget {
  const _TrafficBarCard({required this.systemInfo});

  final SystemInfo systemInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final totalUsed = systemInfo.uplinkTotal.toInt() + systemInfo.downlinkTotal.toInt();
    final downloadRatio = systemInfo.downlinkTotal.toInt() / (totalUsed > 0 ? totalUsed : 1);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.pages.dashboard.trafficDistribution,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  flex: (downloadRatio * 100).round().clamp(1, 99),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Gap(2),
                Expanded(
                  flex: (100 - (downloadRatio * 100).round()).clamp(1, 99),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                    const Gap(4),
                    Text('${t.components.stats.downlink}: ${systemInfo.downlinkTotal.toInt().size()}', style: theme.textTheme.bodySmall),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const Gap(4),
                    Text('${t.components.stats.uplink}: ${systemInfo.uplinkTotal.toInt().size()}', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
