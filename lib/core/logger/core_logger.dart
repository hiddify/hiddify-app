import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart' as pb;
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:logging/logging.dart';

/// Engine logs, split by the `type` field every LogMessage already carries.
///
/// They used to share one name, which meant a failed profile import and a
/// thousand connection lines landed in the same pile. Splitting costs nothing —
/// the field is already on the wire, hiddify simply ignored it.
///
///   core.core     the proxy engine itself: connections, routing, dns
///   core.service  the background tunnel: start, stop, permissions
///   core.config   reading and validating a profile
Logger coreLogFor(pb.LogType type) => switch (type) {
  pb.LogType.SERVICE => _service,
  pb.LogType.CONFIG => _config,
  _ => _core,
};

final _core = coreLogger('core');
final _service = coreLogger('service');
final _config = coreLogger('config');
