import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/adaptive_menu.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/features/chain/overview/chain_mode_icon.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActiveProxyFooter extends HookConsumerWidget with InfraLogger {
  const ActiveProxyFooter({super.key});

  /// Same window as ConnectionButton's held connected look: a brief Disconnected
  /// blip on resume must not collapse this footer or the connect button jumps.
  static const _hold = Duration(milliseconds: 1500);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(
      connectionNotifierProvider.select((value) => value.valueOrNull ?? const Disconnected()),
    );

    final activeCard = ref.watch(activeProxyCardProvider);

    final heldCard = useRef<ActiveProxyCardData?>(null);
    final until = useRef<DateTime?>(null);
    final rebuild = useState(0);

    // Intentional disconnect and a new Connecting must clear immediately — otherwise
    // a held card with an empty IP shows "Unknown IP" under Connecting… (#2395).
    // Only hold across a Connected→Disconnected blip (e.g. resume).
    final clearCard =
        connectionState is Disconnecting || connectionState is Disconnected || connectionState is Connecting;
    final live = connectionState.isRunning && activeCard != null;
    ActiveProxyCardData? card;
    if (live) {
      heldCard.value = activeCard;
      until.value = null;
      card = activeCard;
    } else if (clearCard) {
      heldCard.value = null;
      until.value = null;
      card = null;
    } else if (heldCard.value != null) {
      until.value ??= DateTime.now().add(_hold);
      if (DateTime.now().isBefore(until.value!)) {
        card = heldCard.value;
      } else {
        heldCard.value = null;
        until.value = null;
      }
    }
    useEffect(() {
      final end = until.value;
      if (end == null) return null;
      final timer = Timer(end.difference(DateTime.now()), () => rebuild.value++);
      return timer.cancel;
    }, [until.value]);

    if (card == null) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [if (!card.chain.isOff()) _ChainBand(card), _ProxyRow(card)],
      ),
    );
  }
}

// ---------- the chain band: chain type at the start, the hop at the end ----------

/// The band shows only while the chain is on, so its type is one of the two.
ChainType _typeOf(ActiveProxyCardData card) => card.chain.isUnblocker() ? ChainType.unblocker : ChainType.extraSecurity;

class _ChainBand extends StatelessWidget {
  const _ChainBand(this.card);
  final ActiveProxyCardData card;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final (main, _) = _typeOf(card).colors(card.hopMode);
    final background = Color.alphaBlend(main.withValues(alpha: .16), s.surfaceContainerHigh);
    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 16, 4),
        child: SizedBox(
          // one height for every chain and hop
          height: 40,
          // On narrow screens the hop first drops its name (the flag's badge still shows it), then
          // the pill's label shortens. The IP shortens only once the pill is down to its icon.
          child: LayoutBuilder(
            builder: (context, box) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _ChainPill(card)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: max(0, box.maxWidth - _ChainPill.iconOnlyWidth)),
                  child: _HopChip(card, background: background, showName: box.maxWidth >= 360),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The chain type with its animated icon; opens the chain settings.
class _ChainPill extends ConsumerWidget {
  const _ChainPill(this.card);
  final ActiveProxyCardData card;

  /// Its width with no room left for the label: its paddings, icon and gap.
  static const iconOnlyWidth = 8.0 + 12 + 22 + 6 + 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final type = _typeOf(card);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: Material(
        color: s.onSurface.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => context.goNamed('chainOptions'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChainTypeIcon(type: type, mode: card.hopMode),
                const Gap(6),
                Flexible(
                  child: Text(
                    type.present(t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(color: s.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The hop: its exit flag with the mode as a badge, its name, its IP and its state.
class _HopChip extends ConsumerWidget {
  const _HopChip(this.card, {required this.background, required this.showName});
  final ActiveProxyCardData card;
  final Color background;
  final bool showName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    // the chip's own color, so the badge's ring cuts cleanly into the flag
    final chipColor = Color.alphaBlend(s.onSurface.withValues(alpha: .10), background);
    // centred on the flag's bottom-end corner: the 28 px slot draws a 20 px flag, inset 4 px
    const badge = 14.0;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 10, 2),
      // its start keeps it apart from the pill
      margin: const EdgeInsetsDirectional.fromSTEB(8, 4, 0, 4),
      decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _FlagSlot(card.hop, size: 28, radius: 4),
              PositionedDirectional(
                end: 4 - badge / 2,
                bottom: 4 - badge / 2,
                child: Container(
                  width: badge,
                  height: badge,
                  decoration: BoxDecoration(
                    color: chipColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: chipColor, width: 1.5),
                  ),
                  child: ChainModeIcon(mode: card.hopMode, size: 10),
                ),
              ),
            ],
          ),
          if (showName) ...[
            const Gap(6),
            Text(card.hopMode.present(t), style: theme.textTheme.labelLarge?.copyWith(color: s.onSurface)),
          ],
          const Gap(10),
          Flexible(child: _IpSlot(card.hop, boneWidth: 52, isFinal: card.chain.isExtraSecurity())),
          const Gap(8),
          _HopState(card.hop?.status),
        ],
      ),
    );
  }
}

