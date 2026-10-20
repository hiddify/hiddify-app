import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/utils/number_formatters.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Latency (RTT) and live download/upload speed under the power button.
class HomeTrafficMonitor extends ConsumerWidget {
  const HomeTrafficMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final connected = ref.watch(connectionNotifierProvider.select((value) => value.valueOrNull is Connected));
    if (!connected) return const SizedBox(height: 48);

    final stats = ref.watch(statsNotifierProvider).asData?.value;
    final theme = Theme.of(context);

    Widget speed(IconData icon, String semantic, int bytesPerSecond) => Semantics(
      label: semantic,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const Gap(4),
          Text(bytesPerSecond.speed(), style: theme.textTheme.titleSmall),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        children: [
          const ActiveProxyDelayIndicator(),
          speed(FluentIcons.arrow_download_16_regular, t.components.stats.downlink, stats?.downlink.toInt() ?? 0),
          speed(FluentIcons.arrow_upload_16_regular, t.components.stats.uplink, stats?.uplink.toInt() ?? 0),
        ],
      ),
    );
  }
}

/// Fixed shortcut to the SpriteNet Telegram bot (keys, billing, support).
class TelegramSupportButton extends ConsumerWidget {
  const TelegramSupportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    return Tooltip(
      message: t.pages.home.supportHint,
      child: FilledButton.tonalIcon(
        key: const ValueKey("home_telegram_support"),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceContainer,
          foregroundColor: theme.colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
        ),
        onPressed: () => UriUtils.tryLaunch(Uri.parse(Constants.telegramBotUrl)),
        icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
        label: Text(t.pages.home.support.toUpperCase(), style: const TextStyle(letterSpacing: 1.2)),
      ),
    );
  }
}
