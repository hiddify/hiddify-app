import 'package:grpc/grpc.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/singbox/model/core_status.dart';

({CoreStatus status, ConnectionFailure failure}) mapCoreStartGrpcError(GrpcError error) {
  final grpcMessage = error.message?.trim();
  final detail = [
    'failed to start background core',
    error.codeName,
    if (grpcMessage != null && grpcMessage.isNotEmpty) grpcMessage,
  ].join(': ');
  final status = CoreStatus.stopped(alert: CoreAlert.startFailed, message: detail);
  final failure = error.code == StatusCode.unavailable
      ? ConnectionFailure.backgroundCoreNotAvailable(detail)
      : ConnectionFailure.unexpected(detail);
  return (status: status, failure: failure);
}
