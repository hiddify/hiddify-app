import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/widget/unique_keys_layout.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/proxy_type_label.dart';
import 'package:hiddify/features/proxy/widget/upload_speed.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(
    this.proxy, {
    super.key,
    required this.selected,
    required this.onTap,
    this.testable = true,
    this.showPing = true,
    this.testing = false,
  });

  final OutboundInfo proxy;
  final bool selected;
  final GestureTapCallback? onTap;

  /// Whether a tap on the ping or the speeds tests the proxy; else a tap anywhere is the row's.
  final bool testable;

  /// Whether the ping shows: not for a proxy the core does not run, which no ping will reach.
  final bool showPing;

  /// A ping asked for is on its way: the ping's place says so, also of a proxy at rest, whose
  /// row otherwise does not move.
  final bool testing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final style = ref.watch(proxyPingStyleNotifierProvider);
    final state = proxy.rowState;
    // pops play when a value arrives in this row, not when the row is first built or scrolled in
    final previousState = usePrevious(state);
    final arrived = previousState != null && previousState != state;
    final previousHasIp = usePrevious(proxy.hasIp);
    final colors = _RowColors.of(context);
    // the proxy gave up, or rests: the row fades; of one that gave up the red word stays bright
    final faded = state == ProxyRowState.failed || state == ProxyRowState.resting;
    // tested for its upload or download speed, or being tested: the speeds show under the ping
    // a proxy whose ping and both speeds failed shows the ping's cross alone
    final allFailed =
        state == ProxyRowState.pingFailed &&
        proxy.uploadSpeed < 0 &&
        proxy.downloadSpeed < 0 &&
        !proxy.uploadTesting &&
        !proxy.downloadTesting;
    final uploaded =
        !allFailed &&
        (proxy.uploadTesting || proxy.uploadSpeed != 0 || proxy.downloadTesting || proxy.downloadSpeed != 0);
    // the user asked to keep this proxy loaded whatever its ping: the flag wears a pin
    final pinned = ref.watch(
      activeProfileProvider.select((profile) {
        final p = profile.valueOrNull;
        return p != null && p.keepsTop && p.keepTopPinned.contains(proxy.tag);
      }),
    );
    final word = switch (state) {
      ProxyRowState.connecting => t.pages.proxies.status.connecting,
      ProxyRowState.registering => t.pages.proxies.status.registering,
      _ => null,
    };

    return ListTile(
      title: Text(
        proxy.nameWithDetour,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: PlatformUtils.isWindows ? FontFamily.emoji : null,
          color: faded ? theme.colorScheme.onSurface.withValues(alpha: _fadedAlpha) : null,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(
              opacity: faded ? _fadedAlpha : 1,
              child: _FlagSlot(
                proxy,
                reconnectingBadge: state == ProxyRowState.reconnecting && style == ProxyPingStyle.number,
                popIn: previousHasIp == false,
              ),
            ),
            // the top corner, bright on a faded row; the reconnecting sync takes the bottom one
            if (pinned)
              PositionedDirectional(
                start: -3,
                top: -3,
                child: Tooltip(message: t.dialogs.proxyInfo.keepLoaded, child: const _PinBadge()),
              ),
          ],
        ),
      ),
      // the state word stays whole; a long type gives way first
      subtitle: Row(
        children: [
          Flexible(
            child: ProxyTypeLabel(
              proxy.typeWithoutStatus,
              suffix: [
                if (proxy.isGroup)
                  TextSpan(text: ' (${proxy.groupSelectedTagDisplay.trim()})', style: theme.textTheme.bodySmall),
              ],
              style: faded ? TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: _fadedAlpha)) : null,
            ),
          ),
          if (word != null) Text('  ·  $word', maxLines: 1, style: TextStyle(color: colors.accent)),
        ],
      ),
      trailing: SizedBox(
        width: 88,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Semantics(
              button: true,
              label: t.pages.proxies.testDelay,
              // the tap area hugs the ping; the rest of the row keeps its own tap and long press
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                // a tap tests this proxy's ping, a long press its upload speed
                onTap: testable ? () => ref.read(proxiesOverviewNotifierProvider.notifier).urlTest(proxy.tag) : null,
                onLongPress: testable
                    ? () => ref.read(proxiesOverviewNotifierProvider.notifier).uploadTest(proxy.tag)
                    : null,
                child: Padding(
                  padding: uploaded ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : const EdgeInsets.all(6),
                  child: AnimatedSwitcher(
                    layoutBuilder: uniqueKeysLayout(),
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey((state, style, testing)),
                      child: !showPing
                          ? const SizedBox.shrink()
                          : testing
                          ? _Signal(_Logo.loading(colors.accent))
                          : _ping(context, state, style, colors, t, arrived: arrived),
                    ),
                  ),
                ),
              ),
            ),
            if (uploaded)
              // a tap tests the upload again, a long press the download
              // of a proxy at rest, as dim as its ping
              Opacity(
                opacity: state == ProxyRowState.resting ? .55 : 1,
                child: IgnorePointer(
                  ignoring: !testable,
                  child: UploadSpeedChip(
                    speed: proxy.uploadSpeed.toInt(),
                    testing: proxy.uploadTesting,
                    cached: proxy.uploadSpeedCached,
                    onTest: () => ref.read(proxiesOverviewNotifierProvider.notifier).uploadTest(proxy.tag),
                    downloadSpeed: proxy.downloadSpeed.toInt(),
                    downloadTesting: proxy.downloadTesting,
                    downloadCached: proxy.downloadSpeedCached,
                    onDownloadTest: () => ref.read(proxiesOverviewNotifierProvider.notifier).downloadTest(proxy.tag),
                    dense: true,
                  ),
                ),
              ),
          ],
        ),
      ),
      selected: selected,
      selectedTileColor: theme.colorScheme.primaryContainer,
      onTap: onTap,
      onLongPress: () async => await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: proxy),
      horizontalTitleGap: 4,
    );
  }

  Widget _ping(
    BuildContext context,
    ProxyRowState state,
    ProxyPingStyle style,
    _RowColors colors,
    Translations t, {
    required bool arrived,
  }) {
    final delay = proxy.urlTestDelay;
    // value 1 starts a pop at its end: it only plays for a value that just arrived
    final number = style == ProxyPingStyle.number;
    return switch (state) {
      ProxyRowState.ready =>
        (number
                ? _PingNumber(delay, color: delayColor(context, delay))
                : _Signal(_Logo.lit(delayColor(context, delay), bars: delay < 300 ? 3 : (delay < 800 ? 2 : 1))))
            .animate(value: arrived ? 0 : 1)
            .scaleXY(begin: .5, end: 1, duration: 450.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 200.ms),
      ProxyRowState.pingFailed =>
        (number
                ? Icon(Icons.close_rounded, size: 18, color: colors.red)
                : _Signal(_Logo.lit(colors.red, bars: 0), badge: _Badge(colors.red, Icons.close_rounded)))
            .animate(value: arrived ? 0 : 1)
            .scaleXY(begin: .5, end: 1, duration: 350.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 200.ms),
      ProxyRowState.untested => _Signal(_Logo.loading(colors.wait)),
      // asleep: nothing is coming, so nothing moves. Its last ping stays, dim, beside the moon
      // icon: of this run, else of the one before; a tap on it wakes and tests it
      ProxyRowState.resting => Tooltip(
        message: t.pages.proxies.status.resting,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ConnectionConst.isValidDelay(_lastDelay))
              Opacity(opacity: .55, child: _PingNumber(_lastDelay, color: delayColor(context, _lastDelay)))
            else if (delay >= ConnectionConst.maxDelay)
              Opacity(opacity: .55, child: Icon(Icons.close_rounded, size: 16, color: colors.red)),
            const Gap(6),
            Icon(Icons.bedtime_outlined, size: 16, color: colors.wait),
          ],
        ),
      ),
      ProxyRowState.connecting || ProxyRowState.registering => _Signal(_Logo.loading(colors.accent)),
      ProxyRowState.searching => _Searching(colors.accent),
      // number style: the last ping stays, faded, while the flag wears the badge
      ProxyRowState.reconnecting when number =>
        delay > 0 && delay < 65535
            ? Opacity(opacity: .4, child: _PingNumber(delay, color: delayColor(context, delay)))
            : const SizedBox.shrink(),
      ProxyRowState.reconnecting => _Signal(_Logo.loading(colors.amber), badge: _Badge(colors.amber, null)),
      ProxyRowState.failed =>
        Text(
              t.pages.proxies.status.failed,
              style: TextStyle(fontSize: 12, color: colors.red, fontWeight: FontWeight.w600),
            )
            .animate(value: arrived ? 0 : 1)
            .scaleXY(begin: .5, end: 1, duration: 400.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 200.ms),
    };
  }

  /// The last ping known of the proxy: of this run, else the one the core kept from the run
  /// before, which it sends only to sort by.
  int get _lastDelay => ConnectionConst.isValidDelay(proxy.urlTestDelay) ? proxy.urlTestDelay : proxy.sortDelay;

  Color delayColor(BuildContext context, int delay) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return switch (delay) {
        < 800 => Colors.lightGreen,
        < 1500 => Colors.orange,
        _ => Colors.redAccent,
      };
    }
    return switch (delay) {
      < 800 => Colors.green,
      < 1500 => Colors.deepOrangeAccent,
      _ => Colors.red,
    };
  }
}

