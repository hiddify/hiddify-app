import 'package:flutter/material.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/preferences/actions_at_closing.dart';
import 'package:hiddify/core/router/dialog/widgets/action_at_closing_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/confirmation_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/custom_alert_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/experimental_feature_notice.dart';
import 'package:hiddify/core/router/dialog/widgets/free_profile_consent_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/new_version_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/no_active_profile_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/ok_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/proxy_info_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/region_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/save_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/setting_checkbox_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/setting_input_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/setting_picker_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/setting_radio_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/setting_slider_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/setting_text_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/sort_profiles_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/unknown_domains_warning_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/warp_license_dialog.dart';
import 'package:hiddify/core/router/dialog/widgets/window_closing_dialog.dart';
import 'package:hiddify/core/router/go_router/go_router_notifier.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/features/common/qr_code_dialog.dart';
import 'package:hiddify/features/common/qr_code_scanner_screen.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:protobuf/protobuf.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dialog_notifier.g.dart';

@Riverpod(keepAlive: true)
class DialogNotifier extends _$DialogNotifier {
  @override
  void build() {}

  Future<T?> _show<T>(Widget child) async {
    final context = rootNavKey.currentContext;
    if (context == null) return null;
    // ref.read(popupCountNotifierProvider.notifier).increase();
    return await Navigator.of(context).push<T>(DialogRoute(context: context, builder: (context) => child)).then((
      value,
    ) {
      // ref.read(popupCountNotifierProvider.notifier).decrease();
      return value;
    });
  }

  Future<String?> showQrScanner() async {
    return await _show<String?>(const QrCodeScannerDialog());
  }

  Future<void> showSortProfiles() async {
    return await _show<void>(const SortProfilesDialog());
  }

  Future<bool> showWarpLicense() async {
    return await _show<bool?>(const WarpLicenseDialog()) ?? false;
  }

  Future<void> showQrCode(String link, {String? message}) async {
    return await _show<void>(QrCodeDialog(link, message: message));
  }

  Future<void> showOk(String title, String description) async {
    return await _show<void>(OkDialog(title: title, description: description));
  }

  Future<double?> showSettingSlider({
    required String title,
    required double initialValue,
    VoidCallback? onReset,
    double min = 0,
    double max = 1,
    int? divisions,
    String Function(double value)? labelGen,
  }) async {
    return await _show<double?>(
      SettingsSliderDialog(
        title: title,
        initialValue: initialValue,
        onReset: onReset,
        min: min,
        max: max,
        divisions: divisions,
        labelGen: labelGen,
      ),
    );
  }

  Future<void> showNewVersion({
    required String currentVersion,
    required RemoteVersionEntity newVersion,
    required bool canIgnore,
  }) async {
    return await _show<void>(NewVersionDialog(currentVersion, newVersion, canIgnore: canIgnore));
  }

  Future<bool> showConfirmation({
    required String title,
    required String message,
    IconData? icon,
    String? positiveBtnTxt,
  }) async {
    return await _show<bool>(
          ConfirmationDialog(title: title, message: message, icon: icon, positiveBtnTxt: positiveBtnTxt),
        ) ??
        false;
  }

  Future<Region?> showRegion({required Region selected}) async {
    return await _show<Region?>(RegionDialog(selected: selected));
  }

  Future<ActionsAtClosing?> showActionAtClosing({required ActionsAtClosing selected}) async {
    return await _show<ActionsAtClosing?>(ActionsAtClosingDialog(selected: selected));
  }

  Future<bool> showExperimentalFeatureNotice() async {
    final hasExperimental = ref.read(ConfigOptions.hasExperimentalFeatures);
    final canShowNotice = !ref.read(disableExperimentalFeatureNoticeProvider);
    if (hasExperimental && canShowNotice) {
      return await _show<bool?>(const ExperimentalFeatureNoticeDialog()) ?? false;
    }
    return true;
  }

  Future<void> showNoActiveProfile() async {
    return await _show<void>(const NoActiveProfileDialog());
  }

  Future<bool> showFreeProfileConsent({required String title, required String consent}) async {
    return await _show<bool?>(FreeProfileConsentDialog(title: title, consent: consent)) ?? false;
  }

  Future<bool> showUnknownDomainsWarning({required String url}) async {
    return await _show<bool?>(UnknownDomainsWarningDialog(url: url)) ?? false;
  }

  Future<void> showProxyInfo({required OutboundInfo outboundInfo}) async {
    return await _show<void>(ProxyInfoDialog(outboundInfo: outboundInfo));
  }

  Future<String?> showSettingText({
    required String lable,
    String value = '',
    String? defaultValue,
    FormFieldValidator<String>? validator,
  }) async {
    return await _show<String?>(
      SettingTextDialog(lable: lable, value: value, defaultValue: defaultValue, validator: validator),
    );
  }

  Future<List<ProtobufEnum>?> showSettingCheckbox({
    required String title,
    required List<ProtobufEnum> values,
    required List<ProtobufEnum> selectedValues,
    List<ProtobufEnum>? defaultValue,
    Map<String, String>? t,
  }) async {
    return await _show<List<ProtobufEnum>?>(
      SettingCheckboxDialog(
        title: title,
        values: values,
        selectedValues: selectedValues,
        defaultValue: defaultValue,
        t: t,
      ),
    );
  }

  Future<T?> showSettingRadio<T>({
    required String title,
    required List<T> values,
    required T value,
    T? defaultValue,
    Map<String, String>? t,
  }) async {
    return await _show<T?>(
      SettingRadioDialog(title: title, values: values, value: value, defaultValue: defaultValue, t: t),
    );
  }

  Future<T?> showSettingInput<T>({
    required String title,
    required T initialValue,
    T? Function(String value)? mapTo,
    bool Function(String value)? validator,
    String Function(T value)? valueFormatter,
    List<T>? possibleValues,
    VoidCallback? onReset,
    (String text, VoidCallback)? optionalAction,
    IconData? icon,
    bool digitsOnly = false,
  }) async {
    return await _show<T?>(
      SettingInputDialog(
        title: title,
        initialValue: initialValue,
        mapTo: mapTo,
        validator: validator,
        valueFormatter: valueFormatter,
        possibleValues: possibleValues,
        onReset: onReset,
        optionalAction: optionalAction,
        icon: icon,
        digitsOnly: digitsOnly,
      ),
    );
  }

  Future<T?> showSettingPicker<T>({
    required String title,
    required T selected,
    required List<T> options,
    required String Function(T e) getTitle,
    VoidCallback? onReset,
  }) async {
    return await _show<T?>(
      SettingPickerDialog(title: title, selected: selected, options: options, getTitle: getTitle, onReset: onReset),
    );
  }

  Future<bool?> showSave({required String title, required String description}) async {
    return await _show<bool?>(SaveDialog(title: title, description: description));
  }

  Future<void> showWindowClosing() async {
    return await _show<void>(const WindowClosingDialog());
  }

  Future<void> showCustomAlert({String? title, required String message}) async {
    return await _show<void>(CustomAlertDialog(title: title, message: message));
  }

  Future<void> showCustomAlertFromErr(({String type, String? message}) err) async {
    return await _show<void>(CustomAlertDialog.fromErr(err));
  }
}