/// The hop's state in a fixed slot as wide as the check, so the text before it never moves.
class _HopState extends StatelessWidget {
  const _HopState(this.status);

  /// Null before the core lists the hop.
  final Status? status;

  static const size = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: size,
      child: switch (status) {
        Status.READY => Icon(
          Icons.check_circle_rounded,
          size: size,
          color: theme.extension<ConnectionButtonTheme>()!.connectedColor,
        ),
        Status.FAILED => Icon(Icons.error_rounded, size: size, color: theme.colorScheme.error),
        // not listed yet, connecting, reconnecting, searching, registering
        _ => Center(
          child: SizedBox(
            // as wide as the check's circle, which fills 20 of an icon's 24 units
            width: size * 20 / 24,
            child: LinearProgressIndicator(
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: .25),
            ),
          ),
        ),
      },
    );
  }
}

// ---------- the proxy row: how the server was picked, its name, IP and protocol ----------

class _ProxyRow extends ConsumerWidget {
  const _ProxyRow(this.card);
  final ActiveProxyCardData card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final server = card.server;
    final muted = theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant);
    final nameStyle = theme.textTheme.titleMedium?.copyWith(fontSize: 14);
    final group = card.group;

    Future<void> urlTest() => ref.read(activeProxyNotifierProvider.notifier).urlTest("");

    return ListTile(
      onTap: () => context.goNamed('proxies'),
      leading: InkWell(
        onTap: () async {
          await urlTest();
          await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: server);
        },
        borderRadius: BorderRadius.circular(8),
        child: _FlagSlot(server, size: 40),
      ),
      title: Semantics(
        label: t.pages.proxies.activeProxy,
        child: group == null
            ? Text(server.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: nameStyle)
            : Row(
                children: [
                  Icon(
                    switch (group) {
                      lowestGroupTag => Icons.bolt_rounded,
                      balanceGroupTag => Icons.call_split_rounded,
                      _ => Icons.layers_outlined,
                    },
                    size: 13,
                    color: s.primary,
                  ),
                  const Gap(2),
                  Text(group, style: theme.textTheme.labelMedium?.copyWith(color: s.primary, letterSpacing: .3)),
                  Text('  ·  ', style: theme.textTheme.labelMedium?.copyWith(color: s.outline)),
                  Flexible(
                    child: group == balanceGroupTag
                        ? const _StrategyChip()
                        : Text(server.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: nameStyle),
                  ),
                ],
              ),
      ),
      subtitle: Row(
        children: [
          // The config's IP is the final one only with unblocker; with no chain it is the only one.
          _IpSlot(server, boneWidth: 64, isFinal: card.chain.isUnblocker(), onLongPress: urlTest),
          Flexible(
            child: Text(
              server.ipLookupFailed ? server.type : '  ·  ${server.type}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

/// Balance's strategy as a small button; its menu switches the strategy.
class _StrategyChip extends ConsumerWidget {
  const _StrategyChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final current = ref.watch(ConfigOptions.balancerStrategy);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: AdaptiveMenu(
        items: [
          for (final strategy in BalancerStrategy.values)
            AdaptiveMenuItem(
              title: strategy.present(t),
              leadingIcon: Icon(strategy == current ? Icons.check_rounded : null, size: 18),
              onTap: () => ref.read(ConfigOptions.balancerStrategy.notifier).update(strategy),
            ),
        ],
        builder: (context, toggleVisibility, _) => Material(
          color: s.primary.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: toggleVisibility,
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              // short, so the row is no taller than with a plain name
              height: 20,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 2, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        current.present(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 13, height: 1.2),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down_rounded, size: 16, color: s.onSurface),
                  ],
                ),
              ),
            ),
          ),
        ),
        child: null,
      ),
    );
  }
}