const _fadedAlpha = .4;

class _RowColors {
  const _RowColors({required this.wait, required this.accent, required this.amber, required this.red});
  final Color wait;
  final Color accent;
  final Color amber;
  final Color red;

  factory _RowColors.of(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _RowColors(
      wait: s.onSurfaceVariant,
      accent: s.primary,
      amber: dark ? const Color(0xFFFFB74D) : Colors.orange.shade800,
      red: dark ? const Color(0xFFFF6E6E) : Colors.red.shade700,
    );
  }
}

/// Runs [builder] with 0..1 through a loop of [period], again and again.
class _Looping extends HookWidget {
  const _Looping({required this.period, required this.builder});
  final Duration period;
  final Widget Function(double t) builder;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: period);
    useEffect(() {
      controller.repeat();
      return null;
    }, [controller]);
    return AnimatedBuilder(animation: controller, builder: (_, _) => builder(controller.value));
  }
}

double _ease(double v) => -(cos(pi * v.clamp(0.0, 1.0)) - 1) / 2;

Widget _spinning(Widget child) => _Looping(
  period: const Duration(seconds: 1),
  builder: (t) => Transform.rotate(angle: -t * 2 * pi, child: child),
);

/// The ping as a number, without "ms".
class _PingNumber extends StatelessWidget {
  const _PingNumber(this.delay, {required this.color});
  final int delay;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    '$delay',
    textDirection: TextDirection.ltr,
    style: TextStyle(fontSize: 13, height: 1.1, color: color, fontWeight: FontWeight.w600),
  );
}

