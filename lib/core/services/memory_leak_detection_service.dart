import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:hiddify/utils/memory_leak_prevention.dart';

/// Service to detect and report memory leaks
class MemoryLeakDetectionService {
  static final MemoryLeakDetectionService _instance = MemoryLeakDetectionService._internal();
  factory MemoryLeakDetectionService() => _instance;
  MemoryLeakDetectionService._internal();

  Timer? _periodicCheckTimer;
  bool _isMonitoring = false;

  /// Start memory leak monitoring
  void startMonitoring({Duration checkInterval = const Duration(minutes: 5)}) {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _periodicCheckTimer = Timer.periodic(checkInterval, (timer) {
      _checkForMemoryLeaks();
    });
    
    developer.log('Memory leak monitoring started', name: 'MemoryLeakDetection');
  }

  /// Stop memory leak monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
    
    developer.log('Memory leak monitoring stopped', name: 'MemoryLeakDetection');
  }

  /// Check for potential memory leaks
  void _checkForMemoryLeaks() {
    if (!kDebugMode) return;
    
    final trackedResources = MemoryLeakPrevention.getTrackedResources();
    bool hasLeaks = false;
    
    trackedResources.forEach((category, resources) {
      if (resources.isNotEmpty) {
        hasLeaks = true;
        developer.log(
          'Potential memory leak detected: $category has ${resources.length} undisposed resources',
          name: 'MemoryLeakDetection',
          level: 900, // Warning level
        );
        
        for (final resource in resources) {
          developer.log(
            '  - ${resource.runtimeType}',
            name: 'MemoryLeakDetection',
            level: 900,
          );
        }
      }
    });
    
    if (hasLeaks) {
      _reportMemoryLeak();
    }
  }

  /// Report memory leak to analytics or logging service
  void _reportMemoryLeak() {
    // In a production app, you might want to send this to a monitoring service
    // like Sentry, Firebase Crashlytics, or your own analytics
    developer.log(
      'Memory leak detected - consider investigating undisposed resources',
      name: 'MemoryLeakDetection',
      level: 1000, // Error level
    );
  }

  /// Get current memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    final trackedResources = MemoryLeakPrevention.getTrackedResources();
    final stats = <String, dynamic>{};
    
    trackedResources.forEach((category, resources) {
      stats[category] = {
        'count': resources.length,
        'types': resources.map((r) => r.runtimeType.toString()).toSet().toList(),
      };
    });
    
    return stats;
  }

  /// Force garbage collection (for testing purposes)
  void forceGarbageCollection() {
    // This is a placeholder - in a real implementation, you might use
    // platform-specific methods to suggest garbage collection
    developer.log('Garbage collection requested', name: 'MemoryLeakDetection');
  }

  /// Print detailed memory leak report
  void printDetailedReport() {
    MemoryLeakPrevention.printMemoryLeakReport();
  }
}

/// Extension to easily access the memory leak detection service
extension MemoryLeakDetectionExtension on Object {
  MemoryLeakDetectionService get memoryLeakDetection => MemoryLeakDetectionService();
}