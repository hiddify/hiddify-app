import 'package:hiddify/core/logger/log_service.dart';
import 'package:hiddify/core/service/core_service.dart';
import 'package:hiddify/features/config/model/config.dart';
import 'package:hiddify/features/connection/logic/core_configurator.dart';
import 'package:hiddify/features/settings/model/core_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connection_notifier.g.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

@riverpod
class ConnectionNotifier extends _$ConnectionNotifier {
  late final CoreService _coreService;

  @override
  ConnectionStatus build() {
    _coreService = CoreService();
    return ConnectionStatus.disconnected;
  }

  Future<void> connect(Config config) async {
    state = ConnectionStatus.connecting;
    
    try {
      final coreMode = ref.read(CorePreferences.coreMode);
      final routingRule = ref.read(CorePreferences.routingRule);
      final logLevel = ref.read(CorePreferences.logLevel);
      final enableLogging = ref.read(CorePreferences.enableLogging);
      
      final socksPort = ref.read(CorePreferences.sockPort);
      final httpPort = ref.read(CorePreferences.httpPort);
      final enableMux = ref.read(CorePreferences.enableMux);
      final muxConcurrency = ref.read(CorePreferences.muxConcurrency);
      final domainStrategy = ref.read(CorePreferences.domainStrategy);
      final allowInsecure = ref.read(CorePreferences.allowInsecure);
      final remoteDns = ref.read(CorePreferences.remoteDns);
      final fingerPrint = ref.read(CorePreferences.fingerPrint);

      final accessLogPath = await ref.read(logServiceProvider).getAccessLogPath();
      final errorLogPath = await ref.read(logServiceProvider).getCoreLogPath();

      final fullConfig = CoreConfigurator.generateConfig(
        activeConfig: config,
        coreMode: coreMode,
        routingRule: routingRule,
        logLevel: logLevel,
        enableLogging: enableLogging,
        accessLogPath: accessLogPath,
        errorLogPath: errorLogPath,
        socksPort: socksPort,
        httpPort: httpPort,
        enableMux: enableMux,
        muxConcurrency: muxConcurrency,
        domainStrategy: domainStrategy,
        allowInsecure: allowInsecure,
        remoteDns: remoteDns,
        fingerPrint: fingerPrint,
      );

      final error = await _coreService.start(fullConfig);
      if (error == null) {
        state = ConnectionStatus.connected;
      } else {
        state = ConnectionStatus.error;
        // Trigger failover or show error
      }
    } catch (e) {
      state = ConnectionStatus.error;
    }
  }

  Future<void> disconnect() async {
    await _coreService.stop();
    state = ConnectionStatus.disconnected;
  }
}
