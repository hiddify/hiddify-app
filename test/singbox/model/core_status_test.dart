import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/singbox/model/core_status.dart';

void main() {
  group('CoreStatus.fromCoreInfo', () {
    test('a repeated stop is a normal stop, not a connection failure', () {
      final status = CoreStatus.fromCoreInfo(
        CoreInfoResponse(coreState: CoreStates.STOPPED, messageType: MessageType.ALREADY_STOPPED),
      );
      expect(status, isA<CoreStopped>());
      expect(status.getCoreAlert(), isNull);
    });

    test('a real start failure is still reported', () {
      final status = CoreStatus.fromCoreInfo(
        CoreInfoResponse(coreState: CoreStates.STOPPED, messageType: MessageType.START_SERVICE, message: 'boom'),
      );
      expect(status.getCoreAlert(), isNotNull);
    });

    test('hot reloading is its own state, without an alert', () {
      final status = CoreStatus.fromCoreInfo(CoreInfoResponse(coreState: CoreStates.HOT_RELOADING));
      expect(status, isA<CoreHotReloading>());
      expect(status.getCoreAlert(), isNull);
      expect(CoreStatus.fromEvent({'status': 'HotReloading'}), isA<CoreHotReloading>());
    });
  });
}
