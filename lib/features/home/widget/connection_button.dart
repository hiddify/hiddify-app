import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/core/widget/frame_load.dart';
import 'package:hiddify/core/widget/unique_keys_layout.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/features/chain/overview/chain_mode_icon.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/eclipse_button_painter.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/model/connection_health.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// What the button shows, one value per look.
enum _Look { loading, disconnected, connecting, waiting, noProxies, connected, hotReloading, disconnecting, failed }

/// One look per status the core reports. The core decides when the tunnel is waiting for a ping
/// and when it is connected; the button only shows it.
///
/// The status reloads after every core start; until the new stream answers,
/// the last status holds. A failed start comes back as disconnected with the
/// failure attached.
///
/// A hot reload keeps the tunnel up and has a look of its own.
_Look _lookOf(AsyncValue<ConnectionStatus> status) => switch (status) {
  AsyncError() => _Look.failed,
  AsyncValue(valueOrNull: Disconnected(connectionFailure: _?)) => _Look.failed,
  AsyncValue(valueOrNull: Disconnected()) => _Look.disconnected,
  AsyncValue(valueOrNull: Connecting()) => _Look.connecting,
  AsyncValue(valueOrNull: Waiting()) => _Look.waiting,
  AsyncValue(valueOrNull: NoAvailableProxies()) => _Look.noProxies,
  AsyncValue(valueOrNull: HotReloading()) => _Look.hotReloading,
  AsyncValue(valueOrNull: Connected()) => _Look.connected,
  AsyncValue(valueOrNull: Disconnecting()) => _Look.disconnecting,
  _ => _Look.loading,
};

