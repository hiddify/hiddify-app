// Lightweight utilities to help track and dispose resources in Widgets.
//
// This provides a no-op static tracker and a mixin to collect disposables
// such as controllers and timers, so they can be cleaned up on dispose.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Simple debug-only tracker to aid diagnosing leaks during development.
class MemoryLeakPrevention {
  /// Track a resource by type and instance for debugging purposes.
  static void trackResource(String type, Object resource) {
    if (kDebugMode) {
      // Keep this lightweight to avoid any runtime impact in release.
      debugPrint('[MemoryLeakPrevention] Tracking $type: ${resource.hashCode}');
    }
  }
}

/// Mixin to register disposables and clean them up when the State is disposed.
///
/// Note: Call [disposeMemoryLeakPrevention] inside your State.dispose() if you
/// override dispose in your class.
mixin MemoryLeakPreventionMixin<T extends StatefulWidget> on State<T> {
  final List<VoidCallback> _disposers = <VoidCallback>[];

  /// Register an arbitrary disposer callback.
  @protected
  void addDisposer(VoidCallback disposer) => _disposers.add(disposer);

  /// Register a TextEditingController for disposal.
  @protected
  void addDisposableTextController(TextEditingController controller) {
    _disposers.add(controller.dispose);
  }

  /// Register a ScrollController for disposal.
  @protected
  void addDisposableScrollController(ScrollController controller) {
    _disposers.add(controller.dispose);
  }

  /// Register a FocusNode for disposal.
  @protected
  void addDisposableFocusNode(FocusNode focusNode) {
    _disposers.add(focusNode.dispose);
  }

  /// Register a Timer for cancellation.
  @protected
  void addDisposableTimer(Timer timer) {
    _disposers.add(() {
      if (timer.isActive) timer.cancel();
    });
  }

  /// Performs cleanup of all registered disposers.
  @protected
  @mustCallSuper
  void disposeMemoryLeakPrevention() {
    // Execute a copy in case disposers add more disposers during cleanup.
    final disposers = List<VoidCallback>.from(_disposers);
    _disposers.clear();
    for (final d in disposers) {
      try {
        d();
      } catch (_) {
        // Ignore individual disposer errors to avoid masking the real dispose.
      }
    }
  }
}
