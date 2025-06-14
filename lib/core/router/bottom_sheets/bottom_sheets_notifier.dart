import 'package:flutter/material.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/go_router/routing_config_notifier.dart';
import 'package:hiddify/features/profile/add/add_profile_modal.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_page.dart';
import 'package:hiddify/features/settings/widget/quick_settings_modal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottom_sheets_notifier.g.dart';

@riverpod
class BottomSheetsNotifier extends _$BottomSheetsNotifier {
  @override
  void build() {}

  Future<T?> _show<T>({required Widget child, required bool isScrollControlled}) async {
    final context = branchNavKey.currentContext;
    if (context == null) return null;
    ref.read(popupCountNotifierProvider.notifier).increase();
    return await Navigator.of(context)
        .push<T>(
      ModalBottomSheetRoute(
        constraints: BottomSheetConst.boxConstraints,
        isScrollControlled: isScrollControlled,
        builder: (context) => ClipRRect(
          borderRadius: BottomSheetConst.borderRadius,
          child: Material(
            child: child,
          ),
        ),
      ),
    )
        .then(
      (value) {
        ref.read(popupCountNotifierProvider.notifier).decrease();
        return value;
      },
    );
  }

  Future<void> showAddProfile({String? url}) async => await _show(
        isScrollControlled: true,
        child: AddProfileModal(url: url),
      );

  Future<void> showProfilesOverview() async => await _show(
        isScrollControlled: true,
        child: const ProfilesOverviewModal(),
      );

  Future<void> showQuickSettings() async => await _show(
        isScrollControlled: false,
        child: const QuickSettingsModal(),
      );
}