// ---------- IPs: a skeleton while loading, a pop when they arrive ----------

/// A grey placeholder, breathing, with a tinted light sweeping across it.
class _Bone extends StatelessWidget {
  const _Bone({required this.width, required this.height, required this.radius});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: s.onSurface.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(radius),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1300.ms, color: s.primary.withValues(alpha: .45), angle: .6)
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: .55, end: 1, duration: 900.ms, curve: Curves.easeInOut);
  }
}

/// The flag of [info]'s IP: a placeholder while it loads, a question mark if the lookup failed.
/// On arrival it pops in and sends out one ring.
class _FlagSlot extends StatelessWidget {
  const _FlagSlot(this.info, {required this.size, this.radius = 8});
  final OutboundInfo? info;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final info = this.info;
    final inner = size - 8; // IPCountryFlag draws the flag 8 px smaller than its box
    return SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (info) {
          OutboundInfo(hasIp: true) => Stack(
            key: const ValueKey('flag'),
            alignment: Alignment.center,
            children: [
              Container(
                    width: inner,
                    height: inner,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: s.primary, width: 2),
                    ),
                  )
                  .animate()
                  .scaleXY(begin: 1, end: 1.7, duration: 600.ms, curve: Curves.easeOut)
                  .fadeOut(duration: 600.ms),
              IPCountryFlag(
                    countryCode: info.ipinfo.countryCode,
                    organization: info.ipinfo.org,
                    size: size,
                    radius: radius,
                  )
                  .animate()
                  .scaleXY(begin: .4, end: 1, duration: 500.ms, curve: Curves.easeOutBack)
                  .fadeIn(duration: 200.ms),
            ],
          ),
          OutboundInfo(ipLookupFailed: true) => IPCountryFlag(
            key: const ValueKey('unknown'),
            countryCode: '',
            size: size,
          ),
          _ => Center(
            child: _Bone(width: inner, height: inner, radius: inner / 4),
          ),
        },
      ),
    );
  }
}

/// [info]'s IP: a placeholder while it loads, nothing if the lookup failed. On arrival it slides
/// up; the final IP is green and first shows "Final IP" in its place.
class _IpSlot extends StatelessWidget {
  const _IpSlot(this.info, {required this.boneWidth, required this.isFinal, this.onLongPress});
  final OutboundInfo? info;
  final double boneWidth;
  final bool isFinal;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final info = this.info;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      layoutBuilder: (current, previous) =>
          Stack(alignment: AlignmentDirectional.centerStart, children: [...previous, ?current]),
      child: switch (info) {
        OutboundInfo(hasIp: true) =>
          KeyedSubtree(
                key: const ValueKey('ip'),
                child: isFinal
                    ? _FinalIpSwap(ip: info.ipinfo.ip, onLongPress: onLongPress)
                    : IPText(ip: info.ipinfo.ip, onLongPress: onLongPress ?? () {}, constrained: true),
              )
              .animate(delay: 120.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: .6, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
        OutboundInfo(ipLookupFailed: true) => const SizedBox.shrink(key: ValueKey('unknown')),
        _ => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _Bone(width: boneWidth, height: 9, radius: 4.5),
        ),
      },
    );
  }
}

