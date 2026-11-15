import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/home/widget/eclipse_button_painter.dart';

const _box = 368.0;
const _radius = 74.0;
const _background = Color(0xFF14161A);
const _green = Color(0xFF2E7D32);

EclipseButtonPainter _button({
  EclipseLook look = EclipseLook.connected,
  EclipseLook? previous,
  double since = 20,
  double time = 20,
  double down = 0,
  double up = 0,
  bool dark = true,
  double pixelRatio = 1,
  bool simple = false,
}) => EclipseButtonPainter(
  frame: EclipseFrame(
    look: look,
    previous: previous ?? look,
    since: since,
    time: time,
    color: _green,
    previousColor: _green,
  ),
  radius: _radius,
  traffic: EclipseTraffic(down: down, up: up),
  dark: dark,
  pixelRatio: pixelRatio,
  simple: simple,
);

ui.Picture _record(EclipseButtonPainter painter, {Color background = _background}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, _box, _box), Paint()..color = background);
  painter.paint(canvas, const Size.square(_box));
  return recorder.endRecording();
}

Future<ByteData> _pixels(EclipseButtonPainter painter, {Color background = _background}) async {
  final picture = _record(painter, background: background);
  final image = await picture.toImage(_box.toInt(), _box.toInt());
  picture.dispose();
  final bytes = await image.toByteData();
  image.dispose();
  return bytes!;
}

/// The mean red, green and blue round the button, [out] pixels from its edge.
(double, double, double) _round(ByteData pixels, double out) {
  var r = 0;
  var g = 0;
  var b = 0;
  for (var a = 0; a < 360; a++) {
    final x = (_box / 2 + math.cos(a * math.pi / 180) * (_radius + out)).round();
    final y = (_box / 2 + math.sin(a * math.pi / 180) * (_radius + out)).round();
    final at = (y * _box.toInt() + x) * 4;
    r += pixels.getUint8(at);
    g += pixels.getUint8(at + 1);
    b += pixels.getUint8(at + 2);
  }
  return (r / 360, g / 360, b / 360);
}

void main() {
  test('every look can be drawn at any moment, with any traffic', () async {
    // the light is a mesh in buffers of a fixed size: nothing it is asked for may overflow them
    for (final look in EclipseLook.values) {
      for (final dark in [true, false]) {
        for (final (down, up) in [(0.0, 0.0), (.02, .02), (.2, .05), (.5, 1.0), (1.0, 1.0)]) {
          for (var time = 0.0; time < 40; time += 1.37) {
            for (final previous in [look, EclipseLook.idle, EclipseLook.connected]) {
              _record(
                _button(
                  look: look,
                  previous: previous,
                  since: time % 7,
                  time: time,
                  down: down,
                  up: up,
                  dark: dark,
                  pixelRatio: dark ? 1 : 3,
                ),
              ).dispose();
            }
          }
        }
      }
    }
    // and what was recorded can be drawn
    for (final look in EclipseLook.values) {
      await _pixels(_button(look: look, since: .2, previous: EclipseLook.idle, down: 1, up: 1));
    }
  });

  test('the download lights the button in yellow, close to it', () async {
    final (r, _, b) = _round(await _pixels(_button(down: 1)), 8);
    expect(r, greaterThan(_background.r * 255 + 40));
    expect(r, greaterThan(b + 40));
  });

  test('the upload lights it in blue, further out', () async {
    final pixels = await _pixels(_button(up: 1));
    final (r, _, b) = _round(pixels, 30);
    expect(b, greaterThan(_background.b * 255 + 40));
    expect(b, greaterThan(r + 30));
    // a hollow ring: dimmer next to the button than further out
    expect(_round(pixels, 3).$3, lessThan(b));
  });

  test('the light reaches further with more traffic, and nothing shows without any', () async {
    final none = _round(await _pixels(_button()), 30);
    expect(none.$1, closeTo(_background.r * 255, 2));
    expect(none.$3, closeTo(_background.b * 255, 2));
    final low = _round(await _pixels(_button(down: .3)), 30).$1;
    final full = _round(await _pixels(_button(down: 1)), 30).$1;
    expect(low, closeTo(_background.r * 255, 3));
    expect(full, greaterThan(low + 10));
  });

  test('the same moment is the same picture: a light that stands still stays as it was', () async {
    final a = await _pixels(_button(down: .75, up: .5, time: 12.3, simple: true));
    final b = await _pixels(_button(down: .75, up: .5, time: 12.3, simple: true));
    expect(a.buffer.asUint8List(), b.buffer.asUint8List());
    expect(
      _button(
        down: .75,
        up: .5,
        time: 12.3,
        simple: true,
      ).shouldRepaint(_button(down: .75, up: .5, time: 12.3, simple: true)),
      isFalse,
    );
    // and it moves with its clock
    final later = await _pixels(_button(down: .75, up: .5, time: 13.3, simple: true));
    expect(later.buffer.asUint8List(), isNot(a.buffer.asUint8List()));
  });

  test('the button itself is white, with a shadow under it', () async {
    const page = Color(0xFFF4F5F7);
    final pixels = await _pixels(_button(look: EclipseLook.idle, dark: false), background: page);
    int red(double x, double y) => pixels.getUint8((y.round() * _box.toInt() + x.round()) * 4);
    // left of the logo, where the button is flat: nearer its edge the bevel shades it
    expect(red(_box / 2 - _radius * .6, _box / 2 - _radius * .3), 255);
    expect(red(_box / 2 - _radius * .95, _box / 2), lessThan(255));
    // the shadow falls below it: darker under the button than above it
    final below = red(_box / 2, _box / 2 + _radius + 5);
    final above = red(_box / 2, _box / 2 - _radius - 5);
    expect(below, lessThan(above - 4));
    expect(below, lessThan(page.r * 255 - 8));
  });
}
