import 'dart:io';

import 'package:flutter/material.dart';
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
class SystemTrayNotifier extends _$SystemTrayNotifier with AppLogger {
  @override
  Future<void> build() async {
    if (!PlatformUtils.isDesktop) return;

    try {
      final activeProxy = ref.watch(activeProxyNotifierProvider);
      final delay = activeProxy.value?.urlTestDelayInt ?? 0; // Use Int version
      final newConnectionStatus = delay > 0 && delay < 65000;
      
      ConnectionStatus connection;
      try {
        connection = await ref.watch(connectionNotifierProvider.future);
      } catch (e) {
        loggy.warning("error getting connection status", e);
        connection = const ConnectionStatus.disconnected();
      }

      // Safe translation access with timeout and fallback
      Translations t;
      try {
        // Use a timeout to prevent hanging
        final translationsFuture = Future.value(ref.read(translationsProvider));
        t = await translationsFuture.timeout(const Duration(milliseconds: 500));
      } catch (e) {
        loggy.warning("Translation provider failed, using English fallback", e);
        // Use English fallback directly
        t = AppLocale.en.buildSync();
      }

      var tooltip = Constants.appName;
      ref.watch(ConfigOptions.serviceMode);
      
      if (connection == const Disconnected()) {
        setIcon(connection);
      } else if (newConnectionStatus) {
        setIcon(const Connected());
        tooltip = "$tooltip - ${connection.present(t)}";
        if (newConnectionStatus) {
          tooltip = "$tooltip : ${delay}ms";
        } else {
          tooltip = "$tooltip : -";
        }
      } else {
        setIcon(const Disconnecting());
        tooltip = "$tooltip - ${connection.present(t)}";
      }
      
      if (Platform.isMacOS) {
        try {
          windowManager.setBadgeLabel("${delay}ms");
        } catch (e) {
          loggy.warning("Failed to set badge label", e);
        }
      }
      
      if (!Platform.isLinux) {
        try {
          await trayManager.setToolTip(tooltip);
        } catch (e) {
          loggy.warning("Failed to set tooltip", e);
        }
      }

      await _buildMenu();
    } catch (e) {
      loggy.error("System tray initialization failed", e);
      // Don't rethrow - let the system continue without tray
    }
  }

  static void setIcon(ConnectionStatus status) {
    if (!PlatformUtils.isDesktop) return;
    trayManager
        .setIcon(
          _trayIconPath(status),
          isTemplate: Platform.isMacOS,
        )
        .asStream();
  }

  static String _trayIconPath(ConnectionStatus status) {
    if (Platform.isWindows) {
      final Brightness brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
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
    // return Assets.images.trayIconPng.path;
  }

  // Remove unused variables and add proper app exit
  Future<void> _buildMenu() async {
    final t = ref.read(translationsProvider);
    final connection = ref.read(connectionNotifierProvider).asData?.value ?? const Disconnected();
    final serviceMode = ref.watch(ConfigOptions.serviceMode);

    final menu = Menu(
      items: [
        MenuItem(
          label: t.tray.dashboard,
          onClick: (_) async {
            await ref.read(windowNotifierProvider.notifier).open();
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
          checked: connection.isConnected,
          disabled: connection.isSwitching,
          onClick: (_) async {
            await ref.read(connectionNotifierProvider.notifier).toggleConnection();
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
              await ref.read(ConfigOptions.serviceMode.notifier).update(newMode);
            },
          ),
        ),
        MenuItem.separator(),
        MenuItem(
          label: t.tray.quit,
          onClick: (_) async {
            return ref.read(windowNotifierProvider.notifier).quit();
          },
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }
}
