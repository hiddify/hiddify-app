import 'dart:math' as math;
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Keeps an animation's own frame rate within what the device can draw.
///
/// Give it the intervals the animation can tick at, fastest first; [level] names the one to use
/// now. It rises when the frames being drawn cost more than most of the current interval (the
/// next tick would come before this frame is done, so frames drop in bursts), and falls, after
/// [calm] of cheap frames, when they would fit a faster interval again. A device that keeps up
/// never leaves level 0, so what it shows does not change.
///
/// Call [watch] while the animation runs and [unwatch] when it stops: frames are measured only
/// then, and a frame's cost is the slower of its build and its raster, which run in parallel.
class FrameLoad {
  FrameLoad(this.intervals) : assert(intervals.isNotEmpty);

  final List<Duration> intervals;
  final level = ValueNotifier(0);

  Duration get interval => intervals[level.value];

  /// The share of an interval a frame may take before the next level is used.
  static const _full = .6;

  /// The share of the faster interval a frame must stay under, for [calm], to go back to it.
  static const _light = .3;
  static const calm = Duration(seconds: 3);

  /// Moving average of a frame's cost, in ms.
  double _cost = 0;
  int? _calmSince;
  int _users = 0;

  void watch() {
    if (_users++ == 0) SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void unwatch() {
    if (--_users == 0) SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final ms = math.max(t.buildDuration.inMicroseconds, t.rasterDuration.inMicroseconds) / 1000;
      _cost = _cost == 0 ? ms : _cost + (ms - _cost) * .15;
      final l = level.value;
      final at = t.timestampInMicroseconds(FramePhase.rasterFinish);
      if (l + 1 < intervals.length && _cost > intervals[l].inMilliseconds * _full) {
        level.value = l + 1;
        _calmSince = null;
      } else if (l > 0 && _cost < intervals[l - 1].inMilliseconds * _light) {
        _calmSince ??= at;
        if (at - _calmSince! >= calm.inMicroseconds) {
          level.value = l - 1;
          _calmSince = null;
        }
      } else {
        _calmSince = null;
      }
    }
  }
}
