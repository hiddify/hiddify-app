import 'package:hiddify/hiddifycore/core_interface/core_interface_mobile.dart';

/// Best-effort root check. A channel error means "no root": it must never fail a connect or
/// abort the settings switch. The native side caches the answer, so repeated calls do not ask
/// the user again.
Future<bool> checkRootAccess() async {
  try {
    return await CoreInterfaceMobile.methodChannel.invokeMethod<bool>('check_root') ?? false;
  } catch (_) {
    return false;
  }
}