class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final status = ref.watch(connectionNotifierProvider);
    final look = _held(_lookOf(status));

    // What a tap does follows the core alone, and the core can be stopped whatever it is doing: a
    // tunnel that is up, a start in progress, and a hot reload all turn off at once, and the core
    // cancels what it was busy with.
    final onTap = switch (status) {
      AsyncData(value: Disconnected()) || AsyncError() => () => _connect(ref),
      AsyncData(value: Connected() || Waiting() || NoAvailableProxies() || Connecting() || HotReloading()) =>
        () => ref.read(connectionNotifierProvider.notifier).toggleConnection(),
      _ => null,
    };

    final failure = switch (status) {
      AsyncError(:final ConnectionFailure error) => error,
      AsyncValue(valueOrNull: Disconnected(connectionFailure: final failure?)) => failure,
      _ => null,
    };
    // the speeds the button's light follows while connected
    final stats = ref.watch(statsNotifierProvider).valueOrNull;

    // Connected means some server answers; the user's pick or the chain hop can still be down.
    final health = ref.watch(connectionHealthProvider);
    final h = t.connection.health;
    final chainName = health?.chain?.present(t) ?? '';
    final degraded = look == _Look.connected && (health?.degraded ?? false);
    final hopPending = look == _Look.connected && (health?.hopPending ?? false);

    const buttonTheme = ConnectionButtonTheme.light;
    final today = DateTime.now();
    return _ConnectionButton(
      look: look,
      onTap: onTap,
      onErrorDetails: failure == null
          ? null
          : () => ref.read(dialogNotifierProvider.notifier).showCustomAlertFromErr(failure.present(t)),
      errorDetailsLabel: t.connection.errorDetails,
      download: stats?.downlink.toInt() ?? 0,
      upload: stats?.uplink.toInt() ?? 0,
      label: switch (look) {
        _Look.loading => "",
        _Look.disconnected => t.connection.tapToConnect,
        _Look.connecting => t.connection.connecting,
        _Look.waiting => t.connection.waiting,
        _Look.noProxies => t.connection.noAvailableProxies,
        // connected says the traffic gets through; when it does not, say what stops it
        _Look.connected when degraded =>
          health!.pick == HealthState.failed ? h.pickDead : h.hopFailed(chain: chainName),
        _Look.connected when hopPending => h.hopPending(chain: chainName),
        _Look.connected => t.connection.connected,
        _Look.hotReloading => t.connection.hotReloading,
        _Look.disconnecting => t.connection.disconnecting,
        _Look.failed => t.connection.failed,
      },
      hint: look == _Look.failed ? t.connection.tapToRetry : null,
      searching: hopPending,
      // the chain hop, while the core runs with the chain on
      hop: {_Look.connected, _Look.noProxies, _Look.waiting}.contains(look)
          ? ref.watch(activeProxyCardProvider.select((card) => card?.hopStatus == null ? null : card))
          : null,
      onHop: ref.read(bottomSheetsNotifierProvider.notifier).showConnectionHealth,
      hopLabel: health == null ? '' : '$chainName: ${_hopLabel(h, health)}',
      buttonColor: switch (look) {
        _Look.connected when degraded => _degradedColor,
        // the traffic waits for the chain hop: still on its way
        _Look.connected when hopPending => const Color(0xFF455FE9),
        _Look.connected => buttonTheme.connectedColor!,
        _Look.noProxies => const Color.fromARGB(255, 185, 176, 103),
        _Look.failed => Colors.red,
        // the logo's own blue while the connection is on its way
        _Look.connecting || _Look.waiting || _Look.hotReloading || _Look.disconnecting => const Color(0xFF455FE9),
        _ => buttonTheme.idleColor!,
      },
      image: switch (look) {
        _Look.connected || _Look.noProxies || _Look.hotReloading => Assets.images.connectNorouz,
        _ => Assets.images.disconnectNorouz,
      },
      useImage: today.day >= 19 && today.day <= 23 && today.month == 3,
    );
  }

  /// Coming back from the background, the app sets the core up again, and for a moment the status
  /// can read as not connected though the tunnel never went down. So leaving connected for
  /// [_Look.loading] waits [_hold] before it shows, and nothing changes if
  /// connected is back by then.
  ///
  /// Intentional disconnect must not keep the Connected label: it goes through
  /// [_Look.disconnecting], and a bare Connected→Disconnected jump (no Stopping event) must
  /// also clear immediately — holding disconnected made disconnect feel multi-second slow.
  /// A failure is failed, so it still shows at once.
  _Look _held(_Look look) {
    final shown = useRef(look);
    final until = useRef<DateTime?>(null);
    final rebuild = useState(0);
    final steady = {_Look.connected, _Look.noProxies}.contains(shown.value);
    final blip = {_Look.loading}.contains(look);
    var result = look;
    if (steady && blip) {
      until.value ??= DateTime.now().add(_hold);
      if (DateTime.now().isBefore(until.value!)) {
        result = shown.value;
      } else {
        until.value = null;
      }
    } else {
      until.value = null;
    }
    shown.value = result;
    // shows the new look once the hold is over, if nothing else rebuilds the button first
    useEffect(() {
      final end = until.value;
      if (end == null) return null;
      final timer = Timer(end.difference(DateTime.now()), () => rebuild.value++);
      return timer.cancel;
    }, [until.value]);
    return result;
  }

  static const _hold = Duration(milliseconds: 1500);

  /// Connected, but the traffic does not get through: amber, between connected and failed.
  static const _degradedColor = Color(0xFFE3A63A);

  static String _hopLabel(TranslationsConnectionHealthEn h, ConnectionHealth health) => switch (health.hopState) {
    HealthState.ok => h.hopReady,
    HealthState.pending => h.hopConnecting,
    HealthState.blocked => h.hopBlocked,
    HealthState.failed => health.hopNoReply ? h.hopNoReply : h.hopBroken,
  };

  /// Connects, or sends the user to add a profile when there is none.
  Future<void> _connect(WidgetRef ref) async {
    final dialogs = ref.read(dialogNotifierProvider.notifier);
    if (ref.read(activeProfileProvider).valueOrNull == null) {
      await dialogs.showNoActiveProfile();
      ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
      return;
    }
    if (await dialogs.showExperimentalFeatureNotice()) {
      await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    }
  }
}

class _ConnectionButton extends HookWidget {
  const _ConnectionButton({
    required this.look,
    required this.onTap,
    required this.onErrorDetails,
    required this.errorDetailsLabel,
    required this.download,
    required this.upload,
    required this.label,
    required this.hint,
    required this.searching,
    required this.hop,
    required this.onHop,
    required this.hopLabel,
    required this.buttonColor,
    required this.image,
    required this.useImage,
  });

  final _Look look;
  final VoidCallback? onTap;

  /// Shows what went wrong; null when nothing did.
  final VoidCallback? onErrorDetails;
  final String errorDetailsLabel;

  /// Bytes a second.
  final int download;
  final int upload;
  final String label;
  final String? hint;

  /// Connected, but the traffic still waits for the chain hop: the radar keeps searching.
  final bool searching;

