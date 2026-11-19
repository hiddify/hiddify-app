import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;

/// The CPU time this process has used so far, user and kernel together, or null where it cannot be
/// read. The core runs in a process of its own on desktop, so this is the app's own share.
Duration? processCpuTime() {
  try {
    if (Platform.isWindows) return _windowsCpuTime();
    if (Platform.isLinux || Platform.isMacOS) return _rusageCpuTime();
  } catch (_) {
    // an unknown platform layout: no measurement rather than a wrong one
  }
  return null;
}

Duration _windowsCpuTime() => using((arena) {
  final creation = arena<win32.FILETIME>();
  final exit = arena<win32.FILETIME>();
  final kernel = arena<win32.FILETIME>();
  final user = arena<win32.FILETIME>();
  if (win32.GetProcessTimes(win32.GetCurrentProcess(), creation, exit, kernel, user) == 0) {
    throw StateError('GetProcessTimes failed');
  }
  // in units of 100 ns
  int ticks(Pointer<win32.FILETIME> time) => (time.ref.dwHighDateTime << 32) | time.ref.dwLowDateTime;
  return Duration(microseconds: (ticks(kernel) + ticks(user)) ~/ 10);
});

final _getrusage = DynamicLibrary.process()
    .lookupFunction<Int32 Function(Int32 who, Pointer<Uint8> usage), int Function(int who, Pointer<Uint8> usage)>(
      'getrusage',
    );

// struct rusage starts with ru_utime and ru_stime, two struct timeval of 16 bytes on 64-bit Linux
// and macOS: tv_sec (64-bit), then tv_usec (64-bit on Linux, 32-bit and padding on macOS; under a
// million either way, so its low 32 bits are the value on these little-endian systems).
const _rusageSelf = 0;
const _rusageSize = 256; // larger than struct rusage on both

Duration _rusageCpuTime() => using((arena) {
  final usage = arena<Uint8>(_rusageSize);
  if (_getrusage(_rusageSelf, usage) != 0) throw StateError('getrusage failed');
  int microseconds(int offset) =>
      Pointer<Int64>.fromAddress(usage.address + offset).value * 1000000 +
      Pointer<Int32>.fromAddress(usage.address + offset + 8).value;
  return Duration(microseconds: microseconds(0) + microseconds(16));
});