/// The final IP, in green. Like the QR dialog's "Copied": "Final IP" shows first in its place for
/// [_hold], then the IP slides in, once. Keeps the wider size, so nothing beside it moves.
class _FinalIpSwap extends ConsumerStatefulWidget {
  const _FinalIpSwap({required this.ip, this.onLongPress});
  final String ip;
  final VoidCallback? onLongPress;

  static const _hold = Duration(milliseconds: 2600);

  @override
  ConsumerState<_FinalIpSwap> createState() => _FinalIpSwapState();
}

class _FinalIpSwapState extends ConsumerState<_FinalIpSwap> {
  var _words = true;
  late final Timer _toIp;

  @override
  void initState() {
    super.initState();
    _toIp = Timer(_FinalIpSwap._hold, () => setState(() => _words = false));
  }

  @override
  void dispose() {
    _toIp.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    // the QR dialog's green: M3 has no success role
    final green = theme.brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade800;
    const duration = Duration(milliseconds: 300);
    Widget slot(Widget child, {required bool visible, required Offset hiddenOffset}) => IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : hiddenOffset,
          duration: duration,
          child: AnimatedOpacity(opacity: visible ? 1 : 0, duration: duration, child: child),
        ),
      ),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        slot(
          Theme(
            // IPText draws in labelMedium
            data: theme.copyWith(
              textTheme: theme.textTheme.copyWith(labelMedium: theme.textTheme.labelMedium?.copyWith(color: green)),
            ),
            child: IPText(ip: widget.ip, onLongPress: widget.onLongPress ?? () {}, constrained: true),
          ),
          visible: !_words,
          hiddenOffset: const Offset(0, -0.4),
        ),
        slot(
          Text(
            t.pages.settings.chain.finalIp,
            maxLines: 1,
            style: theme.textTheme.labelMedium?.copyWith(color: green, fontSize: 11),
          ),
          visible: _words,
          hiddenOffset: const Offset(0, 0.4),
        ),
      ],
    );
  }
}

// class _StatsColumn extends HookConsumerWidget {
//   const _StatsColumn();

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final t = ref.watch(translationsProvider).requireValue;
//     final stats = ref.watch(statsNotifierProvider).value;

//     return Directionality(
//       textDirection: TextDirection.values[(Directionality.of(context).index + 1) % TextDirection.values.length],
//       child: Flexible(
//         child: Column(
//           children: [
//             _InfoProp(
//               icon: FluentIcons.arrow_bidirectional_up_down_20_regular,
//               text: (stats?.downlinkTotal ?? 0).size(),
//               semanticLabel: t.stats.totalTransferred,
//             ),
//             const Gap(8),
//             _InfoProp(
//               icon: FluentIcons.arrow_download_20_regular,
//               text: (stats?.downlink ?? 0).speed(),
//               semanticLabel: t.stats.speed,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _InfoProp extends StatelessWidget {
//   const _InfoProp({
//     required this.icon,
//     required this.text,
//     this.semanticLabel,
//   });

//   final IconData icon;
//   final String text;
//   final String? semanticLabel;

//   @override
//   Widget build(BuildContext context) {
//     return Semantics(
//       label: semanticLabel,
//       child: Row(
//         children: [
//           Icon(icon),
//           const Gap(8),
//           Flexible(
//             child: Text(
//               text,
//               style: Theme.of(context).textTheme.labelMedium?.copyWith(fontFamily: FontFamily.emoji),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
