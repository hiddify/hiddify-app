import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:hiddify/core/utils/ffi_utils.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:posix/posix.dart';
import 'package:win32/win32.dart';

abstract interface class ConnectionPlatformSource {
  Future<bool> checkPrivilege();
}

class ConnectionPlatformSourceImpl with InfraLogger implements ConnectionPlatformSource {
  @override
  Future<bool> checkPrivilege() async {
    try {
      if (Platform.isWindows) {
        bool isElevated = false;
        withMemory<void, Uint32>(sizeOf<Uint32>(), (phToken) {
          withMemory<void, Uint32>(sizeOf<Uint32>(), (pReturnedSize) {
            withMemory<void, _TokenElevation>(sizeOf<_TokenElevation>(), (pElevation) {
              if (OpenProcessToken(
                    GetCurrentProcess(),
                    TOKEN_QUERY,
                    phToken.cast(),
                  ) ==
                  1) {
                if (GetTokenInformation(
                      phToken.value,
                      TOKEN_INFORMATION_CLASS.TokenElevation,
                      pElevation,
                      sizeOf<_TokenElevation>(),
                      pReturnedSize,
                    ) ==
                    1) {
                  isElevated = pElevation.ref.tokenIsElevated != 0;
                }
              }
              if (phToken.value != 0) {
                CloseHandle(phToken.value);
              }
            });
          });
        });
        return isElevated;
      } else if (Platform.isLinux) {
        final euid = geteuid();
        return euid == 0;
      } else if (Platform.isMacOS) {
        final versionPart = Platform.operatingSystemVersion.split(".")[0].split(" ")[1];
        final majorVersion = int.parse(versionPart);

        if (majorVersion >= 13) {
          return true;
        }

        final euid = geteuid();
        return euid == 0;
      } else {
        return true;
      }
    } catch (e) {
      loggy.warning("error checking privilege", e);
      return true; // return true so core handles it
    }
  }
}

sealed class _TokenElevation extends Struct {
  /// A nonzero value if the token has elevated privileges;
  /// otherwise, a zero value.
  @Int32()
  external int tokenIsElevated;
}