/// The signal: the logo at the row end in every state, a badge on its top start corner.
class _Signal extends StatelessWidget {
  const _Signal(this.logo, {this.badge});
  final Widget logo;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => Directionality(
    // a signal rises to the right, also in Persian
    textDirection: TextDirection.ltr,
    // only the logo takes room, so the tap area hugs it; the badge sits over its top start corner
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        logo,
        if (badge case final badge?) Positioned(left: -9, top: -5, child: badge),
      ],
    ),
  );
}

/// A small round badge; with no [icon] it shows the spinning sync of a reconnecting proxy.
class _Badge extends StatelessWidget {
  const _Badge(this.color, this.icon);
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final glyph = Icon(icon ?? Icons.sync_rounded, size: 8, color: bg);
    return Container(
      width: 12,
      height: 12,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: bg, width: 1.5),
      ),
      child: icon == null ? _spinning(glyph) : glyph,
    );
  }
}

/// The pin of a proxy the user keeps loaded whatever its ping: a filled circle in the primary color,
/// ringed in the surface color so it stands off any flag.
class _PinBadge extends StatelessWidget {
  const _PinBadge();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: s.primary,
        shape: BoxShape.circle,
        border: Border.all(color: s.surface, width: 2),
      ),
      child: Icon(Icons.push_pin_rounded, size: 11, color: s.onPrimary),
    );
  }
}

/// The Hiddify logo as the signal: its three columns light like a phone's three bars.
class _Logo extends StatelessWidget {
  const _Logo(this.colors);
  final List<Color> colors;

  /// The first [bars] columns in [color], the rest faint.
  factory _Logo.lit(Color color, {required int bars}) =>
      _Logo([for (var b = 0; b < 3; b++) b < bars ? color : color.withValues(alpha: .25)]);

  /// Waiting: the columns light up in turn, then dim in turn. Their size never changes. A slow
  /// loop: a page of rows waiting for their first ping should read as calm, not busy.
  static Widget loading(Color color) => _Looping(
    period: const Duration(milliseconds: 2800),
    builder: (v) {
      double lit(int b) {
        final up = _ease((v - b * .16) / .22);
        final down = _ease((v - .62 - b * .1) / .14);
        return up * (1 - down);
      }

      return _Logo([for (var b = 0; b < 3; b++) color.withValues(alpha: .25 + .65 * lit(b))]);
    },
  );

