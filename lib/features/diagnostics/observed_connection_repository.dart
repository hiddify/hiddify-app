import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/connection/data/connection_repository.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_event.dart';
import 'package:hiddify/features/diagnostics/safe_diagnostic_journal.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';

/// Observes commands without changing their arguments, timing or outcomes.
final class ObservedConnectionRepository implements ConnectionRepository {
  ObservedConnectionRepository(this._delegate, this._journal, {int Function()? elapsedMilliseconds}) {
    final watch = Stopwatch()..start();
    _elapsedMilliseconds = elapsedMilliseconds ?? () => watch.elapsedMilliseconds;
  }

  final ConnectionRepository _delegate;
  final SafeDiagnosticJournal _journal;
  late final int Function() _elapsedMilliseconds;

  @override
  SingboxConfigOption? get configOptionsSnapshot => _delegate.configOptionsSnapshot;

  @override
  TaskEither<ConnectionFailure, Unit> setup() => _observe(DiagnosticOperation.setup, _delegate.setup());

  @override
  TaskEither<ConnectionFailure, Unit> connect(ProfileEntity activeProfile, bool disableMemoryLimit) =>
      _observe(DiagnosticOperation.connect, _delegate.connect(activeProfile, disableMemoryLimit));

  @override
  TaskEither<ConnectionFailure, Unit> reconnect(ProfileEntity activeProfile, bool disableMemoryLimit) =>
      _observe(DiagnosticOperation.reconnect, _delegate.reconnect(activeProfile, disableMemoryLimit));

  @override
  TaskEither<ConnectionFailure, Unit> disconnect() => _observe(DiagnosticOperation.disconnect, _delegate.disconnect());

  @override
  Stream<ConnectionStatus> watchConnectionStatus() => _delegate.watchConnectionStatus().map((status) {
    _safely(() {
      final code = switch (status) {
        Connecting() => DiagnosticCode.starting,
        Connected() => DiagnosticCode.started,
        Disconnecting() => DiagnosticCode.stopping,
        Disconnected(:final connectionFailure) =>
          connectionFailure == null ? DiagnosticCode.stopped : diagnosticCodeForFailure(connectionFailure),
      };
      _journal.record(operation: DiagnosticOperation.tunnel, stage: DiagnosticStage.state, code: code, operationId: 0);
    });
    return status;
  });

  TaskEither<ConnectionFailure, Unit> _observe(
    DiagnosticOperation operation,
    TaskEither<ConnectionFailure, Unit> task,
  ) => TaskEither(() async {
    int? operationId;
    int? started;
    _safely(() {
      operationId = _journal.nextOperationId();
      _journal.record(
        operation: operation,
        stage: DiagnosticStage.requested,
        code: DiagnosticCode.none,
        operationId: operationId!,
      );
    });
    _safely(() => started = _elapsedMilliseconds());
    try {
      final result = await task.run();
      _safely(() {
        result.match(
          (failure) =>
              _complete(operation, operationId, started, DiagnosticStage.failed, diagnosticCodeForFailure(failure)),
          (_) => _complete(operation, operationId, started, DiagnosticStage.accepted, DiagnosticCode.none),
        );
      });
      return result;
    } on Object {
      _safely(() => _complete(operation, operationId, started, DiagnosticStage.failed, DiagnosticCode.unexpected));
      rethrow;
    }
  });

  void _complete(
    DiagnosticOperation operation,
    int? operationId,
    int? started,
    DiagnosticStage stage,
    DiagnosticCode code,
  ) {
    if (operationId == null) return;
    var duration = 0;
    _safely(() {
      if (started != null) duration = _elapsedMilliseconds() - started;
    });
    _journal.record(operation: operation, stage: stage, code: code, operationId: operationId, durationMs: duration);
  }

  void _safely(void Function() action) {
    try {
      action();
    } on Object {
      // Diagnostics must never alter a VPN command or stream outcome.
    }
  }
}
