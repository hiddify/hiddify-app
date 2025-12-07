import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/window/notifier/window_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

part 'system_tray_notifier.g.dart';

@Riverpod(keepAlive: true)
class SystemTrayNotifier extends _$SystemTrayNotifier
    with AppLogger, TrayListener {
  @override
  Future<void> build() async {
    if (!PlatformUtils.isDesktop) return;

    trayManager.addListener(this);
    ref.onDispose(() => trayManager.removeListener(this));

    // Watch dependencies for MENU only
    final connectionAsync = ref.watch(connectionProvider);
    final connection =
        connectionAsync.asData?.value ?? const ConnectionStatus.disconnected();
    final serviceMode = ref.watch(ConfigOptions.serviceMode);
    final t = ref.watch(translationsProvider);

    // Listen to activeProxy for Tooltip/Icon updates without rebuilding the menu
    ref.listen(activeProxyProvider, (previous, next) {
      final delay = switch (next) {
        AsyncData(value: final proxy) => proxy.urlTestDelay,
        _ => 0,
      };
      _updateTrayIconAndTooltip(connection, delay, t);
    });

    // Initial update for icon/tooltip
    final activeProxy = ref.read(activeProxyProvider);
    final delay = switch (activeProxy) {
      AsyncData(value: final proxy) => proxy.urlTestDelay,
      _ => 0,
    };
    _updateTrayIconAndTooltip(connection, delay, t);

    // Build Menu
    final menu = Menu(
      items: [
        MenuItem(
          label: t.tray.dashboard,
          onClick: (_) async {
            await ref.read(windowProvider.notifier).open();
          },
        ),
        MenuItem.separator(),
        MenuItem.checkbox(
          label: switch (connection) {
            Disconnected() => t.tray.status.connect,
            Connecting() => t.tray.status.connecting,
            Connected() => t.tray.status.disconnect,
            Disconnecting() => t.tray.status.disconnecting,
          },
          checked: false,
          disabled: connection.isSwitching,
          onClick: (_) async {
            await ref.read(connectionProvider.notifier).toggleConnection();
          },
        ),
        MenuItem.separator(),
        MenuItem(
          label: t.config.serviceMode,
          icon: Assets.images.trayIconIco,
          disabled: true,
        ),

        ...ServiceMode.values.map(
          (e) => MenuItem.checkbox(
            checked: e == serviceMode,
            key: e.name,
            label: e.present(t),
            onClick: (menuItem) async {
              final newMode = ServiceMode.values.byName(menuItem.key!);
              loggy.debug("switching service mode: [$newMode]");
              await ref
                  .read(ConfigOptions.serviceMode.notifier)
                  .update(newMode);
            },
          ),
        ),
        MenuItem.separator(),
        MenuItem(
          label: t.tray.quit,
          onClick: (_) async {
            await ref.read(windowProvider.notifier).quit();
          },
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  Future<void> _updateTrayIconAndTooltip(
    ConnectionStatus connection,
    int delay,
    TranslationsEn t,
  ) async {
    final newConnectionStatus = delay > 0 && delay < 65000;
    var tooltip = Constants.appName;

    if (connection == const Disconnected()) {
      setIcon(connection);
    } else if (connection == const Connected()) {
      setIcon(const Connected());
      tooltip = "$tooltip - ${connection.present(t)}";
      if (newConnectionStatus) {
        tooltip = "$tooltip : ${delay}ms";
      } else {
        tooltip = "$tooltip : -";
      }
    } else {
      setIcon(const Disconnecting()); // Use Disconnecting icon for intermediate states
      tooltip = "$tooltip - ${connection.present(t)}";
    }

    if (Platform.isMacOS) {
      windowManager.setBadgeLabel("${delay}ms");
    }
    if (!Platform.isLinux) await trayManager.setToolTip(tooltip);
  }

  static void setIcon(ConnectionStatus status) {
    if (!PlatformUtils.isDesktop) return;
    trayManager
        .setIcon(_trayIconPath(status), isTemplate: Platform.isMacOS)
        .asStream();
  }

  static String _trayIconPath(ConnectionStatus status) {
    if (Platform.isWindows) {
      final Brightness brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final isDarkMode = brightness == Brightness.dark;
      switch (status) {
        case Connected():
          return Assets.images.trayIconConnectedIco;
        case Connecting():
          return Assets.images.trayIconDisconnectedIco;
        case Disconnecting():
          return Assets.images.trayIconDisconnectedIco;
        case Disconnected():
          if (isDarkMode) {
            return Assets.images.trayIconIco;
          } else {
            return Assets.images.trayIconDarkIco;
          }
      }
    }
    switch (status) {
      case Connected():
        return Assets.images.trayIconConnectedPng.path;
      case Connecting():
        return Assets.images.trayIconDisconnectedPng.path;
      case Disconnecting():
        return Assets.images.trayIconDisconnectedPng.path;
      case Disconnected():
        return Assets.images.trayIconPng.path;
    }
  }

  @override
  void onTrayIconMouseDown() {
    ref.read(windowProvider.notifier).open();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }
}
