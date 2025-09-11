import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/per_app_proxy/model/installed_package_info.dart';
import 'package:hiddify/utils/utils.dart';

abstract interface class PerAppProxyRepository {
  TaskEither<String, List<InstalledPackageInfo>> getInstalledPackages();
  TaskEither<String, Uint8List> getPackageIcon(String packageName);
}

class PerAppProxyRepositoryImpl
    with InfraLogger
    implements PerAppProxyRepository {
  final _methodChannel = const MethodChannel("com.hiddify.app/platform");

  @override
  TaskEither<String, List<InstalledPackageInfo>> getInstalledPackages() {
    return TaskEither(
      () async {
        loggy.debug("getting installed packages info");
        final result =
            await _methodChannel.invokeMethod<String>("get_installed_packages");
        if (result == null) return left("null response");
        return right(
          (jsonDecode(result) as List).map((e) {
            return InstalledPackageInfo.fromJson(e as Map<String, dynamic>);
          }).toList(),
        );
      },
    );
  }

  @override
  TaskEither<String, Uint8List> getPackageIcon(String packageName) {
    return TaskEither(
      () async {
        loggy.debug("getting package [$packageName] icon");
        final result = await _methodChannel.invokeMethod<String>(
          "get_package_icon",
          {"packageName": packageName},
        );
        if (result == null) return left("null response");
        final Uint8List decoded;
        try {
          decoded = base64.decode(result);
        } catch (e) {
          return left("error parsing base64 response");
        }
        return right(decoded);
      },
    );
  }
}