  /// The chain hop as a badge on the button; null with the chain off.
  final ActiveProxyCardData? hop;

  /// Opens the connection check.
  final VoidCallback onHop;

  /// What the badge says to a screen reader and in its tooltip: the chain and its state.
  final String hopLabel;
  final Color buttonColor;
  final AssetGenImage image;
  final bool useImage;

  static const _size = 148.0;

  /// Room round the button for its light.
  static const _glow = 110.0;

  /// The button and its light take most of a short screen (a TV, a phone held sideways, a small
  /// window): full size from [_fullFrom] logical pixels of height, shrinking evenly to
  /// [_smallest] at [_smallFrom] and below.
  static const _fullFrom = 860.0;
  static const _smallFrom = 640.0;
  static const _smallest = .65;

  /// The frame intervals once a look has settled, one per [FrameLoad] level.
  static const _settledIntervals = [
    Duration(milliseconds: 50),
    Duration(milliseconds: 66),
    Duration(milliseconds: 100),
  ];

  /// Seconds after a look begins until its own motion is over: the connected look's spring and
  /// ripple, the error's shake. What follows only drifts.
  static const _settleAfter = 3.0;

  static double _scaleFor(double height) =>
      _smallest + (1 - _smallest) * ((height - _smallFrom) / (_fullFrom - _smallFrom)).clamp(0.0, 1.0);

