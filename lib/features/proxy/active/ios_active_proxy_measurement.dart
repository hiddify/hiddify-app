import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:rxdart/rxdart.dart';

enum IosProxyMeasurementPhase { idle, checking, available, unavailable, failed, timedOut }

enum IosProxyMeasurementCode { requestFailed, streamFailed, timedOut, cancelled }

class IosProxyMeasurementException implements Exception {
  const IosProxyMeasurementException(this.code);

  final IosProxyMeasurementCode code;

  @override
  String toString() => 'IosProxyMeasurementException(${code.name})';
}

class IosProxyMeasurementState {
  const IosProxyMeasurementState(this.phase, {this.proxy});

  final IosProxyMeasurementPhase phase;
  final OutboundInfo? proxy;
}

class IosActiveProxyMeasurement {
  IosActiveProxyMeasurement({
    required Stream<Either<ProxyFailure, List<OutboundGroup>>> Function() watch,
    required Future<void> Function() request,
    this.deadline = const Duration(seconds: 15),
    DateTime Function()? now,
    bool Function()? canRefresh,
  }) : _watch = watch,
       _request = request,
       _now = now ?? DateTime.now,
       _canRefresh = canRefresh;

  final Stream<Either<ProxyFailure, List<OutboundGroup>>> Function() _watch;
  final Future<void> Function() _request;
  final Duration deadline;
  final DateTime Function() _now;
  final bool Function()? _canRefresh;

  final BehaviorSubject<IosProxyMeasurementState> _states = BehaviorSubject.seeded(
    const IosProxyMeasurementState(IosProxyMeasurementPhase.idle),
  );

  StreamSubscription<Either<ProxyFailure, List<OutboundGroup>>>? _subscription;
  Timer? _timer;
  Future<void>? _inFlight;
  Completer<void>? _completion;
  OutboundInfo? _baseline;
  OutboundInfo? _candidate;
  OutboundInfo? _attemptIdentity;
  DateTime? _requestStartedAt;
  var _requestIssued = false;
  var _requestCompleted = false;
  var _epoch = 0;
  var _disposed = false;

  IosProxyMeasurementState get state => _states.value;

  Stream<IosProxyMeasurementState> get states => _states.stream;

  bool get canRefresh => !_disposed && (_canRefresh?.call() ?? true);

