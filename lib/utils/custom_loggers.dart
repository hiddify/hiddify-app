import 'package:loggy/loggy.dart';




mixin AppLogger implements LoggyType {
  @override
  Loggy<AppLogger> get loggy => Loggy<AppLogger>('$runtimeType');
}




mixin PresLogger implements LoggyType {
  @override
  Loggy<PresLogger> get loggy => Loggy<PresLogger>('$runtimeType');
}




mixin InfraLogger implements LoggyType {
  @override
  Loggy<InfraLogger> get loggy => Loggy<InfraLogger>('$runtimeType');
}

abstract class LoggerMixin {
  LoggerMixin(this.loggy);

  final Loggy loggy;
}
