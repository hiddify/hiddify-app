import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Tracks the pointer over [child] so the cats inside can follow it with their
/// eyes: the mouse while it hovers, a finger while it touches the screen.
///
/// It only listens: taps and drags reach [child] as before.
class CatGazeRegion extends StatefulWidget {
  const CatGazeRegion({super.key, required this.child});

  final Widget child;

  @override
  State<CatGazeRegion> createState() => _CatGazeRegionState();
}

class _CatGazeRegionState extends State<CatGazeRegion> {
  final ValueNotifier<Offset?> _pointer = ValueNotifier(null);
  Timer? _forget;

  void _look(PointerEvent event) {
    _forget?.cancel();
    _pointer.value = event.position;
  }

  /// A lifted finger leaves the cat staring at the spot for a moment.
  void _lift(PointerEvent event) {
    if (event.kind == PointerDeviceKind.mouse) return;
    _forget?.cancel();
    _forget = Timer(const Duration(milliseconds: 1500), () => _pointer.value = null);
  }

  @override
  void dispose() {
    _forget?.cancel();
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: _look,
      onPointerDown: _look,
      onPointerMove: _look,
      onPointerUp: _lift,
      onPointerCancel: _lift,
      child: MouseRegion(
        onExit: (_) => _pointer.value = null,
        child: CatGaze(pointer: _pointer, child: widget.child),
      ),
    );
  }
}

/// Where the pointer is, in global coordinates, or null when it's gone.
class CatGaze extends InheritedWidget {
  const CatGaze({super.key, required this.pointer, required super.child});

  final ValueListenable<Offset?> pointer;

  /// The pointer of the closest [CatGazeRegion]. Doesn't rebuild the caller
  /// when the pointer moves: listen to it instead.
  static ValueListenable<Offset?>? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<CatGaze>()?.pointer;

  @override
  bool updateShouldNotify(CatGaze oldWidget) => pointer != oldWidget.pointer;
}
