import 'package:flutter/material.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/app_router.dart';
import 'package:hiddify/features/config_option/widget/quick_settings_modal.dart';
import 'package:hiddify/features/profile/add/add_profile_modal.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottom_sheets_notifier.g.dart';

@riverpod
class ButtomSheetsNotifier extends _$ButtomSheetsNotifier {
  @override
  void build() {}

  // Wait for result example
  // Future<T?> show<T>() async {
  //   final context = rootNavigatorKey.currentContext;
  //   if (context == null) return null;
  //   return await showModalBottomSheet<T>();
  // }

  void showAddProfile({String? url}) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    showModalBottomSheet(
      constraints: BottomSheetConst.boxConstraints,
      isScrollControlled: true,
      context: context,
      builder: (context) => ClipRRect(
        borderRadius: BottomSheetConst.borderRadius,
        child: Material(
          child: AddProfileModal(url: url),
        ),
      ),
    );
  }

  void showProfilesOverview() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    showModalBottomSheet(
      constraints: BottomSheetConst.boxConstraints,
      isScrollControlled: true,
      context: context,
      builder: (context) => const ClipRRect(
        borderRadius: BottomSheetConst.borderRadius,
        child: Material(
          child: ProfilesOverviewModal(),
        ),
      ),
    );
  }

  void showQuickSettings() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    showModalBottomSheet(
      constraints: BottomSheetConst.boxConstraints,
      context: context,
      builder: (context) => const ClipRRect(
        borderRadius: BottomSheetConst.borderRadius,
        child: Material(
          child: QuickSettingsModal(),
        ),
      ),
    );
  }
}