  EclipseLook get _eclipseLook => switch (look) {
    _Look.loading || _Look.disconnected => EclipseLook.idle,
    _Look.connecting => EclipseLook.starting,
    _Look.disconnecting => EclipseLook.stopping,
    _Look.waiting || _Look.hotReloading => EclipseLook.waiting,
    _Look.connected when searching => EclipseLook.waiting,
    _Look.connected || _Look.noProxies => EclipseLook.connected,
    _Look.failed => EclipseLook.error,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final scale = _scaleFor(MediaQuery.sizeOf(context).height);
    final clock = useMemoized(() => Stopwatch()..start());
    double now() => clock.elapsedMicroseconds / 1e6;
    // keyboard / TV remote focus: a ring round the button, so the face and its logo stay visible
    final focused = useState(false);

    // when the look last changed, and from what
    final eclipseLook = _eclipseLook;
    final change = useRef((
      look: eclipseLook,
      previous: eclipseLook,
      at: -10.0,
      color: buttonColor,
      previousColor: buttonColor,
    ));
    final previousLook = usePrevious(look);
    // when the button last stopped showing connected
    final leftConnected = useRef(-10.0);
    if (change.value.look != eclipseLook || change.value.color != buttonColor) {
      final last = change.value;
      if (last.look == EclipseLook.connected && eclipseLook != EclipseLook.connected) leftConnected.value = now();
      final eased = Color.lerp(last.previousColor, last.color, ((now() - last.at) / .45).clamp(0.0, 1.0))!;
      // the app opening on a tunnel that is already up, or connected coming back
      // after a moment away, skips the connect animation instead of replaying it
      final skip =
          previousLook == _Look.loading || (eclipseLook == EclipseLook.connected && now() - leftConnected.value < 2);
      change.value = (
        look: eclipseLook,
        previous: last.look,
        at: skip ? now() - 10 : now(),
        color: buttonColor,
        previousColor: eased,
      );
    }

    // the speeds arrive once a second; the light follows them smoothly
    final target = useRef(const EclipseTraffic());
    target.value = EclipseTraffic(down: EclipseTraffic.level(download), up: EclipseTraffic.level(upload));
    final traffic = useRef(const EclipseTraffic());

    // Timer (not useSingleTickerProvider): that hook only allows one createTicker
    // for the State's life, so look/still changes crashed after disconnect→connect.
    // A timer does not stop with its tickers, so it stops itself while the button cannot be
    // seen: under another tab, sheet or route, or with the app not visible. TickerMode says
    // both; App turns it off for the whole app when the app is not visible.
    final ticking = useValueListenable(TickerMode.getNotifier(context));
    // A phone that cannot draw a frame in the 33 ms before the next one drops frames in bursts.
    // Measured, not guessed from the model: such a phone gets a steady 20 or 15 fps of the same
    // frames. A phone that keeps up sees nothing of this.
    final load = useMemoized(
      () => FrameLoad(const [Duration(milliseconds: 33), Duration(milliseconds: 50), Duration(milliseconds: 66)]),
    );
    final level = useValueListenable(load.level);
    // Once a look has settled, the light and the breathing move slowly enough for 20 fps; the
    // changes between looks keep 30. Each frame of the light costs the most of anything on the
    // page, so this is a third less of it for as long as the app stays connected.
    final settled = useValueNotifier(false);
    final calm = useValueListenable(settled);
    final interval = calm ? _settledIntervals[level] : load.interval;
    final time = useValueNotifier(0.0);
    useEffect(() {
      if (still || !ticking) return null;
      load.watch();
      var last = now();
      final timer = Timer.periodic(interval, (_) {
        final at = now();
        // the light rises with the traffic in about a second, and fades more slowly, so the
        // stats reloading for a moment (coming back from the background) barely dims it
        double follow(double from, double to) =>
            from + (to - from) * (1 - math.exp(-(at - last) / (to > from ? .8 : 2.5)));
        final t = traffic.value;
        traffic.value = EclipseTraffic(down: follow(t.down, target.value.down), up: follow(t.up, target.value.up));
        last = at;
        final since = at - change.value.at;
        settled.value = since > _settleAfter;
        final idle = change.value.look == EclipseLook.idle && since > 1;
        if (!idle) time.value = at;
      });
      return () {
        timer.cancel();
        load.unwatch();
      };
    }, [still, ticking, interval]);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: onTap != null,
          label: label,
          hint: hint,
          // drawn at full size, then scaled as a whole (light and badges too) to fit short screens
          child: SizedBox.square(
            dimension: _size * scale,
            child: OverflowBox(
              minWidth: _size,
              maxWidth: _size,
              minHeight: _size,
              maxHeight: _size,
              child: Transform.scale(
                scale: scale,
                child: SizedBox.square(
                  dimension: _size,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -_glow,
                        top: -_glow,
                        right: -_glow,
                        bottom: -_glow,
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: ValueListenableBuilder(
                              valueListenable: time,
                              builder: (context, t, _) {
                                final c = change.value;
                                return CustomPaint(
                                  isComplex: true,
                                  willChange: true,
                                  painter: EclipseButtonPainter(
                                    frame: EclipseFrame(
                                      look: c.look,
                                      previous: c.previous,
                                      since: still ? 10 : now() - c.at,
                                      time: still ? 0 : now(),
                                      color: c.color,
                                      previousColor: c.previousColor,
                                    ),
                                    radius: _size / 2,
                                    traffic: traffic.value,
                                    dark: theme.brightness == Brightness.dark,
                                    drawLogo: !useImage,
                                    logoOpacity: look == _Look.loading ? .38 : 1,
                                    pixelRatio: MediaQuery.devicePixelRatioOf(context),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      // the ink only tints the face a little: a solid hover or focus color would hide the logo
                      Material(
                        key: const ValueKey("home_connection_button"),
                        shape: const CircleBorder(),
                        color: Colors.transparent,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onTap,
                          onFocusChange: (value) => focused.value = value,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.black.withValues(alpha: .05),
                          highlightColor: Colors.black.withValues(alpha: .06),
                          splashColor: Colors.black.withValues(alpha: .08),
                          child: useImage ? Padding(padding: const EdgeInsets.all(36), child: image.image()) : null,
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: focused.value ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Transform.scale(
                              scale: 1.1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.colorScheme.primary, width: 3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // the error badge opens what went wrong
                      if (look == _Look.failed && onErrorDetails != null)
                        Positioned.fromRect(
                          rect: EclipseButtonPainter.errorBadgeRect(
                            const Offset(_size / 2, _size / 2),
                            _size / 2,
                          ).inflate(8),
                          child: Semantics(
                            button: true,
                            label: errorDetailsLabel,
                            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onErrorDetails),
                          ),
                        ),
                      // the chain hop sits on the rim at the top left, half on the button
                      if (hop case final hop?)
                        Positioned.fromRect(
                          rect: Rect.fromCircle(
                            center:
                                const Offset(_size / 2, _size / 2) + Offset.fromDirection(5 * math.pi / 4, _size / 2),
                            radius: _ChainBadge.size / 2,
                          ),
                          child: _ChainBadge(hop, label: hopLabel, onTap: onHop),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Gap(24 * scale),
        Column(
          children: [
            AnimatedText(label, style: theme.textTheme.titleMedium),
            AnimatedSwitcher(
              layoutBuilder: uniqueKeysLayout(),
              duration: const Duration(milliseconds: 250),
              child: hint == null
                  ? const SizedBox.shrink()
                  : Text(
                      hint!,
                      key: ValueKey(hint),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The chain hop on the button: its glyph alone, outlined in the button's face color so it reads
/// on the button and on the page. Filled with a check once up, an outline that breathes while it
/// connects, red with a cross when it fails, grey while it waits for the selected proxy. Opens the
/// connection check.
class _ChainBadge extends StatelessWidget {
  const _ChainBadge(this.card, {required this.label, required this.onTap});
  final ActiveProxyCardData card;
  final String label;
  final VoidCallback onTap;

  static const size = 56.0;

  ChainType get _type => card.chain.isUnblocker() ? ChainType.unblocker : ChainType.extraSecurity;

  IconData get _glyph => switch ((_type, card.hopStatus!)) {
    (ChainType.extraSecurity, StepStatus.connected) => Icons.gpp_good_rounded,
    (ChainType.extraSecurity, StepStatus.failed) => Icons.gpp_bad_rounded,
    (ChainType.extraSecurity, _) => Icons.shield_outlined,
    // a door, not a lock: the unblocker gets the proxy through, it does not secure it. Drawn by
    // PassingDoor; these only tell its running state from its shut one, to switch between them
    (ChainType.unblocker, StepStatus.connected || StepStatus.connecting || StepStatus.slow) =>
      Icons.meeting_room_rounded,
    (ChainType.unblocker, _) => Icons.door_front_door_rounded,
  };

  Widget _glyphWidget(StepStatus status) => switch ((_type, status)) {
    // the traffic keeps getting through on its way and once up, as on the proxy card; shut while it
    // waits or fails
    (ChainType.unblocker, _) => PassingDoor(
      size: _glyphSize,
      color: Colors.white,
      animate: status == StepStatus.connecting || status == StepStatus.slow || status == StepStatus.connected,
    ),
    _ => Icon(_glyph, size: _glyphSize, color: Colors.white),
  };

  /// The solid shape under the glyph: the white seal that strokes it and fills its cut-outs. The
  /// door sits on a disc, smaller to stay inside it.
  IconData get _seal => _type == ChainType.extraSecurity ? Icons.shield_rounded : Icons.circle;
  double get _glyphSize => _type == ChainType.extraSecurity ? 40 : 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = card.hopStatus!;
    final (main, accent) = _type.colors(card.hopMode);
    // a gradient in the chain's own colors; red when it fails, grey while it waits
    final (from, to) = switch (status) {
      StepStatus.failed => (const Color(0xFFFF6B6B), theme.colorScheme.error),
      StepStatus.waiting => (theme.colorScheme.outline, theme.colorScheme.outlineVariant),
      _ => (main, accent),
    };
    const face = Color(0xFFF7F7F9);
    Widget glyph = SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // the seal: a little larger than the glyph, so it reads as a white stroke, with a soft
          // glow in the state's color
          Icon(
            _seal,
            size: 50,
            color: face,
            shadows: [
              Shadow(color: from.withValues(alpha: status == StepStatus.waiting ? .2 : .55), blurRadius: 14),
              Shadow(color: Colors.black.withValues(alpha: .25), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [from, to],
            ).createShader(rect),
            child: _glyphWidget(status),
          ),
        ],
      ),
    );
    glyph = switch (status) {
      _ when MediaQuery.disableAnimationsOf(context) => glyph,
      // once up, a light sweeps across it now and then
      StepStatus.connected =>
        glyph
            .animate(onPlay: (c) => c.repeat())
            .shimmer(delay: 2500.ms, duration: 1200.ms, color: Colors.white.withValues(alpha: .7)),
      // on its way: the door opening says so; the shield breathes
      StepStatus.connecting || StepStatus.slow when _type == ChainType.unblocker => glyph,
      StepStatus.connecting || StepStatus.slow =>
        glyph
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: .92, end: 1.04, duration: 900.ms, curve: Curves.easeInOut),
      // failed: one short shake to catch the eye
      StepStatus.failed => glyph.animate().shake(hz: 4, rotation: .06, duration: 500.ms),
      StepStatus.waiting => glyph,
    };
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          // its shimmer and breathing repaint the badge alone, not the button and the page
          child: RepaintBoundary(
            child: Center(
              child: AnimatedSwitcher(
                layoutBuilder: uniqueKeysLayout(),
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: KeyedSubtree(key: ValueKey(_glyph), child: glyph),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