  Future<void> refresh() {
    if (!canRefresh) {
      return Future<void>.error(const IosProxyMeasurementException(IosProxyMeasurementCode.cancelled));
    }
    final current = _inFlight;
    if (current != null) return current;

    _cancelResources();
    final epoch = ++_epoch;
    final completion = Completer<void>();
    _completion = completion;
    _inFlight = completion.future;
    _baseline = null;
    _candidate = null;
    _attemptIdentity = null;
    _requestStartedAt = null;
    _requestIssued = false;
    _requestCompleted = false;
    _emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.checking));

    try {
      _subscription = _watch().listen(
        (event) => _onEvent(epoch, event),
        onError: (Object _, StackTrace _) => _onStreamError(epoch),
      );
    } catch (_) {
      _failAttempt(
        epoch,
        const IosProxyMeasurementException(IosProxyMeasurementCode.streamFailed),
        IosProxyMeasurementPhase.failed,
      );
      return completion.future;
    }
    _timer = Timer(
      deadline,
      () => _failAttempt(
        epoch,
        const IosProxyMeasurementException(IosProxyMeasurementCode.timedOut),
        IosProxyMeasurementPhase.timedOut,
      ),
    );

    scheduleMicrotask(() => _issueRequest(epoch));
    return completion.future;
  }

  void stop() {
    if (_disposed) return;
    _cancel(const IosProxyMeasurementException(IosProxyMeasurementCode.cancelled));
  }

  void dispose() {
    if (_disposed) return;
    final cancellation = _subscription?.cancel();
    _subscription = null;
    _cancel(const IosProxyMeasurementException(IosProxyMeasurementCode.cancelled));
    _disposed = true;
    if (cancellation != null) {
      unawaited(_ignoreCancellationError(cancellation));
    }
    unawaited(_states.close());
  }

  Future<void> _issueRequest(int epoch) async {
    if (!_isCurrent(epoch)) return;
    _requestIssued = true;
    _requestStartedAt = _now();
    try {
      await _request();
    } catch (_) {
      _failAttempt(
        epoch,
        const IosProxyMeasurementException(IosProxyMeasurementCode.requestFailed),
        IosProxyMeasurementPhase.failed,
      );
      return;
    }
    if (!_isCurrent(epoch)) return;
    _requestCompleted = true;
    _tryComplete(epoch);
  }

  void _onEvent(int epoch, Either<ProxyFailure, List<OutboundGroup>> event) {
    if (!_isEpochCurrent(epoch)) return;
    event.match(
      (_) {
        if (_isCurrent(epoch)) {
          _failAttempt(
            epoch,
            const IosProxyMeasurementException(IosProxyMeasurementCode.streamFailed),
            IosProxyMeasurementPhase.unavailable,
          );
        } else if (state.phase == IosProxyMeasurementPhase.available) {
          _invalidatePassive(epoch, IosProxyMeasurementPhase.unavailable);
        }
      },
      (groups) {
        final proxy = _activeProxy(groups);
        if (proxy == null) {
          if (state.phase == IosProxyMeasurementPhase.available) {
            _invalidatePassive(epoch, IosProxyMeasurementPhase.unavailable);
          }
          return;
        }
        if (!_requestIssued) {
          _baseline = proxy;
          _attemptIdentity = proxy;
          return;
        }
        if (state.phase == IosProxyMeasurementPhase.available) {
          _updateAvailable(epoch, proxy);
          return;
        }
        final identity = _attemptIdentity;
        if (identity == null) {
          _attemptIdentity = proxy;
        } else if (!_sameIdentity(identity, proxy)) {
          _completeUnavailable(epoch);
          return;
        }
        if (!_isFresh(proxy)) return;
        _candidate = proxy;
        _tryComplete(epoch);
      },
    );
  }

  void _onStreamError(int epoch) {
    if (!_isEpochCurrent(epoch)) return;
    if (_isCurrent(epoch)) {
      _failAttempt(
        epoch,
        const IosProxyMeasurementException(IosProxyMeasurementCode.streamFailed),
        IosProxyMeasurementPhase.failed,
      );
    } else if (state.phase == IosProxyMeasurementPhase.available) {
      _invalidatePassive(epoch, IosProxyMeasurementPhase.failed);
    }
  }

  void _updateAvailable(int epoch, OutboundInfo proxy) {
    final current = state.proxy;
    if (current == null) return;
    if (!_sameIdentity(current, proxy)) {
      _invalidatePassive(epoch, IosProxyMeasurementPhase.unavailable);
      return;
    }
    if (!proxy.hasUrlTestTime() || !current.hasUrlTestTime()) return;
    final measuredAt = proxy.urlTestTime.toDateTime().toUtc();
    final currentMeasuredAt = current.urlTestTime.toDateTime().toUtc();
    if (measuredAt.isBefore(currentMeasuredAt)) return;
    if (measuredAt.isAtSameMomentAs(currentMeasuredAt)) {
      final enriched = OutboundInfo()..mergeFromMessage(proxy);
      enriched
        ..urlTestDelay = current.urlTestDelay
        ..urlTestTime = current.urlTestTime;
      _emit(IosProxyMeasurementState(IosProxyMeasurementPhase.available, proxy: enriched));
      return;
    }
    if (proxy.urlTestDelay <= 0) return;
    if (proxy.urlTestDelay > 65000) {
      _invalidatePassive(epoch, IosProxyMeasurementPhase.unavailable);
      return;
    }
    _emit(IosProxyMeasurementState(IosProxyMeasurementPhase.available, proxy: proxy));
  }

  bool _sameIdentity(OutboundInfo first, OutboundInfo second) {
    return first.tag == second.tag && first.groupSelectedTag == second.groupSelectedTag;
  }

  OutboundInfo? _activeProxy(List<OutboundGroup> groups) {
    if (groups.isEmpty || groups.first.items.isEmpty) return null;
    final proxy = groups.first.items.first;
    if (proxy.tag.isEmpty) return null;
    return proxy;
  }

  bool _isFresh(OutboundInfo proxy) {
    final startedAt = _requestStartedAt;
    if (startedAt == null || !proxy.hasUrlTestTime()) return false;
    final measuredAt = proxy.urlTestTime.toDateTime().toUtc();
    if (measuredAt.isBefore(startedAt.toUtc())) return false;
    final baseline = _baseline;
    if (baseline != null && _sameIdentity(baseline, proxy) && baseline.hasUrlTestTime()) {
      if (!measuredAt.isAfter(baseline.urlTestTime.toDateTime().toUtc())) return false;
    }
    return proxy.urlTestDelay > 0;
  }

  void _tryComplete(int epoch) {
    if (!_isCurrent(epoch) || !_requestCompleted) return;
    final proxy = _candidate;
    if (proxy == null) return;
    if (proxy.urlTestDelay > 65000) {
      _completeUnavailable(epoch);
      return;
    }
    _timer?.cancel();
    _timer = null;
    _emit(IosProxyMeasurementState(IosProxyMeasurementPhase.available, proxy: proxy));
    _complete(epoch);
  }

  void _completeUnavailable(int epoch) {
    if (!_isCurrent(epoch)) return;
    _emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.unavailable));
    _complete(epoch, cancelSubscription: true);
  }

  void _failAttempt(int epoch, IosProxyMeasurementException error, IosProxyMeasurementPhase phase) {
    if (!_isCurrent(epoch)) return;
    _emit(IosProxyMeasurementState(phase));
    _timer?.cancel();
    _timer = null;
    final completion = _completion;
    _completion = null;
    _inFlight = null;
    _cancelSubscription();
    if (completion != null && !completion.isCompleted) completion.completeError(error);
  }

  void _complete(int epoch, {bool cancelSubscription = false}) {
    if (!_isCurrent(epoch)) return;
    _timer?.cancel();
    _timer = null;
    if (cancelSubscription) {
      _cancelSubscription();
    }
    final completion = _completion;
    _completion = null;
    _inFlight = null;
    if (completion != null && !completion.isCompleted) completion.complete();
  }

  void _invalidatePassive(int epoch, IosProxyMeasurementPhase phase) {
    if (!_isEpochCurrent(epoch)) return;
    _epoch++;
    _cancelResources();
    _emit(IosProxyMeasurementState(phase));
  }

  void _cancel(IosProxyMeasurementException error) {
    _epoch++;
    _cancelResources();
    final completion = _completion;
    _completion = null;
    _inFlight = null;
    _emit(const IosProxyMeasurementState(IosProxyMeasurementPhase.idle));
    if (completion != null && !completion.isCompleted) completion.completeError(error);
  }

  void _cancelResources() {
    _timer?.cancel();
    _timer = null;
    _cancelSubscription();
  }

  void _cancelSubscription() {
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      unawaited(_ignoreCancellationError(subscription.cancel()));
    }
  }

  Future<void> _ignoreCancellationError(Future<void> cancellation) async {
    try {
      await cancellation;
    } catch (_) {}
  }

  bool _isCurrent(int epoch) => !_disposed && epoch == _epoch && _completion != null;

  bool _isEpochCurrent(int epoch) => !_disposed && epoch == _epoch;

  void _emit(IosProxyMeasurementState next) {
    if (!_disposed && !_states.isClosed) _states.add(next);
  }
}
