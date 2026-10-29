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

    test('waiting is the core up without a ping, started comes with a ping', () {
      expect(CoreStatus.fromCoreInfo(CoreInfoResponse(coreState: CoreStates.WAITING)), isA<CoreWaiting>());
      expect(CoreStatus.fromCoreInfo(CoreInfoResponse(coreState: CoreStates.STARTED)), isA<CoreStarted>());
      expect(CoreStatus.fromEvent({'status': 'Waiting'}), isA<CoreWaiting>());
    });

    test('every proxy timing out is its own state, not an alert', () {
      final status = CoreStatus.fromCoreInfo(CoreInfoResponse(coreState: CoreStates.NO_AVAILABLE_PROXIES));
      expect(status, isA<CoreNoAvailableProxies>());
      expect(status.getCoreAlert(), isNull);
    });
  });
}
