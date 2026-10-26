import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/home/widget/eclipse_button_painter.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
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
        _Look.connected => t.connection.connected,
        _Look.hotReloading => t.connection.hotReloading,
        _Look.disconnecting => t.connection.disconnecting,
        _Look.failed => t.connection.failed,
      },
      hint: look == _Look.failed ? t.connection.tapToRetry : null,
      buttonColor: switch (look) {
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
  final Color buttonColor;
  final AssetGenImage image;
  final bool useImage;

  static const _size = 148.0;

  /// Room round the button for its light.
  static const _glow = 110.0;

  EclipseLook get _eclipseLook => switch (look) {
    _Look.loading || _Look.disconnected => EclipseLook.idle,
    _Look.connecting => EclipseLook.starting,
    _Look.disconnecting => EclipseLook.stopping,
    _Look.waiting || _Look.hotReloading => EclipseLook.waiting,
    _Look.connected || _Look.noProxies => EclipseLook.connected,
    _Look.failed => EclipseLook.error,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final clock = useMemoized(() => Stopwatch()..start());
    double now() => clock.elapsedMicroseconds / 1e6;

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
    final time = useValueNotifier(0.0);
    useEffect(() {
      if (still) return null;
      var last = now();
      final timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
        final at = now();
        // the light rises with the traffic in about a second, and fades more slowly, so the
        // stats reloading for a moment (coming back from the background) barely dims it
        double follow(double from, double to) =>
            from + (to - from) * (1 - math.exp(-(at - last) / (to > from ? .8 : 2.5)));
        final t = traffic.value;
        traffic.value = EclipseTraffic(down: follow(t.down, target.value.down), up: follow(t.up, target.value.up));
        last = at;
        final settled = change.value.look == EclipseLook.idle && at - change.value.at > 1;
        if (!settled) time.value = at;
      });
      return timer.cancel;
    }, [still]);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: onTap != null,
          label: label,
          hint: hint,
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
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Material(
                  key: const ValueKey("home_connection_button"),
                  shape: const CircleBorder(),
                  color: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    focusColor: Colors.grey,
                    onTap: onTap,
                    child: useImage ? Padding(padding: const EdgeInsets.all(36), child: image.image()) : null,
                  ),
                ),
                // the error badge opens what went wrong
                if (look == _Look.failed && onErrorDetails != null)
                  Positioned.fromRect(
                    rect: EclipseButtonPainter.errorBadgeRect(const Offset(_size / 2, _size / 2), _size / 2).inflate(8),
                    child: Semantics(
                      button: true,
                      label: errorDetailsLabel,
                      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onErrorDetails),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Gap(24),
        ExcludeSemantics(
          child: Column(
            children: [
              AnimatedText(label, style: theme.textTheme.titleMedium),
              AnimatedSwitcher(
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
        ),
      ],
    );
  }
}
