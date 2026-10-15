import 'package:hiddify/features/connection/model/connection_failure.dart';

enum DiagnosticOperation { setup, connect, reconnect, disconnect, tunnel }

enum DiagnosticStage { requested, accepted, failed, state }

enum DiagnosticCode {
  none,
  unexpected,
  vpnPermissionDenied,
  notificationPermissionDenied,
  privilegeRequired,
  invalidConfigOption,
  invalidConfig,
  coreUnavailable,
  warpLicenseRequired,
  starting,
  started,
  stopping,
  stopped,
}

DiagnosticCode diagnosticCodeForFailure(ConnectionFailure failure) => switch (failure) {
  UnexpectedConnectionFailure() => DiagnosticCode.unexpected,
  MissingVpnPermission() => DiagnosticCode.vpnPermissionDenied,
  MissingNotificationPermission() => DiagnosticCode.notificationPermissionDenied,
  MissingPrivilege() => DiagnosticCode.privilegeRequired,
  InvalidConfigOption() => DiagnosticCode.invalidConfigOption,
  InvalidConfig() => DiagnosticCode.invalidConfig,
  BackgroundCoreNotAvailable() => DiagnosticCode.coreUnavailable,
  MissingWarpLicense() => DiagnosticCode.warpLicenseRequired,
};

final class SafeDiagnosticEvent {
  SafeDiagnosticEvent({
    required this.sequence,
    required this.operationId,
    required this.operation,
    required this.stage,
    required this.code,
    int durationMs = 0,
  }) : durationMs = durationMs.clamp(0, maxDurationMs) {
    if (sequence <= 0 || sequence > maxCounter) {
      throw RangeError.range(sequence, 1, maxCounter, 'sequence');
    }
    if (operationId < 0 || operationId > maxCounter || !_validOperationId(operationId, operation, stage)) {
      throw RangeError.range(operationId, 0, maxCounter, 'operationId');
    }
  }

  static const int maxDurationMs = 3600000;
  static const int maxCounter = 9007199254740991;
  static const Set<String> _keys = {
    'sequence',
    'operation_id',
    'operation',
    'stage',
    'code',
    'duration_ms',
    'reachability',
  };

  final int sequence;
  final int operationId;
  final DiagnosticOperation operation;
  final DiagnosticStage stage;
  final DiagnosticCode code;
  final int durationMs;

  Map<String, Object> toJson() => {
    'sequence': sequence,
    'operation_id': operationId,
    'operation': operation.name,
    'stage': stage.name,
    'code': code.name,
    'duration_ms': durationMs,
    'reachability': 'not_checked',
  };

  factory SafeDiagnosticEvent.fromJson(Map<String, Object?> json) {
    if (json.length != _keys.length || !json.keys.every(_keys.contains)) {
      throw const FormatException('invalid diagnostic event fields');
    }
    final sequence = json['sequence'];
    final operationId = json['operation_id'];
    final operation = json['operation'];
    final stage = json['stage'];
    final code = json['code'];
    final durationMs = json['duration_ms'];
    if (sequence is! int ||
        sequence <= 0 ||
        sequence > maxCounter ||
        operationId is! int ||
        operationId < 0 ||
        operationId > maxCounter ||
        operation is! String ||
        stage is! String ||
        code is! String ||
        durationMs is! int ||
        durationMs < 0 ||
        durationMs > maxDurationMs ||
        json['reachability'] != 'not_checked') {
      throw const FormatException('invalid diagnostic event value');
    }
    final parsedOperation = _enumByName(DiagnosticOperation.values, operation);
    final parsedStage = _enumByName(DiagnosticStage.values, stage);
    final parsedCode = _enumByName(DiagnosticCode.values, code);
    if (parsedOperation == null || parsedStage == null || parsedCode == null) {
      throw const FormatException('unknown diagnostic event value');
    }
    if (!_validOperationId(operationId, parsedOperation, parsedStage)) {
      throw const FormatException('invalid diagnostic operation id');
    }
    return SafeDiagnosticEvent(
      sequence: sequence,
      operationId: operationId,
      operation: parsedOperation,
      stage: parsedStage,
      code: parsedCode,
      durationMs: durationMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafeDiagnosticEvent &&
          sequence == other.sequence &&
          operationId == other.operationId &&
          operation == other.operation &&
          stage == other.stage &&
          code == other.code &&
          durationMs == other.durationMs;

  @override
  int get hashCode => Object.hash(sequence, operationId, operation, stage, code, durationMs);
}

bool _validOperationId(int operationId, DiagnosticOperation operation, DiagnosticStage stage) =>
    operationId > 0 || operation == DiagnosticOperation.tunnel && stage == DiagnosticStage.state;

T? _enumByName<T extends Enum>(List<T> values, String name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
