import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/adaptive_menu.dart';
import 'package:hiddify/core/widget/unique_keys_layout.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/features/chain/overview/chain_mode_icon.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/proxy/widget/proxy_type_label.dart';
import 'package:hiddify/features/proxy/widget/upload_speed.dart';
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
    return Card(margin: const EdgeInsets.all(16), clipBehavior: Clip.antiAlias, child: _Steps(card));
  }
}

// ---------- the steps: one row each, in the order they connect, joined by a rail ----------

/// One row's height, and the column its flag sits in; the flags are the rail's nodes.
const _rowHeight = 76.0;
const _railWidth = 56.0;
const _flagSize = 36.0;

/// The hop row: one line, so shorter, with a smaller and squarer flag.
const _hopRowHeight = 44.0;
const _hopFlagSize = 30.0;
const _hopFlagRadius = 4.0;

Color _green(BuildContext context) => Theme.of(context).extension<ConnectionButtonTheme>()!.connectedColor!;

class _Steps extends StatelessWidget {
  const _Steps(this.card);
  final ActiveProxyCardData card;

  @override
  Widget build(BuildContext context) {
    final hopStatus = card.hopStatus;
    if (hopStatus == null) return _ProxyRow(card);
    // unblocker carries the server's traffic, extra security dials through the server
    final unblocker = card.chain.isUnblocker();
    // the rail stops this far from each flag, which draws 8 px smaller than its box
    const gap = 5.0;
    final (h1, f1, h2, f2) = unblocker
        ? (_hopRowHeight, _hopFlagSize, _rowHeight, _flagSize)
        : (_rowHeight, _flagSize, _hopRowHeight, _hopFlagSize);
    final top = h1 / 2 + (f1 - 8) / 2 + gap;
    final bottom = h1 + h2 / 2 - (f2 - 8) / 2 - gap;
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: unblocker ? [_HopRow(card), _ProxyRow(card)] : [_ProxyRow(card), _HopRow(card)],
        ),
        PositionedDirectional(
          start: _railWidth / 2 - 1.5,
          width: 3,
          top: top,
          height: bottom - top,
          child: _Rail(unblocker ? card.serverStatus : hopStatus),
        ),
      ],
    );
  }
}

/// A step's row: its flag with the state badge, two lines of text, and a chevron; or, with
/// [trailing], [title] alone on one line and the trailing widget in place of the chevron.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.color,
    required this.onTap,
    required this.flag,
    required this.status,
    required this.title,
    this.subtitle = const SizedBox.shrink(),
    this.height = _rowHeight,
    this.trailing,
    this.end,
    this.onLongPress,
  });

  final double height;
  final Widget? trailing;

  /// Before the chevron of a row without [trailing]: the upload speed of the proxy in use.
  final Widget? end;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget flag;
  final StepStatus status;
  final Widget title;
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              SizedBox(
                width: _railWidth,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      flag,
                      if (trailing == null)
                        PositionedDirectional(end: -3, top: -3, child: _StateBadge(status, ring: color))
                      else
                        PositionedDirectional(
                          end: -5,
                          top: -5,
                          child: Transform.scale(scale: .8, child: _StateBadge(status, ring: color)),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: trailing == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, const Gap(2), subtitle],
                      )
                    : Align(alignment: AlignmentDirectional.centerStart, child: title),
              ),
              if (trailing case final trailing?) ...[
                const Gap(8),
                trailing,
                // room for the trailing widget's badge, clear of the card's rounded corner
                const Gap(24),
              ] else ...[
                if (end case final end?) ...[const Gap(8), end, const Gap(4)],
                Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const Gap(12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A step's problem, in place of its second line.
class _Problem extends StatelessWidget {
  const _Problem(this.message, {this.error = true});
  final String message;

  /// False while it is only slow.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelMedium?.copyWith(
        color: error ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Shows [first] and [second] in turn, a few seconds each, with a crossfade; it starts on [first].
class _Alternating extends HookWidget {
  const _Alternating(this.first, this.second);
  final Widget first;
  final Widget second;

  static const _period = Duration(seconds: 3);

  @override
  Widget build(BuildContext context) {
    final showFirst = useState(true);
    useEffect(() {
      final timer = Timer.periodic(_period, (_) => showFirst.value = !showFirst.value);
      return timer.cancel;
    }, const []);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      layoutBuilder: (current, previous) =>
          Stack(alignment: AlignmentDirectional.centerStart, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(showFirst.value), child: showFirst.value ? first : second),
    );
  }
}

TextStyle? _nameStyle(BuildContext context, StepStatus status) => Theme.of(context).textTheme.titleMedium?.copyWith(
  fontSize: 14,
  // a step that waits for the one before it is dimmed
  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: status == StepStatus.waiting ? .45 : 1),
);

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
    final status = card.serverStatus;
    final connected = status == StepStatus.connected;
    final muted = theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant);
    final nameStyle = _nameStyle(context, status);
    final group = card.group;

    Future<void> urlTest() => ref.read(activeProxyNotifierProvider.notifier).urlTest("");

    return _StepRow(
      color: theme.cardTheme.color ?? s.surfaceContainerLow,
      onTap: () => context.goNamed('proxies'),
      // how fast the proxy in use uploads and downloads: a tap measures the upload, a long press the
      // download
      end: connected
          ? UploadSpeedChip(
              speed: server.uploadSpeed.toInt(),
              testing: server.uploadTesting,
              cached: server.uploadSpeedCached,
              onTest: () => ref.read(activeProxyNotifierProvider.notifier).uploadTest(),
              downloadSpeed: server.downloadSpeed.toInt(),
              downloadTesting: server.downloadTesting,
              downloadCached: server.downloadSpeedCached,
              onDownloadTest: () => ref.read(activeProxyNotifierProvider.notifier).downloadTest(),
            )
          : null,
      flag: InkWell(
        onTap: () async {
          await urlTest();
          await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: server);
        },
        borderRadius: BorderRadius.circular(8),
        child: _FlagSlot(
          connected ? server : null,
          size: _flagSize,
          dim: status == StepStatus.waiting || status == StepStatus.failed,
        ),
      ),
      status: status,
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
      subtitle: switch (status) {
        // lowest picks the best server, so lowest failing means none answers
        StepStatus.failed => _Problem(
          group == lowestGroupTag ? t.pages.proxies.noneResponding : t.pages.proxies.notResponding,
        ),
        StepStatus.waiting => ProxyTypeLabel(server.type, style: muted),
        _ => Row(
          children: [
            // The config's IP is the final one only with unblocker; with no chain it is the only one.
            _IpSlot(connected ? server : null, boneWidth: 64, isFinal: card.chain.isUnblocker(), onLongPress: urlTest),
            Flexible(
              child: ProxyTypeLabel(server.type, prefix: '  ·  ', style: muted),
            ),
          ],
        ),
      },
    );
  }
}

