import 'dart:math' as math;
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:hiddify/core/utils/process_cpu_time.dart';

/// Keeps an animation's own frame rate within what the device can afford.
///
/// Give it the intervals the animation can tick at, fastest first; [level] names the one to use
/// now. It rises when the frames being drawn cost too much for the current interval, and falls,
/// after [calm] of cheap frames, when they would fit a faster interval again. A device that keeps
/// up never leaves level 0, so what it shows does not change.
///
/// A frame costs too much for an interval in two ways:
/// - its build or its raster, which run in parallel, take most of it: the next tick would come
///   before the frame is done, and frames drop in bursts;
/// - on a desktop, the CPU time the app spends on it is more than [cpuShare] of it. Drawing
///   without a graphics card, putting the window on the screen costs most of a frame, and a
///   frame's timings do not show that part; the app's CPU time does. The core runs in a process
///   of its own there, so the app's CPU time is what its frames cost.
///
/// Call [watch] while the animation runs and [unwatch] when it stops: frames are measured only
/// then.
class FrameLoad {
  FrameLoad(this.intervals, {this.cpuShare = .2, Duration? Function() cpuTime = processCpuTime})
    : assert(intervals.isNotEmpty),
      _cpuTime = cpuTime;

  final List<Duration> intervals;

  /// The share of one core the app may spend on its frames, where its CPU time can be read.
  final double cpuShare;

  /// The CPU time the app has used so far; null where it cannot be read.
  final Duration? Function() _cpuTime;

  final level = ValueNotifier(0);

  Duration get interval => intervals[level.value];

  /// The share of an interval a frame may take before the next level is used.
  static const _full = .6;

  /// The share of the faster interval a frame must stay under, for [calm], to go back to it.
  static const _light = .3;

  /// The share of [cpuShare] the CPU time of a frame must stay under, for [calm], to go back.
  static const _cpuLight = .5;
  static const calm = Duration(seconds: 3);

  /// How long the CPU time is measured over at the least: Windows counts it in steps of 15.6 ms.
  static const _cpuWindow = Duration(seconds: 2);

  /// Moving average of a frame's cost, in ms.
  double _cost = 0;

  /// The CPU time a frame costs, in ms: the lower of the last two measurements, so one costly
  /// stretch (the app starting, a profile loading) is not taken for what frames cost.
  double _cpu = 0;
  double _lastCpu = 0;

  /// Where the measurement under way began: the CPU time then, and the frame it came after.
  Duration? _cpuFrom;
  int? _cpuSince;
  int _cpuFrames = 0;

  int? _calmSince;
  int _users = 0;

  void watch() {
    if (_users++ == 0) SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void unwatch() {
    if (--_users > 0) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    // the time until it is watched again draws nothing of its own: the next measurement starts
    // afresh
    _cpuFrom = null;
  }

  @visibleForTesting
  void debugReport(List<FrameTiming> timings) => _onTimings(timings);

  void _onTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    _measureCpu(timings);
    for (final t in timings) {
      final ms = math.max(t.buildDuration.inMicroseconds, t.rasterDuration.inMicroseconds) / 1000;
      _cost = _cost == 0 ? ms : _cost + (ms - _cost) * .15;
      _adjust(t.timestampInMicroseconds(FramePhase.rasterFinish));
    }
  }

  /// The CPU time a frame costs: what the app used over at least [_cpuWindow], over the frames it
  /// drew in it. The frames are reported in batches, once a second in a release build, and the
  /// CPU time is read as each batch comes, so the two cover the same stretch.
  void _measureCpu(List<FrameTiming> timings) {
    final at = timings.last.timestampInMicroseconds(FramePhase.rasterFinish);
    final from = _cpuFrom;
    final since = _cpuSince;
    if (from == null || since == null) {
      // the frames in this batch were drawn before the measurement begins
      _cpuFrom = _cpuTime();
      _cpuSince = at;
      _cpuFrames = 0;
      return;
    }
    _cpuFrames += timings.length;
    if (at - since < _cpuWindow.inMicroseconds) return;
    final now = _cpuTime();
    if (now == null) return;
    final perFrame = (now - from).inMicroseconds / 1000 / _cpuFrames;
    _cpu = math.min(perFrame, _lastCpu);
    _lastCpu = perFrame;
    _cpuFrom = now;
    _cpuSince = at;
    _cpuFrames = 0;
  }

  /// Moves to the next level if the frames cost too much for this one, or back to the one before
  /// once they have fit it for [calm].
  void _adjust(int at) {
    final l = level.value;
    final current = intervals[l].inMicroseconds / 1000;
    if (l + 1 < intervals.length && (_cost > current * _full || _cpu > current * cpuShare)) {
      level.value = l + 1;
      _calmSince = null;
    } else if (l > 0 && _fits(intervals[l - 1].inMicroseconds / 1000)) {
      _calmSince ??= at;
      if (at - _calmSince! >= calm.inMicroseconds) {
        level.value = l - 1;
        _calmSince = null;
      }
    } else {
      _calmSince = null;
    }
  }

  /// Whether the frames cost little enough for an interval of [faster] ms.
  bool _fits(double faster) => _cost < faster * _light && _cpu < faster * cpuShare * _cpuLight;
}
