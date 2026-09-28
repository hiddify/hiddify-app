import 'dart:io';

import 'package:hiddify/hiddifycore/core_interface/core_interface.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_desktop.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_mobile.dart';
import 'package:hiddify/hiddifycore/core_interface/core_interface_macos.dart';

CoreInterface getCoreInterface() {
  if (Platform.isAndroid || Platform.isIOS) {
    return CoreInterfaceMobile();
  }
  if (Platform.isMacOS) return CoreInterfaceMacOS();
  return CoreInterfaceDesktop();
}
