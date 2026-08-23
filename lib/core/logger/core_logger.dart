import 'package:logging/logging.dart';

/// Everything arriving from the Go engine shares this one logger name, so the
/// logs page can filter the whole engine out — or show only it — with a single
/// `core` category check.
final coreLog = Logger('core');