  static const size = 13.0;

  // where the logo's columns split, as parts of its width (assets/images/logo.svg, 64 wide)
  static const _cuts = [0.0, 17.6 / 64, 45.6 / 64, 1.0];

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      children: [
        for (var b = 0; b < 3; b++)
          ClipRect(
            clipper: _ColumnClip(_cuts[b], _cuts[b + 1]),
            child: Assets.images.logo.svg(
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(colors[b], BlendMode.srcIn),
            ),
          ),
      ],
    ),
  );
}

class _ColumnClip extends CustomClipper<Rect> {
  const _ColumnClip(this.from, this.to);
  final double from;
  final double to;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(size.width * from, 0, size.width * to, size.height);

  @override
  bool shouldReclip(_ColumnClip old) => old.from != from || old.to != to;
}

/// Searching: a magnifier circling slowly.
class _Searching extends StatelessWidget {
  const _Searching(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => _Looping(
    period: const Duration(milliseconds: 1400),
    builder: (t) => Transform.translate(
      offset: Offset(cos(t * 2 * pi), sin(t * 2 * pi)) * 2.5,
      child: Icon(Icons.search_rounded, size: 17, color: color),
    ),
  );
}

/// The flag of [proxy]'s IP. This run's IP: the flag, popping in on arrival. Only the last run's
/// IP: that flag, faded and shimmering. No IP while waiting: a shimmering placeholder; after a failure:
/// the plain empty square. With [reconnectingBadge] the flag fades and wears the spinning sync.
class _FlagSlot extends StatelessWidget {
  const _FlagSlot(this.proxy, {required this.reconnectingBadge, required this.popIn});
  final OutboundInfo proxy;
  final bool reconnectingBadge;

  /// This run's IP just arrived: the flag pops in with a ring.
  final bool popIn;

  static const size = 40.0;
  static const inner = size - 8; // IPCountryFlag draws the flag 8 px smaller than its box

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final ip = proxy.ipinfo;
    final flag = IPCountryFlag(countryCode: ip.countryCode, organization: ip.org, size: size);
    final state = proxy.rowState;
    final gaveUp = state == ProxyRowState.pingFailed || state == ProxyRowState.failed;
    final still = MediaQuery.disableAnimationsOf(context);

    final (Object key, Widget child) = switch (proxy) {
      _ when reconnectingBadge && ip.countryCode.isNotEmpty => (
        'reconnecting',
        Stack(
          clipBehavior: Clip.none,
          children: [
            Opacity(opacity: .45, child: flag),
            PositionedDirectional(
              end: -2,
              bottom: -2,
              child: Transform.scale(scale: 1.3, child: _Badge(_RowColors.of(context).amber, null)),
            ),
          ],
        ),
      ),
      OutboundInfo(hasIp: true) => (
        'flag',
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
                  width: inner,
                  height: inner,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.lightGreen, width: 2),
                  ),
                )
                .animate(value: popIn ? 0 : 1)
                .scaleXY(begin: 1, end: 1.7, duration: 700.ms, curve: Curves.easeOut)
                .fadeOut(duration: 700.ms),
            flag
                .animate(value: popIn ? 0 : 1)
                .scaleXY(begin: .4, end: 1, duration: 500.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 200.ms),
          ],
        ),
      ),
      _ when ip.ip.isNotEmpty && still => ('cached', Opacity(opacity: .35, child: flag)),
      _ when ip.ip.isNotEmpty => (
        'cached',
        Opacity(opacity: .35, child: flag)
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1300.ms, color: s.primary.withValues(alpha: .5), angle: .6),
      ),
      _ when gaveUp => ('empty', _square(s.onSurface.withValues(alpha: .07))),
      _ when still => ('bone', _square(s.onSurface.withValues(alpha: .12))),
      _ => (
        'bone',
        _square(s.onSurface.withValues(alpha: .12))
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1300.ms, color: s.primary.withValues(alpha: .45), angle: .6)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: .55, end: 1, duration: 900.ms, curve: Curves.easeInOut),
      ),
    };
    return SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        layoutBuilder: uniqueKeysLayout(),
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(key: ValueKey(key), child: child),
      ),
    );
  }

  static Widget _square(Color color) => Center(
    child: Container(
      width: inner,
      height: inner,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    ),
  );
}
