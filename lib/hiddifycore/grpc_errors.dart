import 'package:grpc/grpc.dart';

/// Whether a gRPC error only says that the core's end of the channel went away.
///
/// A core that is not running refuses the connection (unavailable). A core that stops while a
/// stream is open, which every reconnect does (Android closes the VPN service and its gRPC
/// server, then starts them again), closes the socket under the stream: the HTTP/2 client then
/// fails the call as unknown, "Connection is being forcefully terminated" with errorCode 10
/// (CONNECT_ERROR). Neither is an error of the app; the stream is armed again on the next start.
bool isCoreGoneError(Object? error) {
  if (error is! GrpcError) return false;
  if (error.code == StatusCode.unavailable) return true;
  return error.code == StatusCode.unknown &&
      (error.message ?? '').contains('Connection is being forcefully terminated');
}