// ---------- the hop row: its IP, then the chain type in a chip with its mode as a badge. A tap
// shows the hop's proxy info, a long press its configuration. ----------

class _HopRow extends ConsumerWidget {
  const _HopRow(this.card);
  final ActiveProxyCardData card;

  static const _chipHeight = 28.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final status = card.hopStatus!;
    final type = card.chain.isUnblocker() ? ChainType.unblocker : ChainType.extraSecurity;
    final (main, _) = type.colors(card.hopMode);
    final color = Color.alphaBlend(main.withValues(alpha: .16), s.surfaceContainerHigh);
    final down = status == StepStatus.waiting || status == StepStatus.failed;
    final hop = card.hop;
    // the core still setting the hop up (or not listing it yet): its live state in place of the flag
    // and the IP; once the core says ready, the flag and the IP wait for the first ping as usual
    final live = status == StepStatus.slow || (status == StepStatus.connecting && hop?.status != Status.READY);
    return _StepRow(
      color: color,
      onTap: hop == null
          ? () => context.goNamed('chainOptions')
          : () => ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: hop),
      onLongPress: () => context.goNamed('chainOptions'),
      height: _hopRowHeight,
      // while the hop connects, its live state as a moving icon in the flag's place
      flag: switch (status) {
        _ when live => SizedBox.square(
          dimension: _hopFlagSize,
          child: Center(
            child: _HopStateIcon(slow: status == StepStatus.slow, core: hop?.status, color: main),
          ),
        ),
        _ => _FlagSlot(
          status == StepStatus.connected ? card.hop : null,
          size: _hopFlagSize,
          radius: _hopFlagRadius,
          dim: down,
        ),
      },
      status: status,
      title: switch (status) {
        StepStatus.waiting => const SizedBox.shrink(),
        // slow: the warning comes and goes, and in between the row says what the hop is doing
        StepStatus.slow => _Alternating(
          _Problem(t.connection.slow, error: false),
          ProxyTypeLabel(
            hop?.type ?? card.hopMode.present(t),
            style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant),
          ),
        ),
        StepStatus.failed => _Problem(t.connection.failed),
        // while it connects, what the hop runs and what it is doing, as the core names it ("Psiphon ⏳
        // Connecting...", "WARP · Auto 🔑 Registering..."), in place of the IP's placeholder
        StepStatus.connecting when live => ProxyTypeLabel(
          hop?.type ?? card.hopMode.present(t),
          style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant),
        ),
        _ => _IpSlot(status == StepStatus.connected ? hop : null, boneWidth: 64, isFinal: card.chain.isExtraSecurity()),
      },
      trailing: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: _chipHeight,
            padding: const EdgeInsetsDirectional.only(start: 6, end: 10),
            decoration: BoxDecoration(
              color: main.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(_chipHeight / 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: _chipHeight - 10,
                  child: FittedBox(
                    child: ChainTypeIcon(type: type, mode: card.hopMode, animate: !down),
                  ),
                ),
                const Gap(4),
                Text(type.present(t), style: theme.textTheme.labelMedium?.copyWith(color: main, letterSpacing: .3)),
              ],
            ),
          ),
          // the mode, as a badge on the chip's top end
          PositionedDirectional(
            top: -5,
            end: -5,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: s.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(child: ChainModeIcon(mode: card.hopMode, size: 10)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A connecting hop's live state on a small tile: an hourglass that flips while it connects, a clock
/// when it is slow, a pulsing fingerprint while WARP registers, a circling magnifier while it
/// searches, spinning arrows while it reconnects.
class _HopStateIcon extends HookWidget {
  const _HopStateIcon({required this.slow, required this.core, required this.color});
  final bool slow;
  final Status? core;
  final Color color;

  static const _tile = 22.0;

  /// One loop holds every motion: the clock's hour hand takes the longest, 36 s.
  static const _loop = 36.0;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final clock = useAnimationController(duration: const Duration(seconds: 36));
    useEffect(() {
      clock.repeat();
      return null;
    }, const []);
    final amber = Colors.amber.shade300;
    return RepaintBoundary(
      child: Container(
        width: _tile,
        height: _tile,
        decoration: BoxDecoration(color: s.onSurface.withValues(alpha: .08), borderRadius: BorderRadius.circular(4)),
        child: Center(
          child: AnimatedBuilder(
            animation: clock,
            builder: (context, _) {
              final t = clock.value * _loop;
              Icon icon(IconData data) => Icon(data, size: 15, color: color);
              return switch (core) {
                _ when slow => CustomPaint(size: const Size.square(15), painter: _ClockPainter(t, amber)),
                Status.REGISTERING => Opacity(
                  opacity: .55 + .45 * ((math.sin(t * 2 * math.pi / 1.6) + 1) / 2),
                  child: Icon(Icons.fingerprint_rounded, size: 16, color: color),
                ),
                Status.SEARCHING => Transform.translate(
                  offset: Offset(math.cos(t * 2 * math.pi / 1.6), math.sin(t * 2 * math.pi / 1.6)) * 3,
                  child: icon(Icons.search_rounded),
                ),
                Status.RECONNECTING => Transform.rotate(angle: -t * 2 * math.pi / 1.2, child: icon(Icons.sync_rounded)),
                // a half turn every 1.6 s: it turns in the first half, then rests
                _ => Transform.rotate(
                  angle:
                      math.pi * (t ~/ 1.6) +
                      math.pi * Curves.easeInOutCubic.transform(((t % 1.6) / 1.6 * 2).clamp(0.0, 1.0)),
                  child: icon(Icons.hourglass_top_rounded),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

/// A clock face with two hands: the minute hand goes round every 3 s, the hour hand twelve times
/// slower. Both stay clear of the rim.
class _ClockPainter extends CustomPainter {
  _ClockPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, pen..strokeWidth = 1.6);
    Offset tip(double turns, double length) =>
        c + Offset(math.sin(turns * 2 * math.pi), -math.cos(turns * 2 * math.pi)) * length;
    canvas.drawLine(c, tip(t / 3, r * .55), pen..strokeWidth = 1.4);
    canvas.drawLine(c, tip(.25 + t / 36, r * .38), pen..strokeWidth = 1.8);
  }

  @override
  bool shouldRepaint(_ClockPainter old) => old.t != t || old.color != color;
}

// ---------- a step's state: a badge on its flag, and the rail to the next step ----------

/// Waiting: an empty circle; connecting: a spinner; connected: a check; failed: an error icon.
/// Ringed in the row's color, so it cuts cleanly into the flag.
class _StateBadge extends StatelessWidget {
  const _StateBadge(this.status, {required this.ring});
  final StepStatus status;
  final Color ring;

  static const size = 15.0;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: size,
        child: AnimatedSwitcher(
          layoutBuilder: uniqueKeysLayout(),
          duration: const Duration(milliseconds: 250),
          child: switch (status) {
            StepStatus.waiting => Container(
              key: const ValueKey('waiting'),
              margin: const EdgeInsets.all(size * 2 / 24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: s.onSurface.withValues(alpha: .35), width: 1.5),
              ),
            ),
            StepStatus.connecting || StepStatus.slow => Padding(
              key: const ValueKey('connecting'),
              padding: const EdgeInsets.all(size * 2 / 24),
              child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: s.onSurface.withValues(alpha: .2)),
            ),
            StepStatus.connected => Icon(
              Icons.check_circle_rounded,
              key: const ValueKey('connected'),
              size: size,
              color: _green(context),
            ).animate().scaleXY(begin: .4, end: 1, duration: 400.ms, curve: Curves.easeOutBack),
            StepStatus.failed => Icon(Icons.error_rounded, key: const ValueKey('failed'), size: size, color: s.error),
          },
        ),
      ),
    );
  }
}

/// The line between the two flags, showing the second step: grey while it waits, dashes marching
/// down while it connects, filling green from the top once it connects, red-tinted if it failed.
class _Rail extends HookWidget {
  const _Rail(this.next);
  final StepStatus next;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final moving = next == StepStatus.connecting || next == StepStatus.slow;
    final connected = next == StepStatus.connected;
    // one dash and its gap per loop
    final march = useAnimationController(duration: const Duration(milliseconds: 360));
    // a card that shows up already connected starts full
    final fill = useAnimationController(duration: const Duration(milliseconds: 400), initialValue: connected ? 1 : 0);
    useEffect(() {
      if (moving) {
        march.repeat();
      } else {
        march.stop();
      }
      return null;
    }, [moving]);
    useEffect(() {
      if (connected) {
        fill.forward();
      } else {
        fill.value = 0;
      }
      return null;
    }, [connected]);
    return CustomPaint(
      painter: _RailPainter(
        next: next,
        march: march,
        fill: fill,
        track: s.onSurface.withValues(alpha: .15),
        dash: s.primary,
        green: _green(context),
        error: s.error.withValues(alpha: .5),
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.next,
    required this.march,
    required this.fill,
    required this.track,
    required this.dash,
    required this.green,
    required this.error,
  }) : super(repaint: Listenable.merge([march, fill]));

  final StepStatus next;
  final Animation<double> march;
  final Animation<double> fill;
  final Color track;
  final Color dash;
  final Color green;
  final Color error;

  static const _dash = 5.0;
  static const _space = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.width / 2);
    final rail = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas
      ..save()
      ..clipRRect(rail)
      ..drawRRect(rail, Paint()..color = next == StepStatus.failed ? error : track);
    switch (next) {
      case StepStatus.connecting || StepStatus.slow:
        final paint = Paint()..color = dash;
        for (var y = march.value * (_dash + _space) - _dash - _space; y < size.height; y += _dash + _space) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, y, size.width, _dash), radius), paint);
        }
      case StepStatus.connected:
        final height = size.height * Curves.easeOutCubic.transform(fill.value);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, height), Paint()..color = green);
      case StepStatus.waiting || StepStatus.failed:
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.next != next || old.track != track || old.dash != dash || old.green != green || old.error != error;
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
    final bone = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: s.onSurface.withValues(alpha: .12), borderRadius: BorderRadius.circular(radius)),
    );
    if (MediaQuery.disableAnimationsOf(context)) return bone;
    return RepaintBoundary(
      // both loops repaint the bone alone, not the card round it
      child: bone
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1300.ms, color: s.primary.withValues(alpha: .45), angle: .6)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: .55, end: 1, duration: 900.ms, curve: Curves.easeInOut),
    );
  }
}

