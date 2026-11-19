// The real store on any platform with dart:io, the do-nothing stub on web.
export 'app_crash_store_stub.dart' if (dart.library.io) 'app_crash_store_io.dart';
