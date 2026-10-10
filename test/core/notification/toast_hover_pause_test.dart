import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/notification/toast_hover_pause.dart';
import 'package:toastification/toastification.dart';

void main() {
  testWidgets('a toast closed under the pointer does not break mouse handling', (tester) async {
    await tester.pumpWidget(const ToastificationWrapper(child: MaterialApp(home: Scaffold())));
    late final ToastificationItem toast;
    toast = toastification.show(
      title: ToastHoverPause(item: () => toast, child: const Text('toast')),
      alignment: Alignment.center,
      autoCloseDuration: const Duration(seconds: 4),
      pauseOnHover: false,
    );
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('toast')));
    await tester.pump();
    expect(toast.timeStatus, ToastTimeStatus.paused, reason: 'hover pauses the timer');

    // Close it while no frames are drawn (window in the background): toastification disposes the
    // toast on a timer while its close animation, and so the toast itself, is still on screen.
    // With toastification's own pauseOnHover, leaving it now throws inside the mouse tracker and
    // every later mouse event fails with '!_debugDuringDeviceUpdate'.
    toastification.dismiss(toast);
    await tester.binding.delayed(const Duration(seconds: 2));
    expect(find.text('toast'), findsOneWidget);

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await mouse.moveTo(const Offset(10, 10));
    await tester.pump();
    await mouse.removePointer();
    // any error thrown or reported above fails the test
  });
}
