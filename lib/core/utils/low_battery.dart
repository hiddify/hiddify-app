import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/utils/custom_loggers.dart';

final _log = appLogger('LowBattery');

/// At or under this share of charge, on battery, the battery counts as low.
const _lowLevel = 20;

/// Neither the level nor battery saver says when it changes, only charging does; they are read
/// again this often.
const _poll = Duration(minutes: 1);

/// Whether the device should save its battery: battery saver (low power mode) is on, or it runs on
/// battery at [_lowLevel]% or less. False where the platform cannot tell (a desktop without a
/// battery, Linux without UPower).
bool useLowBattery() {
  final low = useState(false);
  useEffect(() {
    final battery = Battery();
    var disposed = false;
    Future<void> check() async {
      var saving = false;
      var drained = false;
      try {
        saving = await battery.isInBatterySaveMode;
      } catch (_) {
        // not every platform knows battery saver
      }
      try {
        if (await battery.batteryState == BatteryState.discharging) {
          final level = await battery.batteryLevel;
          drained = level > 0 && level <= _lowLevel;
        }
      } catch (_) {
        // no battery, or no way to read it
      }
      final value = saving || drained;
      if (disposed || value == low.value) return;
      _log.info(value ? 'battery low or saving power: endless animations stop' : 'battery fine again');
      low.value = value;
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
