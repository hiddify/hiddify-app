import 'package:hiddify/singbox/service/noop_singbox_service.dart';
import 'package:hiddify/singbox/service/singbox_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'singbox_service_provider.g.dart';

@Riverpod(keepAlive: true)
SingboxService singboxService(Ref ref) {
  const disableCore = bool.fromEnvironment('DISABLE_CORE');
  if (disableCore) {
    return NoopSingboxService();
  }
  return SingboxService();
}
