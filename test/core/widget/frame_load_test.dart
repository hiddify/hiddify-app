import 'dart:ui' show FrameTiming;

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/widget/frame_load.dart';

const _intervals = [
  Duration(milliseconds: 33),
  Duration(milliseconds: 50),
  Duration(milliseconds: 66),
  Duration(milliseconds: 100),
];

/// A device drawing frames: the clock its frames are stamped with, and the CPU time the app used.
class _Device {
  int _at = 1000000;
  Duration cpu = Duration.zero;

  /// Draws frames every [every] for [seconds], each taking [raster] ms to raster and [cpuMs] ms of
  /// the app's CPU time, and reports them to [load] in batches once a second, as a release build
  /// does.
  void draw(
    FrameLoad load, {
    required double seconds,
    Duration every = const Duration(milliseconds: 50),
    double raster = 2,
    double cpuMs = 2,
  }) {
    final end = _at + (seconds * 1e6).round();
    var batch = <FrameTiming>[];
    var report = _at + 1000000;
    while (_at < end) {
      final rasterUs = (raster * 1000).round();
      batch.add(
        FrameTiming(
          vsyncStart: _at,
          buildStart: _at,
          buildFinish: _at + 500,
          rasterStart: _at + 500,
          rasterFinish: _at + 500 + rasterUs,
          rasterFinishWallTime: _at + 500 + rasterUs,
        ),
      );
      cpu += Duration(microseconds: (cpuMs * 1000).round());
      _at += every.inMicroseconds;
      if (_at >= report) {
        load.debugReport(batch);
        batch = [];
        report += 1000000;
      }
    }
    if (batch.isNotEmpty) load.debugReport(batch);
  }
}

void main() {
  test('a device that keeps up steps at the fastest rate', () {
    final device = _Device();
    final load = FrameLoad(_intervals, cpuTime: () => device.cpu);
    device.draw(load, seconds: 20);
    expect(load.level.value, 0);
  });

  test('frames that take most of the interval to raster step less often', () {
    final device = _Device();
    final load = FrameLoad(_intervals, cpuTime: () => device.cpu);
    device.draw(load, seconds: 10, raster: 25);
    expect(load.interval, const Duration(milliseconds: 50));
  });

  test('frames that cost much CPU outside their timings step less often, down to the slowest rate', () {
    // drawing without a graphics card: the frame itself is quick, putting the window on the
    // screen is not
    final device = _Device();
    final load = FrameLoad(_intervals, cpuTime: () => device.cpu);
    device.draw(load, seconds: 10, cpuMs: 40);
    expect(load.interval, const Duration(milliseconds: 100));
  });

  test('a moderate cost settles on the fastest rate within a fifth of a core', () {
    final device = _Device();
    final load = FrameLoad(_intervals, cpuTime: () => device.cpu);
    // 12 ms a frame: 36% of a core at 33 ms, 24% at 50 ms, 18% at 66 ms
    device.draw(load, seconds: 10, cpuMs: 12);
    expect(load.interval, const Duration(milliseconds: 66));
  });

  test('one costly stretch, such as the app starting, is not taken for what frames cost', () {
    final device = _Device();
    final load = FrameLoad(_intervals, cpuTime: () => device.cpu);
    device.draw(load, seconds: 2, cpuMs: 200);
    device.draw(load, seconds: 20);
    expect(load.level.value, 0);
  });

  test('it goes back to the fastest rate once the frames are cheap again', () {
    final device = _Device();
    final load = FrameLoad(_intervals, cpuTime: () => device.cpu);
    device.draw(load, seconds: 10, cpuMs: 40);
    expect(load.level.value, 3);
    device.draw(load, seconds: 20);
    expect(load.level.value, 0);
  });

  test('without the CPU time, as on a phone, only the timings count', () {
    final device = _Device();
    final load = FrameLoad(_intervals, cpuTime: () => null);
    device.draw(load, seconds: 10, cpuMs: 40);
    expect(load.level.value, 0);
  });
}
