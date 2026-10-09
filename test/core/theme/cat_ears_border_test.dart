import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/cat/cat_ears_border.dart';
import 'package:hiddify/core/theme/cat/cat_peek_border.dart';
import 'package:hiddify/core/theme/cat/cat_theme_data.dart';

void main() {
  const rect = Rect.fromLTWH(0, 20, 120, 40);

  group('CatEarsBorder', () {
    test('the ears stand above the top edge, near the corners, not in the middle', () {
      final path = const CatEarsBorder(earHeight: 8).getOuterPath(rect);
      expect(path.getBounds().top, lessThan(rect.top - 6));
      expect(path.contains(Offset(24, rect.top - 2)), isTrue, reason: 'left ear');
      expect(path.contains(Offset(rect.right - 24, rect.top - 2)), isTrue, reason: 'right ear');
      expect(path.contains(Offset(rect.center.dx, rect.top - 2)), isFalse, reason: 'between the ears');
      expect(path.contains(rect.center), isTrue, reason: 'the body');
    });

    test('a rect too small for ears keeps its plain shape', () {
      const tiny = Rect.fromLTWH(0, 0, 10, 10);
      expect(const CatEarsBorder(earHeight: 8).getOuterPath(tiny).getBounds(), tiny);
    });

    test('a plain rounded shape grows its ears from nothing', () {
      const eared = CatEarsBorder(earHeight: 8, borderRadius: BorderRadius.all(Radius.circular(12)));
      const plain = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)));
      final start = eared.lerpFrom(plain, 0)! as CatEarsBorder;
      final middle = eared.lerpFrom(plain, .5)! as CatEarsBorder;
      expect(start.earHeight, 0);
      expect(middle.earHeight, 4);
      expect(eared.lerpFrom(plain, 1), eared);
    });

    test('copyWith keeps the ears and changes the side', () {
      const side = BorderSide(color: Colors.red);
      final copy = const CatEarsBorder(earHeight: 8, earTilt: .3).copyWith(side: side);
      expect(copy.side, side);
      expect(copy.earTilt, .3);
      expect(copy, isNot(const CatEarsBorder(earHeight: 8, earTilt: .3)));
    });

    test('buttons perk their ears up when pressed and droop them when disabled', () {
      final ears = catEarsForButtons(Colors.pink);
      final idle = ears.resolve({})! as CatEarsBorder;
      final pressed = ears.resolve({WidgetState.pressed})! as CatEarsBorder;
      final disabled = ears.resolve({WidgetState.disabled})! as CatEarsBorder;
      expect(pressed.earHeight, greaterThan(idle.earHeight));
      expect(disabled.earHeight, lessThan(idle.earHeight));
      expect(disabled.earTilt, greaterThan(idle.earTilt));
    });
  });

  group('CatPeekBorder', () {
    const peek = CatPeekBorder(
      lineColor: Colors.grey,
      innerEarColor: Colors.pink,
      irisColor: Colors.green,
      pupilColor: Colors.black,
      blushColor: Colors.pink,
    );
    const dialog = Rect.fromLTWH(0, 100, 320, 200);

    test('the cat peeks over the top edge, toward the end of the line', () {
      final ltr = peek.getOuterPath(dialog, textDirection: TextDirection.ltr).getBounds();
      expect(ltr.top, lessThan(dialog.top - 30));
      final head = peek.getOuterPath(dialog, textDirection: TextDirection.ltr);
      final mirrored = peek.getOuterPath(dialog, textDirection: TextDirection.rtl);
      expect(head.contains(Offset(dialog.width * .8, dialog.top - 10)), isTrue);
      expect(mirrored.contains(Offset(dialog.width * .2, dialog.top - 10)), isTrue);
    });

    test('a hidden cat leaves a plain rounded rect', () {
      expect(peek.copyWith(peek: 0).getOuterPath(dialog).getBounds(), dialog);
    });
  });
}
