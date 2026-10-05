import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/hiddifycore/core_start_failure.dart';
import 'package:hiddify/singbox/model/core_status.dart';

void main() {
  test('preserves gRPC details and publishes a stopped status', () {
    final result = mapCoreStartGrpcError(
      const GrpcError.unknown('start service: detour to an empty direct outbound makes no sense'),
    );

    const detail =
        'failed to start background core: UNKNOWN: '
        'start service: detour to an empty direct outbound makes no sense';
    expect(result.status, const CoreStatus.stopped(alert: CoreAlert.startFailed, message: detail));
    expect(result.failure, const ConnectionFailure.unexpected(detail));
  });

  test('classifies an unavailable Core separately', () {
    final result = mapCoreStartGrpcError(const GrpcError.unavailable('connection refused'));

    const detail = 'failed to start background core: UNAVAILABLE: connection refused';
    expect(result.status, const CoreStatus.stopped(alert: CoreAlert.startFailed, message: detail));
    expect(result.failure, const ConnectionFailure.backgroundCoreNotAvailable(detail));
  });

  test('does not add an empty message segment', () {
    final result = mapCoreStartGrpcError(const GrpcError.unknown());

    const detail = 'failed to start background core: UNKNOWN';
    expect(result.status, const CoreStatus.stopped(alert: CoreAlert.startFailed, message: detail));
    expect(result.failure, const ConnectionFailure.unexpected(detail));
  });
}
