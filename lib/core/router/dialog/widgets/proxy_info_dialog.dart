import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/upload_speed.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A proxy at a glance: who it is and where it leads, then its ping, upload and download speed,
/// each tested on a tap. The values follow the core while the dialog is open.
class ProxyInfoDialog extends ConsumerWidget {
  const ProxyInfoDialog({super.key, required this.outboundInfo});

  final OutboundInfo outboundInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    // the proxy as the core reports it now, so a test's result shows: from the proxies list, or, for
    // the home card's server and chain hop, which that list may not hold, from the main list
    final proxy =
        ref.watch(
          proxiesOverviewNotifierProvider.select(
            (list) => list.valueOrNull?.items.where((e) => e.tag == outboundInfo.tag).firstOrNull,
          ),
        ) ??
        ref.watch(
          mainOutboundsNotifierProvider.select((list) {
            final main = list.valueOrNull;
            if (main == null) return null;
            if (main.hasChainHop() && main.chainHop.tag == outboundInfo.tag) return main.chainHop;
            return main.items.expand((group) => group.items).where((e) => e.tag == outboundInfo.tag).firstOrNull;
          }),
        ) ??
        outboundInfo;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      title: _Header(proxy),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(child: OutboundInfoWidget(outboundInfo: proxy)),
      ),
      actions: [TextButton(onPressed: context.pop, child: Text(t.common.close))],
    );
  }
}

/// The flag, the name, and what the proxy is and how it stands.
class _Header extends ConsumerWidget {
  const _Header(this.proxy);

  final OutboundInfo proxy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final (String status, Color color) = switch (proxy.status) {
      Status.CONNECTING => (t.pages.proxies.status.connecting, s.primary),
      Status.REGISTERING => (t.pages.proxies.status.registering, s.primary),
      Status.SEARCHING => (t.pages.proxies.status.searching, s.primary),
      Status.RECONNECTING => (t.pages.proxies.status.reconnecting, dark ? Colors.orange : Colors.deepOrange),
      Status.FAILED => (t.pages.proxies.status.failed, s.error),
      _ => (t.pages.proxies.status.ready, dark ? Colors.lightGreen : Colors.green.shade700),
    };
    return Row(
      children: [
        IPCountryFlag(countryCode: proxy.ipinfo.countryCode, organization: proxy.ipinfo.org, size: 48),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(proxy.tagDisplay, maxLines: 2, style: theme.textTheme.titleMedium),
              const Gap(6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (proxy.typeWithoutStatus.isNotEmpty)
                    _Chip(text: proxy.typeWithoutStatus, color: s.onSurfaceVariant),
                  _Chip(text: status, color: color, dot: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, this.dot = false});

  final String text;
  final Color color;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const Gap(5),
          ],
          Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, letterSpacing: .3)),
        ],
      ),
    );
  }
}

/// Why the proxy failed, when the core says, then where it leads, then its speeds.
class OutboundInfoWidget extends ConsumerWidget {
  const OutboundInfoWidget({super.key, required this.outboundInfo});

  final OutboundInfo outboundInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final info = t.dialogs.proxyInfo;
    final theme = Theme.of(context);
    final proxy = outboundInfo;
    final ip = proxy.ipinfo;
    final server = proxy.host.isEmpty ? '' : (proxy.port == 0 ? proxy.host : '${proxy.host}:${proxy.port}');
    final rows = [
      if (ip.ip.isNotEmpty) (FluentIcons.globe_24_regular, info.ip, ip.ip),
      if (ip.countryCode.isNotEmpty) (FluentIcons.flag_24_regular, info.country, ip.countryCode),
      if (ip.org.isNotEmpty) (FluentIcons.building_24_regular, info.organization, ip.org),
      if (server.isNotEmpty) (FluentIcons.server_24_regular, info.server, server),
      if (proxy.tag != proxy.tagDisplay) (FluentIcons.tag_24_regular, info.fullTag, proxy.tag),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (proxy.error.isNotEmpty) ...[_FailureReason(title: info.error, reason: proxy.error), const Gap(12)],
        if (rows.isNotEmpty) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final (i, (icon, title, value)) in rows.indexed) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 40, color: theme.colorScheme.outlineVariant.withValues(alpha: .5)),
                  _InfoRow(icon: icon, title: title, value: value),
                ],
              ],
            ),
          ),
          const Gap(18),
        ],
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(
            info.speed,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: .3),
          ),
        ),
        const Gap(8),
        _Speeds(proxy),
      ],
    );
  }
}

/// The error of the proxy's last URL test, or why it is not ready, as the core reports it.
class _FailureReason extends StatelessWidget {
  const _FailureReason({required this.title, required this.reason});

