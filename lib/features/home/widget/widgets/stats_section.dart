import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LiveStatsSection extends ConsumerWidget {
  const LiveStatsSection({
    required this.t,
    required this.isConnected,
    super.key,
  });

  final TranslationsEn t;
  final bool isConnected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trafficAsync = ref.watch(trafficStatsProvider);
    final pingAsync = ref.watch(realTimePingProvider);

    return StatsSection(
      t: t,
      isConnected: isConnected,
      uploadSpeed: trafficAsync.asData?.value.uploadSpeed ?? 0,
      downloadSpeed: trafficAsync.asData?.value.downloadSpeed ?? 0,
      ping: pingAsync.asData?.value,
      totalUp: trafficAsync.asData?.value.totalUpload ?? 0,
      totalDown: trafficAsync.asData?.value.totalDownload ?? 0,
    );
  }
}

class StatsSection extends StatelessWidget {
  const StatsSection({
    required this.t,
    required this.isConnected,
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.ping,
    required this.totalUp,
    required this.totalDown,
    super.key,
  });

  final TranslationsEn t;
  final bool isConnected;
  final int uploadSpeed;
  final int downloadSpeed;
  final int? ping;
  final int totalUp;
  final int totalDown;

  String _formatSpeed(int bytes) {
    if (bytes < 1024) return '$bytes B/s';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }

  String _formatTotal(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final cardColor = tokens.surface.card;

    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radius.lg),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.x5),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.arrow_upward_rounded,
                    iconColor: tokens.status.upload,
                    label: t.stats.uplink,
                    value: isConnected ? _formatSpeed(uploadSpeed) : '--',
                    colors: colors,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.arrow_downward_rounded,
                    iconColor: tokens.status.download,
                    label: t.stats.downlink,
                    value: isConnected ? _formatSpeed(downloadSpeed) : '--',
                    colors: colors,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colors.outlineVariant.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.speed_rounded,
                    iconColor: _pingColor(ping, tokens, colors),
                    label: 'Ping',
                    value: isConnected && ping != null ? '${ping}ms' : '--',
                    valueColor: _pingColor(ping, tokens, colors),
                    colors: colors,
                  ),
                ),
              ],
            ),
            if (isConnected && (totalUp > 0 || totalDown > 0)) ...[
              const Gap(16),
              Divider(
                color: colors.outlineVariant.withValues(alpha: 0.2),
                height: 1,
              ),
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    '↑ ${_formatTotal(totalUp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '↓ ${_formatTotal(totalDown)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _pingColor(int? ping, AppTokens tokens, ColorScheme colors) {
    if (ping == null || !isConnected) return colors.onSurfaceVariant;
    if (ping < 100) return tokens.status.success;
    if (ping < 300) return tokens.status.warning;
    return tokens.status.danger;
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 20, color: iconColor),
      const Gap(8),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: valueColor ?? colors.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      const Gap(4),
      Text(
        label,
        style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
      ),
    ],
  );
}
