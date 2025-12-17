import 'dart:async';

import 'package:flutter/foundation.dart';

class CallbackDebouncer {
  CallbackDebouncer(this._delay);

  final Duration _delay;
  Timer? _timer;

  
  void call(VoidCallback callback) {
    if (_delay == Duration.zero) {
      callback();
    } else {
      _timer?.cancel();
      _timer = Timer(_delay, callback);
    }
  }

  
  void dispose() {
    _timer?.cancel();
  }
}
