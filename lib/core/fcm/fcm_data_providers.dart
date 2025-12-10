// TEMPORARILY DISABLED: Firebase Cloud Messaging
/*
import 'dart:io';

import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/fcm/fcm_polling_service.dart';
import 'package:hiddify/core/fcm/fcm_service.dart';
import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_data_providers.g.dart';

@Riverpod(keepAlive: true)
FcmService fcmService(FcmServiceRef ref) {
  final service = FcmService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
}

@Riverpod(keepAlive: true)
Future<FcmPollingService> fcmPollingService(FcmPollingServiceRef ref) async {
  if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
    throw UnsupportedError('FcmPollingService is only supported on Linux, Windows, and macOS (as fallback)');
  }

  // Ensure appInfoProvider is ready first, since httpClientProvider synchronously watches it.
  // This prevents httpClientProvider from failing when it tries to access appInfoProvider.requireValue.
  await ref.watch(appInfoProvider.future);

  // Now we can safely read httpClientProvider, which depends on appInfoProvider.
  // We use ref.read instead of ref.watch because ref.watch cannot be used for synchronous
  // providers in async provider builders. Since we've already ensured appInfoProvider is ready,
  // httpClientProvider will be able to access it successfully.
  final httpClient = ref.read(httpClientProvider);
  final service = FcmPollingService(
    httpClient: httpClient,
  );

  await service.init();

  // Log platform-specific message
  if (Platform.isLinux) {
    print('[FCM Polling] Initialized for Linux');
  } else if (Platform.isWindows) {
    print('[FCM Polling] Initialized for Windows');
  } else if (Platform.isMacOS) {
    print('[FCM Polling] Initialized for macOS (fallback)');
  }

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
*/
