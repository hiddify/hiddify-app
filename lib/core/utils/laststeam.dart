import 'dart:async';

class LastStream<T> {
  final Stream<T> _source;
  T? _latest;
  bool _hasValue = false;
  late final StreamSubscription<T> _sub;
  final List<Completer<T>> _waiters = [];

  LastStream(Stream<T> source) : _source = source {
    _sub = _source.listen((event) {
      _latest = event;
      _hasValue = true;
      // Complete all waiting futures
      for (final completer in _waiters) {
        if (!completer.isCompleted) completer.complete(event);
      }
      _waiters.clear();
    });
  }

  void clean() {
    _latest = null;
    _hasValue = false;
  }

  /// Returns the latest value if available,
  /// otherwise waits up to [timeout] for one.
  Future<T> get({Duration? timeout}) async {
    if (_hasValue) return _latest as T;

    final completer = Completer<T>();
    _waiters.add(completer);

    if (timeout != null) {
      return completer.future.timeout(
        timeout,
        onTimeout: () {
          _waiters.remove(completer);
          throw TimeoutException('No value received in $timeout');
        },
      );
    }

    return completer.future;
  }

  /// Dispose the listener and clear resources.
  Future<void> close() async {
    await _sub.cancel();
    for (final c in _waiters) {
      if (!c.isCompleted) {
        c.completeError(StateError('Stream closed'));
      }
    }
    _waiters.clear();
  }
}