  final String title;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: s.errorContainer.withValues(alpha: .6), borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.error_circle_24_regular, size: 18, color: s.onErrorContainer),
                const Gap(8),
                Text(title, style: theme.textTheme.labelLarge?.copyWith(color: s.onErrorContainer)),
              ],
            ),
            const Gap(6),
            // the core's own words, left to right: they are English and full of addresses
            SelectableText(
              reason,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall?.copyWith(color: s.onErrorContainer, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: s.primary),
          const Gap(10),
          Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
          const Gap(12),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ping, upload and download, side by side; a tap on one tests it, a long press on a speed sets how
/// much its test moves. A group's speeds are those of the proxy it uses, tested from that proxy.
class _Speeds extends ConsumerWidget {
  const _Speeds(this.proxy);

  final OutboundInfo proxy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final info = t.dialogs.proxyInfo;
    final notifier = ref.read(proxiesOverviewNotifierProvider.notifier);
    final dark = Theme.of(context).brightness == Brightness.dark;
    // a ping from the previous run comes only as the sort delay until this run tests the proxy
    final pingCached = proxy.urlTestDelay == 0 && proxy.sortDelay > 0;
    final delay = pingCached ? proxy.sortDelay : proxy.urlTestDelay;
    final pingColor = switch (delay) {
      < 800 => dark ? Colors.lightGreen : Colors.green,
      < 1500 => dark ? Colors.orange : Colors.deepOrangeAccent,
      _ => dark ? Colors.redAccent : Colors.red,
    };

    Widget speed({required bool download}) {
      final value = (download ? proxy.downloadSpeed : proxy.uploadSpeed).toInt();
      return _SpeedTile(
        icon: download ? FluentIcons.arrow_download_24_regular : FluentIcons.arrow_upload_24_regular,
        label: download ? info.download : info.upload,
        value: value > 0 ? formatMbps(value) : null,
        unit: 'Mbps',
        color: value > 0 ? uploadSpeedColor(context, value) : null,
        failed: value < 0,
        cached: download ? proxy.downloadSpeedCached : proxy.uploadSpeedCached,
        testing: download ? proxy.downloadTesting : proxy.uploadTesting,
        hint: proxy.isGroup ? null : info.tapToTest,
        onTap: proxy.isGroup
            ? null
            : () => download ? notifier.downloadTest(proxy.tag) : notifier.uploadTest(proxy.tag),
        onLongPress: () => chooseUploadTestSize(ref),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _SpeedTile(
            icon: FluentIcons.wifi_1_24_regular,
            label: info.ping,
            value: delay > 0 && delay < 65000 ? '$delay' : null,
            unit: 'ms',
            color: pingColor,
            failed: delay >= 65000 && !pingCached,
            cached: pingCached,
            hint: info.tapToTest,
            onTap: () => notifier.urlTest(proxy.tag),
          ),
        ),
        const Gap(8),
        Expanded(child: speed(download: false)),
        const Gap(8),
        Expanded(child: speed(download: true)),
      ],
    );
  }
}

/// One measure: its icon and name, then the value in its color, a spinner while it is tested, or
/// what a tap does before the first test. A value from an earlier run ([cached]) is faded, as in the
/// proxy list, until a test of this run replaces it.
class _SpeedTile extends StatelessWidget {
  const _SpeedTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.failed,
    this.cached = false,
    this.testing = false,
    this.hint,
    this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String unit;
  final Color? color;
  final bool failed;
  final bool cached;
  final bool testing;
  final String? hint;

  static const _cachedOpacity = .45;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final tint = failed ? s.error : (value != null ? color! : s.primary);
    final old = cached && value != null;
    final Widget reading = switch ((testing, value, failed)) {
      (true, _, _) => SizedBox.square(
        key: const ValueKey('testing'),
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: s.primary),
      ),
      // a long reading shrinks to fit the tile
      (_, final value?, _) => Opacity(
        key: ValueKey((value, old)),
        opacity: old ? _cachedOpacity : 1,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: theme.textTheme.labelSmall?.copyWith(color: s.onSurfaceVariant),
                ),
              ],
            ),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
      (_, _, true) => Icon(Icons.close_rounded, key: const ValueKey('failed'), size: 24, color: s.error),
      _ => Text(
        hint ?? '—',
        key: const ValueKey('hint'),
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(color: s.primary, letterSpacing: .3),
      ),
    };
    return Material(
      color: Color.alphaBlend(
        tint.withValues(alpha: old ? .06 : (value != null || failed ? .12 : .06)),
        s.surfaceContainerHigh,
      ),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: testing ? null : onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: old ? tint.withValues(alpha: _cachedOpacity) : tint),
                  const Gap(4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              SizedBox(
                height: 30,
                child: Center(
                  child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: reading),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
