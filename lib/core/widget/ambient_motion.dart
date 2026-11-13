import 'dart:async';

import 'package:flutter/widgets.dart';

/// Whether purely decorative, endless motion runs now: the light around the connect button, the
/// chain icons' orbiting light and passing door, the chain badge's shine, the loading shimmer.
///
/// It runs for [ambientFor] after it may start (see [allowAmbientMotion]) and after each
/// [wakeAmbientMotion], then stands still: an endless loop costs a frame many times a second for
/// as long as the app stays connected, which even a fast laptop shows in its CPU use.
///
/// Never while a desktop window has no focus, or while the battery
/// is low or saving power. Desktop windows without focus keep updating (connection state, proxies,
/// logs), so TickerMode stays on for them; only these loops stop.
final ValueNotifier<bool> ambientMotion = ValueNotifier(false);

/// How long the endless decoration runs each time it starts.
const ambientFor = Duration(seconds: 10);

bool _ambientAllowed = false;
Timer? _ambientSleep;

/// Whether endless decoration may run at all (see [allowAmbientMotion]), though it may have stopped
/// for now.
bool get ambientMotionAllowed => _ambientAllowed;

/// Whether endless decoration may run at all: the app is seen (a desktop window has focus), the
/// battery is fine. Becoming allowed starts it for [ambientFor].
void allowAmbientMotion(bool allowed) {
  if (allowed == _ambientAllowed) return;
  _ambientAllowed = allowed;
  if (allowed) {
    wakeAmbientMotion();
  } else {
    _ambientSleep?.cancel();
    _ambientSleep = null;
    ambientMotion.value = false;
  }
}

/// Runs the endless decoration again for [ambientFor], where it may run: something it shows has
/// changed (the connection).
void wakeAmbientMotion() {
  if (!_ambientAllowed) return;
  ambientMotion.value = true;
  _ambientSleep?.cancel();
  _ambientSleep = Timer(ambientFor, () {
    _ambientSleep = null;
    ambientMotion.value = false;
  });
}

/// The one timer behind every endless decoration.
///
/// Each loop that ran on its own ticker asked for a frame at every refresh of the screen, 60 to 120
/// a second, for as long as the app stayed connected; a small orbit was enough to keep a fast
/// laptop's app at a fifth of a core. They all move slowly, so they now share this timer and step
/// together, at the fastest rate one of them asks for (the connect button's light, 30 fps or less),
/// and draw in the same frames.
abstract final class AmbientClock {
  /// The rate a decoration asks for: its motion is slow enough for 20 fps.
  static const decoration = Duration(milliseconds: 50);

  static final _clock = Stopwatch()..start();
  static final _ticks = <({Duration interval, void Function() onTick})>[];
  static Timer? _timer;
  static Duration? _interval;

  /// Seconds since the app started; what every loop takes its phase from, so they keep in step.
  static double get now => _clock.elapsedMicroseconds / 1e6;

  /// Calls [onTick] at [interval] or faster, until the returned function is called.
  static VoidCallback subscribe(Duration interval, VoidCallback onTick) {
    final tick = (interval: interval, onTick: onTick);
    _ticks.add(tick);
    _retime();
    return () {
      _ticks.remove(tick);
      _retime();
    };
  }

  static void _retime() {
    Duration? fastest;
    for (final t in _ticks) {
      if (fastest == null || t.interval < fastest) fastest = t.interval;
    }
    if (fastest == _interval) return;
    _timer?.cancel();
    _timer = null;
    _interval = fastest;
    if (fastest == null) return;
    _timer = Timer.periodic(fastest, (_) {
      for (final t in List.of(_ticks)) {
        t.onTick();
      }
    });
  }
}

/// Builds [moving] while endless decoration may run (see [ambientMotion]), the system does not ask
/// for reduced motion, and the widget can be seen (TickerMode, off under another route), [still]
/// otherwise.
class AmbientMotionBuilder extends StatelessWidget {
  const AmbientMotionBuilder({super.key, required this.moving, required this.still});

  final WidgetBuilder moving;
  final WidgetBuilder still;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: TickerMode.getNotifier(context),
    builder: (context, visible, _) => ValueListenableBuilder<bool>(
      valueListenable: ambientMotion,
      builder: (context, ambient, _) =>
          visible && ambient && !MediaQuery.disableAnimationsOf(context) ? moving(context) : still(context),
    ),
  );
}

/// An endless loop of [period] on the [AmbientClock], while [AmbientMotionBuilder] lets it move;
/// [still] otherwise. [builder] gets the loop's phase, from 0 to 1, as a notifier: drive an
/// [Animate] with a `ValueNotifierAdapter` of it, so no ticker of its own runs.
class AmbientLoop extends StatelessWidget {
  const AmbientLoop({super.key, required this.period, required this.builder, required this.still});

  final Duration period;
  final Widget Function(BuildContext context, ValueNotifier<double> phase) builder;
  final WidgetBuilder still;

  @override
  Widget build(BuildContext context) => AmbientMotionBuilder(
    still: still,
    moving: (context) => _AmbientLoopRunner(period: period, builder: builder),
  );
}

class _AmbientLoopRunner extends StatefulWidget {
  const _AmbientLoopRunner({required this.period, required this.builder});

  final Duration period;
  final Widget Function(BuildContext context, ValueNotifier<double> phase) builder;

  @override
  State<_AmbientLoopRunner> createState() => _AmbientLoopRunnerState();
}

class _AmbientLoopRunnerState extends State<_AmbientLoopRunner> {
  final _phase = ValueNotifier(0.0);
  late final VoidCallback _unsubscribe;

  void _tick() {
    final period = widget.period.inMicroseconds / 1e6;
    _phase.value = AmbientClock.now % period / period;
  }

  @override
  void initState() {
    super.initState();
    _tick();
    _unsubscribe = AmbientClock.subscribe(AmbientClock.decoration, _tick);
  }

  @override
  void dispose() {
    _unsubscribe();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _phase);
}
