import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';

void main() {
  test('a core that is up is running whether or not a ping works yet', () {
    expect(const ConnectionStatus.waiting().isRunning, isTrue);
    expect(const ConnectionStatus.connected().isRunning, isTrue);
    expect(const ConnectionStatus.noAvailableProxies().isRunning, isTrue);
    expect(const ConnectionStatus.hotReloading().isRunning, isTrue);
    expect(const ConnectionStatus.connecting().isRunning, isFalse);
    expect(const ConnectionStatus.disconnecting().isRunning, isFalse);
    expect(const ConnectionStatus.disconnected().isRunning, isFalse);
  });

  test('only a positive ping is connected', () {
    expect(const ConnectionStatus.waiting().isConnected, isFalse);
    expect(const ConnectionStatus.connected().isConnected, isTrue);
  });
}
