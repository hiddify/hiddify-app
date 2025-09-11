import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

extension RefLifeCycle<T> on AutoDisposeRef<T> {
  void disposeDelay(Duration duration) {
    final link = keepAlive();
    Timer? timer;

    onCancel(() {
      timer?.cancel();
      timer = Timer(duration, link.close);
    });

    onDispose(() {
      timer?.cancel();
    });

    onResume(() {
      timer?.cancel();
    });
  }
}
