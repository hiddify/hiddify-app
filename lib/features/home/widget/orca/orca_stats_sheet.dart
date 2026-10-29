import 'package:flutter/material.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'glass_kit.dart';
import 'orca_strings.dart';

/// Opens the live-stats sheet (download / upload speed and ping).
Future<void> showOrcaStatsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _StatsSheet(),
  );
}

String _speed(int bytesPerSecond) {
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  var v = bytesPerSecond.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}

class _StatsSheet extends ConsumerWidget {
  const _StatsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = OrcaStrings.of(context);
    final running = ref.watch(serviceRunningProvider);
    final stats = ref.watch(statsNotifierProvider).valueOrNull;
    final delay = ref.watch(activeProxyNotifierProvider).valueOrNull?.urlTestDelay ?? 0;

    final down = running ? (stats?.downlink.toInt() ?? 0) : 0;
    final up = running ? (stats?.uplink.toInt() ?? 0) : 0;
    final pingText = running && ConnectionConst.isValidDelay(delay) ? '$delay ms' : '—';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: GlassCard(
            radius: 30,
            blur: 30,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.statsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: OrcaColors.textPrimary,
                  ),
                ),
                if (!running) ...[
                  const SizedBox(height: 6),
                  Text(
                    s.notConnected,
                    style: const TextStyle(color: OrcaColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        icon: Icons.arrow_downward_rounded,
                        color: OrcaColors.cyan,
                        label: s.download,
                        value: _speed(down),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        icon: Icons.arrow_upward_rounded,
                        color: OrcaColors.pink,
                        label: s.upload,
                        value: _speed(up),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatTile(
                  icon: Icons.wifi_tethering_rounded,
                  color: OrcaColors.success,
                  label: s.ping,
                  value: pingText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: OrcaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: OrcaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
