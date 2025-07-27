import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Utility class to help prevent memory leaks
class MemoryLeakPrevention {
  static final Map<String, List<dynamic>> _trackedResources = {};
  static bool _isTrackingEnabled = kDebugMode;

  /// Enable or disable memory leak tracking
  static void setTrackingEnabled(bool enabled) {
    _isTrackingEnabled = enabled;
  }

  /// Track a resource for potential memory leak detection
  static void trackResource(String category, dynamic resource) {
    if (!_isTrackingEnabled) return;
    
    _trackedResources.putIfAbsent(category, () => []).add(resource);
    developer.log('Tracking resource: $category - ${resource.runtimeType}', name: 'MemoryLeakPrevention');
  }

  /// Untrack a resource when it's properly disposed
  static void untrackResource(String category, dynamic resource) {
    if (!_isTrackingEnabled) return;
    
    _trackedResources[category]?.remove(resource);
    developer.log('Untracked resource: $category - ${resource.runtimeType}', name: 'MemoryLeakPrevention');
  }

  /// Get tracked resources for debugging
  static Map<String, List<dynamic>> getTrackedResources() {
    return Map.unmodifiable(_trackedResources);
  }

  /// Clear all tracked resources
  static void clearTrackedResources() {
    _trackedResources.clear();
  }

  /// Safe disposal of Timer
  static void safeDisposeTimer(Timer? timer) {
    if (timer != null && timer.isActive) {
      timer.cancel();
      developer.log('Timer disposed', name: 'MemoryLeakPrevention');
    }
  }

  /// Safe disposal of StreamSubscription
  static void safeDisposeSubscription(StreamSubscription? subscription) {
    if (subscription != null) {
      subscription.cancel();
      developer.log('StreamSubscription disposed', name: 'MemoryLeakPrevention');
    }
  }

  /// Safe disposal of TextEditingController
  static void safeDisposeTextController(TextEditingController? controller) {
    if (controller != null) {
      controller.dispose();
      developer.log('TextEditingController disposed', name: 'MemoryLeakPrevention');
    }
  }

  /// Safe disposal of ScrollController
  static void safeDisposeScrollController(ScrollController? controller) {
    if (controller != null) {
      controller.dispose();
      developer.log('ScrollController disposed', name: 'MemoryLeakPrevention');
    }
  }

  /// Safe disposal of FocusNode
  static void safeDisposeFocusNode(FocusNode? focusNode) {
    if (focusNode != null) {
      focusNode.dispose();
      developer.log('FocusNode disposed', name: 'MemoryLeakPrevention');
    }
  }

  /// Safe disposal of AnimationController
  static void safeDisposeAnimationController(AnimationController? controller) {
    if (controller != null) {
      controller.dispose();
      developer.log('AnimationController disposed', name: 'MemoryLeakPrevention');
    }
  }

  /// Safe disposal of StreamController
  static Future<void> safeDisposeStreamController(StreamController? controller) async {
    if (controller != null && !controller.isClosed) {
      await controller.close();
      developer.log('StreamController disposed', name: 'MemoryLeakPrevention');
    }
  }

  /// Print memory leak report
  static void printMemoryLeakReport() {
    if (!_isTrackingEnabled) return;
    
    developer.log('=== Memory Leak Report ===', name: 'MemoryLeakPrevention');
    _trackedResources.forEach((category, resources) {
      if (resources.isNotEmpty) {
        developer.log('$category: ${resources.length} resources not disposed', name: 'MemoryLeakPrevention');
        for (final resource in resources) {
          developer.log('  - ${resource.runtimeType}', name: 'MemoryLeakPrevention');
        }
      }
    });
    developer.log('========================', name: 'MemoryLeakPrevention');
  }
}

/// Mixin to help with memory leak prevention in StatefulWidgets
mixin MemoryLeakPreventionMixin<T extends StatefulWidget> on State<T> {
  final List<dynamic> _resourcesToDispose = [];

  /// Add a resource to be disposed when the widget is disposed
  void addDisposable(dynamic resource) {
    _resourcesToDispose.add(resource);
  }

  /// Add a Timer to be disposed
  void addDisposableTimer(Timer timer) {
    addDisposable(timer);
    MemoryLeakPrevention.trackResource('Timer', timer);
  }

  /// Add a StreamSubscription to be disposed
  void addDisposableSubscription(StreamSubscription subscription) {
    addDisposable(subscription);
    MemoryLeakPrevention.trackResource('StreamSubscription', subscription);
  }

  /// Add a TextEditingController to be disposed
  void addDisposableTextController(TextEditingController controller) {
    addDisposable(controller);
    MemoryLeakPrevention.trackResource('TextEditingController', controller);
  }

  /// Add a ScrollController to be disposed
  void addDisposableScrollController(ScrollController controller) {
    addDisposable(controller);
    MemoryLeakPrevention.trackResource('ScrollController', controller);
  }

  /// Add a FocusNode to be disposed
  void addDisposableFocusNode(FocusNode focusNode) {
    addDisposable(focusNode);
    MemoryLeakPrevention.trackResource('FocusNode', focusNode);
  }

  @override
  void dispose() {
    for (final resource in _resourcesToDispose) {
      if (resource is Timer) {
        MemoryLeakPrevention.safeDisposeTimer(resource);
        MemoryLeakPrevention.untrackResource('Timer', resource);
      } else if (resource is StreamSubscription) {
        MemoryLeakPrevention.safeDisposeSubscription(resource);
        MemoryLeakPrevention.untrackResource('StreamSubscription', resource);
      } else if (resource is TextEditingController) {
        MemoryLeakPrevention.safeDisposeTextController(resource);
        MemoryLeakPrevention.untrackResource('TextEditingController', resource);
      } else if (resource is ScrollController) {
        MemoryLeakPrevention.safeDisposeScrollController(resource);
        MemoryLeakPrevention.untrackResource('ScrollController', resource);
      } else if (resource is FocusNode) {
        MemoryLeakPrevention.safeDisposeFocusNode(resource);
        MemoryLeakPrevention.untrackResource('FocusNode', resource);
      } else if (resource is AnimationController) {
        MemoryLeakPrevention.safeDisposeAnimationController(resource);
        MemoryLeakPrevention.untrackResource('AnimationController', resource);
      } else if (resource is StreamController) {
        MemoryLeakPrevention.safeDisposeStreamController(resource);
        MemoryLeakPrevention.untrackResource('StreamController', resource);
      } else {
        // Try to call dispose() if the resource has it
        try {
          if (resource is dynamic && resource.dispose is Function) {
            resource.dispose();
          }
        } catch (e) {
          developer.log('Error disposing resource: $e', name: 'MemoryLeakPrevention');
        }
      }
    }
    _resourcesToDispose.clear();
    super.dispose();
  }
}