/// The flag of [info]'s IP: a placeholder until this run's IP arrives (a failed lookup is retried
/// with the next ping), a faint square while [dim] (its step waits or failed). On arrival it pops in
/// and sends out a ring.
class _FlagSlot extends StatelessWidget {
  const _FlagSlot(this.info, {required this.size, this.dim = false, this.radius = 8});
  final OutboundInfo? info;
  final double size;
  final bool dim;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final info = this.info;
    final inner = size - 8; // IPCountryFlag draws the flag 8 px smaller than its box
    return SizedBox.square(
      dimension: size,
      child: RepaintBoundary(
        // the pop and the ring repaint the slot alone
        child: AnimatedSwitcher(
          layoutBuilder: uniqueKeysLayout(),
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
                        border: Border.all(color: _green(context), width: 2),
                      ),
                    )
                    .animate()
                    .scaleXY(begin: 1, end: 1.7, duration: 700.ms, curve: Curves.easeOut)
                    .fadeOut(duration: 700.ms),
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
            _ when dim => Center(
              key: const ValueKey('dim'),
              child: Container(
                width: inner,
                height: inner,
                decoration: BoxDecoration(
                  color: s.onSurface.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
            _ => Center(
              key: const ValueKey('bone'),
              child: _Bone(width: inner, height: inner, radius: inner / 4),
            ),
          },
        ),
      ),
    );
  }
}

/// [info]'s IP: a placeholder until this run's IP arrives. On arrival it slides up; the final IP is
/// green and first shows "Final IP" in its place.
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
      layoutBuilder: uniqueKeysLayout(AlignmentDirectional.centerStart),
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
