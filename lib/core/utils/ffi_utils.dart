import 'dart:ffi';

import 'package:ffi/ffi.dart';

R withMemory<R, T extends NativeType>(
  int size,
  R Function(Pointer<T> memory) action,
) {
  final memory = calloc<Int8>(size);
  try {
    return action(memory.cast());
  } finally {
    calloc.free(memory);
  }
}
