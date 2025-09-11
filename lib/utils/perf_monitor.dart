import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:hiddify/core/logger/logger.dart';

/// Lightweight performance/jank monitor for production builds.
class PerfMonitor {
  PerfMonitor._();
  static final PerfMonitor instance = PerfMonitor._();

  bool _initialized = false;
  bool _enabled = true; // keep logging in release; overlay is opt-in
  Duration slowFrame = const Duration(milliseconds: 250);
  Duration slowOp = const Duration(milliseconds: 150);

  void init({bool enabled = true, Duration? slowFrame, Duration? slowOp}) {
    if (_initialized) return;
    _enabled = enabled;
    if (slowFrame != null) {
      this.slowFrame = slowFrame;
    }
    if (slowOp != null) {
      this.slowOp = slowOp;
    }
    _initialized = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!_enabled) return;
    for (final t in timings) {
      final total = t.totalSpan;
      if (total >= slowFrame) {
        Logger.app.warning(
          'Slow frame: build=${_us(t.buildDuration)}µs, raster=${_us(t.rasterDuration)}µs, total=${total.inMilliseconds}ms',
        );
      }
    }
  }

  Future<T> measure<T>(String label, FutureOr<T> Function() action) async {
    final sw = Stopwatch()..start();
    try {
      final result = await Future<T>.microtask(() => action());
      return result;
    } finally {
      sw.stop();
      if (sw.elapsed >= slowOp) {
        Logger.app.warning('Slow op [$label]: ${sw.elapsedMilliseconds}ms');
      } else {
        Logger.app.info('Op [$label]: ${sw.elapsedMilliseconds}ms');
      }
    }
  }

  static int _us(Duration d) => d.inMicroseconds;
}

/// Small overlay using Flutter's built-in PerformanceOverlay (opt-in in UI).
class PerfOverlay extends StatelessWidget {
  const PerfOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: 160,
        height: 120,
        child: PerformanceOverlay.allEnabled(),
      ),
    );
  }
}


