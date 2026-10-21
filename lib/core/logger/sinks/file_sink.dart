// Picks the real file sink on any platform that has dart:io,
// and the do-nothing stub on web. The compiler decides, not runtime code.
export 'file_sink_stub.dart'
    if (dart.library.io) 'file_sink_io.dart';
