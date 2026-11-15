import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hiddify/core/widget/frame_load.dart';

/// Whether purely decorative, endless motion runs now: the chain icons' orbiting light and passing
/// door, the chain badge's shine, the loading shimmer.
///
/// It runs for [ambientFor] after it may start (see [allowAmbientMotion]) and after each
/// [wakeAmbientMotion], then stands still: an endless loop costs a frame many times a second for
/// as long as the app stays connected, which even a fast laptop shows in its CPU use.
///
/// The light around the connect button does not stop with it: it moves for as long as the
/// decoration may run at all ([ambientMotionAllowed]). A light that froze where it was, and then
/// jumped with the traffic once a second, looked as if the app had hung.
///
/// Never while a desktop window has no focus, or while the battery
/// is low or saving power. Desktop windows without focus keep updating (connection state, proxies,
/// logs), so TickerMode stays on for them; only these loops stop.
final ValueNotifier<bool> ambientMotion = ValueNotifier(false);

/// Whether the app can be seen at all: it is not hidden or in the background, and on a desktop its
/// window is not hidden in the tray or minimized. While it cannot, nothing moves: the
/// [AmbientClock] stops, and App turns tickers off.
///
/// It changes as soon as the app is hidden. Flutter draws no frame while the app is hidden or in
/// the background, so whatever waits for a build to stop its timers only stopped them when the
/// app came back: the clock went on ticking 20 to 30 times a second for nothing.
ValueListenable<bool> get appSeen => _appSeen;
final _appSeen = ValueNotifier(true);
var _lifecycleSeen = true;
var _windowHidden = false;

/// Follows the app's lifecycle: hidden, paused and detached cannot be seen. A desktop window
/// that has the focus again is shown, however it was brought back (the tray, the dock, a second
/// launch).
void seeLifecycle(AppLifecycleState? state) {
  _lifecycleSeen = switch (state) {
    null || AppLifecycleState.resumed || AppLifecycleState.inactive => true,
    AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached => false,
  };
  if (state == AppLifecycleState.resumed) _windowHidden = false;
  _appSeen.value = _lifecycleSeen && !_windowHidden;
}

/// A desktop window hidden in the tray or minimized cannot be seen, whatever the engine reports.
void seeWindow({required bool hidden}) {
  _windowHidden = hidden;
  _appSeen.value = _lifecycleSeen && !_windowHidden;
}

/// Whether the desktop window has the focus, as the window reports it: on Windows the lifecycle
/// does not always say so. Without it the light stands still.
final ValueNotifier<bool> windowFocused = ValueNotifier(true);

/// How long the endless decoration runs each time it starts.
const ambientFor = Duration(seconds: 10);

final _ambientAllowed = ValueNotifier(false);
Timer? _ambientSleep;

/// Whether endless decoration may run at all (see [allowAmbientMotion]), though [ambientMotion]
/// may have stopped for now.
ValueListenable<bool> get ambientMotionAllowed => _ambientAllowed;

/// Whether endless decoration may run at all: the app is seen (a desktop window has focus), the
/// battery is fine. Becoming allowed starts it for [ambientFor].
void allowAmbientMotion(bool allowed) {
  if (allowed == _ambientAllowed.value) return;
  _ambientAllowed.value = allowed;
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
  if (!_ambientAllowed.value) return;
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
///
/// It steps no faster than the device affords its frames ([FrameLoad]). Drawing without a graphics
/// card, a frame costs tens of milliseconds of CPU whatever changed in it, most of it to put the
/// whole window on the screen: there the clock steps less often, down to 10 times a second, which
/// the slow motion still shows smoothly. A device that keeps up never sees this.
abstract final class AmbientClock {
  /// The rate a decoration asks for: its motion is slow enough for 20 fps.
  static const decoration = Duration(milliseconds: 50);

  /// The rate a change asks for while it plays, such as the connect button going to another look.
  static const lively = Duration(milliseconds: 33);

  static final _clock = Stopwatch()..start();
  static final _ticks = <({Duration interval, void Function() onTick})>[];
  static Timer? _timer;
  static Duration? _interval;

  /// The rates the frames can be afforded at, fastest first; measured while the clock runs.
  static final _load = FrameLoad(const [lively, decoration, Duration(milliseconds: 66), Duration(milliseconds: 100)]);
  static var _measuring = false;

  /// Seconds since the app started; what every loop takes its phase from, so they keep in step.
  static double get now => _clock.elapsedMicroseconds / 1e6;

  /// Calls [onTick] at [interval] or faster, until the returned function is called. It is called
  /// less often than [interval] where the device cannot afford the frames, and not at all while
  /// the app cannot be seen ([appSeen]).
  static VoidCallback subscribe(Duration interval, VoidCallback onTick) {
    final tick = (interval: interval, onTick: onTick);
    _ticks.add(tick);
    _retime();
    return () {
      _ticks.remove(tick);
      _retime();
    };
  }

  static var _following = false;

  static void _retime() {
    if (!_following) {
      _following = true;
      _appSeen.addListener(_retime);
    }
    Duration? fastest;
    if (_appSeen.value) {
      for (final t in _ticks) {
        if (fastest == null || t.interval < fastest) fastest = t.interval;
      }
    }
    _measure(fastest != null);
    // no faster than the device affords the frames
    if (fastest != null && _load.interval > fastest) fastest = _load.interval;
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

  /// Measures what the frames cost while something moves, and follows it.
  static void _measure(bool on) {
    if (on == _measuring) return;
    _measuring = on;
    if (on) {
      _load.watch();
      _load.level.addListener(_retime);
    } else {
      _load.level.removeListener(_retime);
      _load.unwatch();
    }
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
