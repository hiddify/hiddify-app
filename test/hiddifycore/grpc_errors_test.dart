import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:hiddify/hiddifycore/grpc_errors.dart';
import 'package:http2/transport.dart';

void main() {
  test('a core that is not running is gone', () {
    expect(isCoreGoneError(const GrpcError.unavailable('Error connecting: connection refused')), isTrue);
  });

  // the error grpc-dart raises when the core's gRPC server stops under an open stream, as on
  // every reconnect on Android
  test('a core that closed the connection under a stream is gone', () {
    final error = GrpcError.unknown(
      TransportConnectionException(10, 'Connection is being forcefully terminated.').toString(),
    );
    expect(error.message, 'HTTP/2 error: Connection error: Connection is being forcefully terminated. (errorCode: 10)');
    expect(isCoreGoneError(error), isTrue);
  });

  test('other errors are errors', () {
    expect(isCoreGoneError(const GrpcError.unknown('something else')), isFalse);
    expect(isCoreGoneError(const GrpcError.internal('Connection is being forcefully terminated')), isFalse);
    expect(isCoreGoneError(StateError('not grpc')), isFalse);
  });
}
