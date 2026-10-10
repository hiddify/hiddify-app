import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/theme/cat/cat_theme_data.dart';
import 'package:hiddify/core/widget/cat/cat_bubble.dart';
import 'package:hiddify/core/widget/cat/cat_face.dart';
import 'package:hiddify/core/widget/cat/cat_gaze.dart';
import 'package:hiddify/core/widget/cat/cat_progress_bar.dart';
import 'package:hiddify/core/widget/cat/loafing_cat.dart';
import 'package:hiddify/core/widget/cat/paw_prints_background.dart';
import 'package:hiddify/core/widget/cat/paw_spinner.dart';
import 'package:hiddify/core/widget/cat/tappable_cat.dart';

Widget app(Widget child, {CatBreed breed = CatBreed.ginger}) => MaterialApp(
  theme: buildCatTheme(breed, fontFamily: ''),
  home: Scaffold(
    body: CatGazeRegion(child: Center(child: child)),
  ),
);

void main() {
  testWidgets('the cat goes through every mood, in every breed', (tester) async {
    final face = GlobalKey<CatFaceState>();
    for (final breed in CatBreed.values) {
      for (final mood in CatMood.values) {
        await tester.pumpWidget(
          app(
            CatFace(key: face, mood: mood, size: 120, aura: Colors.green, collar: Colors.green),
            breed: breed,
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
      }
    }
    face.currentState!
      ..boop()
      ..celebrate();
    await tester.pump(const Duration(seconds: 2));
    // an alive cat keeps breathing; taking it away must stop its ticker
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a cat at rest stops animating once its mood has changed', (tester) async {
    await tester.pumpWidget(app(const CatFace(mood: CatMood.napping, alive: false)));
    await tester.pumpWidget(app(const CatFace(mood: CatMood.purring, alive: false)));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('petting purrs until the finger lifts', (tester) async {
    int purrs = 0;
    await tester.pumpWidget(app(CatFace(mood: CatMood.purring, size: 120, pettable: true, onPurr: () => purrs++)));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(CatFace)));
    await tester.pump(const Duration(milliseconds: 600));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    final whilePetted = purrs;
    expect(whilePetted, greaterThan(1));
    await tester.pump(const Duration(seconds: 1));
    expect(purrs, whilePetted);
  });

  testWidgets('the eyes turn to the pointer across the gaze region, then settle', (tester) async {
    await tester.pumpWidget(app(const CatFace(mood: CatMood.purring, size: 120, alive: false, followPointer: true)));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);

    // far from the cat, but inside the region
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(5, 5));
    await mouse.moveTo(const Offset(10, 10));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'the eyes turn');
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'and stop once they look at it');
    await mouse.removePointer();
    await tester.pumpAndSettle();
  });

  testWidgets('tapping a cat says the meow in a bubble that goes away', (tester) async {
    await tester.pumpWidget(app(const TappableCat(mood: CatMood.purring, meow: 'Meow', size: 48)));
    await tester.tap(find.byType(TappableCat));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Meow'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Meow'), findsNothing);
  });

  testWidgets('a new bubble replaces the one still on screen', (tester) async {
    await tester.pumpWidget(app(Builder(builder: (context) => const SizedBox(width: 40, height: 40))));
    final context = tester.element(find.byType(SizedBox).last);
    CatBubble.show(context, 'Meow');
    await tester.pump(const Duration(milliseconds: 100));
    CatBubble.show(context, 'Meow');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Meow'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the loafing cat wakes up and meows when tapped', (tester) async {
    int wakes = 0;
    await tester.pumpWidget(app(LoafingCat(meow: 'Meow', onWake: () => wakes++)));
    await tester.tap(find.byType(LoafingCat));
    await tester.pump(const Duration(milliseconds: 200));
    expect(wakes, 1);
    expect(find.text('Meow'), findsOneWidget);
    // back asleep, it keeps still between swishes of its tail
    for (int i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('paw prints stamp under touches and fade away', (tester) async {
    await tester.pumpWidget(app(const PawPrintsBackground(child: SizedBox(width: 300, height: 300))));
    await tester.tapAt(tester.getCenter(find.byType(PawPrintsBackground)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the paw spinner and progress bar draw', (tester) async {
    await tester.pumpWidget(
      app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PawSpinner(),
            SizedBox(width: 200, child: CatProgressBar(value: .4)),
            SizedBox(width: 200, child: CatProgressBar(value: 0)),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    // the bar tells screen readers how far it got
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.value == '40%'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.value == '0%'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with animations off the cats keep still', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: app(
          const Column(
            children: [
              CatFace(mood: CatMood.napping),
              LoafingCat(),
              PawSpinner(),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
