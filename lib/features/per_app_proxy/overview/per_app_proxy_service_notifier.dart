import 'dart:async';

import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/per_app_proxy/data/selected_data_provider.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/per_app_proxy/overview/per_app_proxy_notifier.dart';
import 'package:installed_apps/index.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'per_app_proxy_service_notifier.g.dart';

@riverpod
class PerAppProxyService extends _$PerAppProxyService {
  StreamSubscription? _includeSubscription;
  StreamSubscription? _excludeSubscription;
  Timer? _timer;
  @override
  Future<void> build() async {
    final phonePkgs = (await InstalledApps.getInstalledApps(false)).map((e) => e.packageName).toSet();
    _includeSubscription = ref
        .read(appProxyDataSourceProvider)
        .watchActivePackages(phonePkgs: phonePkgs, mode: AppProxyMode.include)
        .listen((pkgs) => ref.read(Preferences.includeApps.notifier).update(pkgs));
    _excludeSubscription = ref
        .read(appProxyDataSourceProvider)
        .watchActivePackages(phonePkgs: phonePkgs, mode: AppProxyMode.exclude)
        .listen((pkgs) => ref.read(Preferences.excludeApps.notifier).update(pkgs));

    _timer = Timer.periodic(const Duration(days: 1), (_) async => await _autoSelectionUpdate());
    ref.onDispose(() {
      _includeSubscription?.cancel();
      _excludeSubscription?.cancel();
      _timer?.cancel();
    });
    await _autoSelectionUpdate();
  }

  Future<void> _autoSelectionUpdate() async {
    final autoRegion = ref.read(Preferences.autoAppsSelectionRegion);
    if (autoRegion == null) return;
    final mode = ref.read(Preferences.perAppProxyMode).toAppProxy();
    final lastUpdate = ref.read(Preferences.autoAppsSelectionLastUpdate);
    final days = ref.read(Preferences.autoAppsSelectionUpdateInterval).round();
    final interval = Duration(days: days);
    if (mode != null && (lastUpdate == null || DateTime.now().difference(lastUpdate) > interval)) {
      final rs = await ref.read(PerAppProxyProvider(mode).notifier).applyAutoSelection();
      if (rs) {
        final t = ref.read(translationsProvider).requireValue;
        ref
            .read(inAppNotificationControllerProvider)
            .showSuccessToast(t.pages.settings.routing.perAppProxy.autoSelection.toast.success);
      }
    }
  }
}
