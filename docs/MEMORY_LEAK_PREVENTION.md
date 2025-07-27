# Memory Leak Prevention Guide

This document outlines the memory leak prevention measures implemented in the Hiddify project.

## Overview

Memory leaks can occur when resources are not properly disposed of, leading to increased memory usage over time. This guide provides best practices and tools to prevent memory leaks in the application.

## Common Memory Leak Sources

### 1. Timers
```dart
// ❌ Bad - Timer not disposed
Timer? _timer;
_timer = Timer(Duration(seconds: 5), () {
  // callback
});

// ✅ Good - Timer properly disposed
Timer? _timer;
_timer = Timer(Duration(seconds: 5), () {
  // callback
});

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```

### 2. Stream Subscriptions
```dart
// ❌ Bad - Subscription not disposed
StreamSubscription? _subscription;
_subscription = stream.listen((data) {
  // handle data
});

// ✅ Good - Subscription properly disposed
StreamSubscription? _subscription;
_subscription = stream.listen((data) {
  // handle data
});

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

### 3. Controllers
```dart
// ❌ Bad - Controllers not disposed
final _textController = TextEditingController();
final _scrollController = ScrollController();

// ✅ Good - Controllers properly disposed
final _textController = TextEditingController();
final _scrollController = ScrollController();

@override
void dispose() {
  _textController.dispose();
  _scrollController.dispose();
  super.dispose();
}
```

### 4. Focus Nodes
```dart
// ❌ Bad - FocusNode not disposed
final _focusNode = FocusNode();

// ✅ Good - FocusNode properly disposed
final _focusNode = FocusNode();

@override
void dispose() {
  _focusNode.dispose();
  super.dispose();
}
```

## Memory Leak Prevention Tools

### 1. MemoryLeakPrevention Utility

The `MemoryLeakPrevention` utility class provides safe disposal methods:

```dart
import 'package:hiddify/utils/memory_leak_prevention.dart';

// Safe disposal methods
MemoryLeakPrevention.safeDisposeTimer(timer);
MemoryLeakPrevention.safeDisposeSubscription(subscription);
MemoryLeakPrevention.safeDisposeTextController(controller);
MemoryLeakPrevention.safeDisposeScrollController(controller);
MemoryLeakPrevention.safeDisposeFocusNode(focusNode);
```

### 2. MemoryLeakPreventionMixin

Use the mixin in StatefulWidgets for automatic resource disposal:

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with MemoryLeakPreventionMixin {
  late Timer _timer;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    
    _timer = Timer(Duration(seconds: 5), () {});
    _controller = TextEditingController();
    
    // Add to automatic disposal
    addDisposableTimer(_timer);
    addDisposableTextController(_controller);
  }
  
  // No need to override dispose() - mixin handles it
}
```

### 3. Memory Leak Detection Service

The service automatically monitors for potential memory leaks:

```dart
// Start monitoring (automatically done in debug mode)
MemoryLeakDetectionService().startMonitoring();

// Get memory statistics
final stats = MemoryLeakDetectionService().getMemoryStats();

// Print detailed report
MemoryLeakDetectionService().printDetailedReport();
```

## Best Practices

### 1. Always Dispose Resources

- **Timers**: Always call `cancel()` before disposal
- **Stream Subscriptions**: Always call `cancel()` before disposal
- **Controllers**: Always call `dispose()` before disposal
- **Focus Nodes**: Always call `dispose()` before disposal

### 2. Use the Mixin for StatefulWidgets

Instead of manually managing disposal, use the `MemoryLeakPreventionMixin`:

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with MemoryLeakPreventionMixin {
  @override
  void initState() {
    super.initState();
    
    // Add resources for automatic disposal
    addDisposableTimer(Timer(Duration(seconds: 5), () {}));
    addDisposableTextController(TextEditingController());
  }
}
```

### 3. Check for Memory Leaks in Debug Mode

The memory leak detection service automatically runs in debug mode and will log warnings for undisposed resources.

### 4. Use Safe Disposal Methods

When manually disposing resources, use the safe disposal methods:

```dart
@override
void dispose() {
  MemoryLeakPrevention.safeDisposeTimer(_timer);
  MemoryLeakPrevention.safeDisposeSubscription(_subscription);
  MemoryLeakPrevention.safeDisposeTextController(_controller);
  super.dispose();
}
```

## Debugging Memory Leaks

### 1. Enable Memory Leak Tracking

```dart
// Enable tracking (enabled by default in debug mode)
MemoryLeakPrevention.setTrackingEnabled(true);
```

### 2. Check for Undisposed Resources

```dart
// Get all tracked resources
final trackedResources = MemoryLeakPrevention.getTrackedResources();

// Print memory leak report
MemoryLeakPrevention.printMemoryLeakReport();
```

### 3. Monitor Memory Usage

```dart
// Get memory statistics
final stats = MemoryLeakDetectionService().getMemoryStats();
print('Memory stats: $stats');
```

## Common Patterns

### 1. Riverpod Providers

For Riverpod providers, use `ref.onDispose()`:

```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  Timer? _timer;
  
  @override
  void build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    _timer = Timer(Duration(seconds: 5), () {});
    return initialState;
  }
}
```

### 2. Async Operations

For async operations, always cancel them when the widget is disposed:

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with MemoryLeakPreventionMixin {
  CancelToken? _cancelToken;
  
  Future<void> _loadData() async {
    _cancelToken = CancelToken();
    try {
      await apiCall(cancelToken: _cancelToken);
    } catch (e) {
      if (e is DioError && e.type == DioErrorType.cancel) {
        // Request was cancelled
        return;
      }
      rethrow;
    }
  }
  
  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }
}
```

## Testing Memory Leaks

### 1. Manual Testing

1. Navigate to different screens multiple times
2. Check memory usage in debug console
3. Look for memory leak warnings in logs

### 2. Automated Testing

```dart
testWidgets('should not leak memory', (WidgetTester tester) async {
  // Build widget
  await tester.pumpWidget(MyWidget());
  
  // Navigate away
  await tester.pumpWidget(Container());
  
  // Check for undisposed resources
  final trackedResources = MemoryLeakPrevention.getTrackedResources();
  expect(trackedResources.values.every((list) => list.isEmpty), isTrue);
});
```

## Monitoring in Production

While memory leak detection is primarily for development, you can enable it in production for monitoring:

```dart
// Enable in production (use with caution)
if (kReleaseMode) {
  MemoryLeakDetectionService().startMonitoring(
    checkInterval: Duration(minutes: 30), // Less frequent checks
  );
}
```

## Conclusion

By following these guidelines and using the provided tools, you can significantly reduce the risk of memory leaks in the application. Always remember to:

1. Dispose of all resources properly
2. Use the `MemoryLeakPreventionMixin` for StatefulWidgets
3. Monitor for memory leaks in debug mode
4. Test thoroughly for memory leaks before releasing