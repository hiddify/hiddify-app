import 'dart:async';

class LastStream<T> {
  final Stream<T> _source;
  T? _latest;
  bool _hasValue = false;
  late final StreamSubscription<T> _sub;
  final List<(bool Function(T value), Completer<T>)> _waiters = [];

  LastStream(Stream<T> source) : _source = source {
    _sub = _source.listen((event) {
      _latest = event;
      _hasValue = true;
      // Complete the waiters this value satisfies; the rest keep waiting.
      _waiters.removeWhere((waiter) {
        final (where, completer) = waiter;
        if (!where(event)) return false;
        if (!completer.isCompleted) completer.complete(event);
        return true;
      });
    });
  }

  void clean() {
    _latest = null;
    _hasValue = false;
  }

  /// Returns the latest value if available and accepted by [where],
  /// otherwise waits up to [timeout] for the next one it accepts.
  Future<T> get({Duration? timeout, bool Function(T value)? where}) async {
    final accepts = where ?? (_) => true;
    if (_hasValue && accepts(_latest as T)) return _latest as T;

    final completer = Completer<T>();
    final waiter = (accepts, completer);
    _waiters.add(waiter);

    if (timeout != null) {
      return completer.future.timeout(
        timeout,
        onTimeout: () {
          _waiters.remove(waiter);
          throw TimeoutException('No value received in $timeout');
        },
      );
    }

    return completer.future;
  }

  /// Dispose the listener and clear resources.
  Future<void> close() async {
    await _sub.cancel();
    for (final (_, c) in _waiters) {
      if (!c.isCompleted) {
        c.completeError(StateError('Stream closed'));
      }
    }
    _waiters.clear();
  }
}
