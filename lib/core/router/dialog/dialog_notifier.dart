import 'package:flutter/material.dart';
import 'package:hiddify/core/router/app_router.dart';
import 'package:hiddify/features/common/qr_code_scanner_screen.dart';
import 'package:hiddify/features/config_option/overview/warp_options_widgets.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dialog_notifier.g.dart';

@riverpod
class DialogNotifier extends _$DialogNotifier {
  @override
  void build() {}

  Future<T?> showQrScanner<T>() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return null;
    return await showDialog<T>(
      context: context,
      builder: (context) => const QrCodeScannerDialog(),
    );
  }

  Future<T?> showSortProfiles<T>() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return null;
    return await showDialog<T>(
      context: context,
      builder: (context) => const SortProfilesDialog(),
    );
  }

  Future<T?> showWarpLicense<T>() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return null;
    return await showDialog<T>(
      context: context,
      builder: (context) => const WarpLicenseDialog(),
    );
  }

  Future<T?> showWarpConfig<T>(String content) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return null;
    return await showDialog<T>(
      context: context,
      builder: (context) => WarpConfigDialog(content: content),
    );
  }
}
