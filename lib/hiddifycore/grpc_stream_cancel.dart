import 'dart:async';

import 'package:grpc/grpc.dart';

extension CancelOnUnsubscribe<T> on ResponseStream<T> {
  /// This call as a stream whose cancellation also cancels the call.
  ///
  /// grpc-dart ties a subscription's cancel to the call only once the call's HTTP/2 stream is
  /// open. A subscription cancelled before that, which a quick re-listen does, left the call
  /// open with nobody reading it: the core kept sending into it, and once the unread data filled
  /// the connection's flow-control window (64 KB) no other call on the channel got an answer.
  /// Connect, disconnect and the proxy list then all waited forever.
  Stream<T> get cancelOnUnsubscribe {
    StreamSubscription<T>? subscription;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        subscription = listen(controller.add, onError: controller.addError, onDone: controller.close);
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        final cancelled = subscription?.cancel();
        // also before the HTTP/2 stream exists: the call then never sends its request
        unawaited(cancel().catchError((Object _) {}));
        return cancelled;
      },
    );
    return controller.stream;
  }
}
