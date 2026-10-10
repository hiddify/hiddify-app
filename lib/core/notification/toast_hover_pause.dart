import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Pauses a toast's auto-close timer while the pointer is over [child].
///
/// Used instead of toastification's `pauseOnHover` (3.2.0): when a toast closes under the pointer
/// (e.g. `dismissAll` for a newer toast) its MouseRegion still calls into the disposed timer from
/// `onExit`. That exception is thrown inside the mouse tracker and leaves it broken for the rest
/// of the session: every mouse event then fails with `!_debugDuringDeviceUpdate`.
class ToastHoverPause extends StatelessWidget {
  const ToastHoverPause({super.key, required this.item, required this.child});

  /// The toast; read lazily because the toast is created after its content.
  final ToastificationItem Function() item;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(onEnter: (_) => _alive()?.pause(), onExit: (_) => _alive()?.start(), child: child);
  }

  // toastification forgets a toast before disposing it, so a closed toast is not found
  ToastificationItem? _alive() {
    final toast = item();
    return toastification.findToastificationItem(toast.id) == null ? null : toast;
  }
}
