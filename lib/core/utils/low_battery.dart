import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/utils/custom_loggers.dart';

final _log = appLogger('LowBattery');

/// Under this share of charge, on battery, the battery counts as low.
const _lowLevel = 5;

/// The level does not say when it changes, only charging does; it is read again this often.
const _poll = Duration(minutes: 1);

/// Whether the device should save its battery: it runs on battery under [_lowLevel]%. Battery
/// saver (low power mode) alone does not count. False where the platform cannot tell (a desktop
/// without a battery, Linux without UPower).
bool useLowBattery() {
  final low = useState(false);
  useEffect(() {
    final battery = Battery();
    var disposed = false;
    Future<void> check() async {
      var drained = false;
      try {
        if (await battery.batteryState == BatteryState.discharging) {
          final level = await battery.batteryLevel;
          drained = level > 0 && level < _lowLevel;
        }
      } catch (_) {
        // no battery, or no way to read it
      }
      if (disposed || drained == low.value) return;
      _log.info(drained ? 'battery low: endless animations stop' : 'battery fine again');
      low.value = drained;
    }

    final changes = battery.onBatteryStateChanged.listen((_) => unawaited(check()), onError: (Object _) {});
    final timer = Timer.periodic(_poll, (_) => unawaited(check()));
    unawaited(check());
    return () {
      disposed = true;
      unawaited(changes.cancel());
      timer.cancel();
    };
  }, const []);
  return low.value;
}
