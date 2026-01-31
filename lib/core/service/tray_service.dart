import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/logger/logger.dart';
import 'package:hiddify/core/preferences/actions_at_closing.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/app_router.dart';
import 'package:hiddify/features/config/controller/config_controller.dart';
import 'package:hiddify/features/connection/logic/connection_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

part 'tray_service.g.dart';

@Riverpod(keepAlive: true)
class TrayService extends _$TrayService with TrayListener, WindowListener {
  static const _kIconIcoPath = 'assets/images/tray_icon.ico';
  static const _kIconPngPath = 'assets/images/tray_icon.png';
  static const _kIconConnectedIcoPath = 'assets/images/tray_icon_connected.ico';
  static const _kIconConnectedPngPath = 'assets/images/tray_icon_connected.png';
  static const _kIconDisconnectedIcoPath =
      'assets/images/tray_icon_disconnected.ico';
  static const _kIconDisconnectedPngPath =
      'assets/images/tray_icon_disconnected.png';

  static String _platformIconPath({
    required String windows,
    required String other,
  }) {
    return Platform.isWindows ? windows : other;
  }

  @override
  Future<void> build() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

    ref.onDispose(() {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    });

    // Listen to connection state changes to update tray icon and menu
    ref.listen(connectionProvider,
        (ConnectionStatus? previous, ConnectionStatus next) {
      unawaited(updateTrayState(next));
    });

    await init();
  }

  Future<void> init() async {
    Logger.bootstrap.info('Initializing TrayService');
    await trayManager.setIcon(
      _platformIconPath(windows: _kIconIcoPath, other: _kIconPngPath),
    );
    await _updateContextMenu(ConnectionStatus.disconnected);
    trayManager.addListener(this);
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  Future<void> updateTrayState(ConnectionStatus status) async {
    await _updateTrayIcon(status);
    await _updateContextMenu(status);
  }

  Future<void> _updateTrayIcon(ConnectionStatus status) async {
    final (windowsIconPath, otherIconPath, tooltip) = switch (status) {
      ConnectionStatus.connected => (
          _kIconConnectedIcoPath,
          _kIconConnectedPngPath,
          'Hiddify - Connected',
        ),
      ConnectionStatus.disconnected => (
          _kIconDisconnectedIcoPath,
          _kIconDisconnectedPngPath,
          'Hiddify - Disconnected',
        ),
      ConnectionStatus.connecting => (
          _kIconIcoPath,
          _kIconPngPath,
          'Hiddify - Connecting...',
        ),
      ConnectionStatus.error => (
          _kIconDisconnectedIcoPath,
          _kIconDisconnectedPngPath,
          'Hiddify - Error',
        ),
    };

    final iconPath =
        _platformIconPath(windows: windowsIconPath, other: otherIconPath);

    try {
      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip(tooltip);
    } catch (e) {
      Logger.bootstrap.warning('Failed to update tray icon: $e');
    }
  }

  Future<void> _updateContextMenu(ConnectionStatus status) async {
    final isConnected = status == ConnectionStatus.connected;
    final isConnecting = status == ConnectionStatus.connecting;

    final menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Hiddify',
        ),
        MenuItem.separator(),
        if (isConnected || isConnecting)
          MenuItem(
            key: 'disconnect',
            label: 'Disconnect',
          )
        else
          MenuItem(
            key: 'connect',
            label: 'Connect',
          ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: 'Quit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    _handleTrayMenuItemClick(menuItem);
  }

  Future<void> _handleTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        await windowManager.show();
        await windowManager.focus();
        return;
      case 'connect':
        final configs = await ref.read(configControllerProvider.future);
        if (configs.isNotEmpty) {
          final activeConfig = configs.first;
          await ref.read(connectionProvider.notifier).connect(activeConfig);
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
        return;
      case 'disconnect':
        await ref.read(connectionProvider.notifier).disconnect();
        return;
      case 'quit':
        await _quitApp();
        return;
    }
  }

  @override
  void onWindowClose() {
    _handleWindowClose();
  }

  Future<void> _handleWindowClose() async {
    final action = ref.read(Preferences.actionAtClose);
    switch (action) {
      case ActionsAtClosing.hide:
        await windowManager.hide();
        return;
      case ActionsAtClosing.exit:
        await _quitApp();
        return;
      case ActionsAtClosing.ask:
        final context = rootNavigatorKey.currentContext;
        if (context != null && context.mounted) {
          if (!await windowManager.isVisible()) {
            await windowManager.show();
          }
          await windowManager.focus();

          if (!context.mounted) return;

          final t = ref.read(translationsProvider);
          await showDialog<void>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Exit Hiddify?'),
                content: Text(t.settings.general.actionsAtClosing.askEachTime),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      windowManager.hide();
                    },
                    child: Text(t.settings.general.actionsAtClosing.hide),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _quitApp();
                    },
                    child: Text(t.settings.general.actionsAtClosing.exit),
                  ),
                ],
              );
            },
          );
        } else {
          await windowManager.hide();
        }
    }
  }

  Future<void> _quitApp() async {
    await ref.read(connectionProvider.notifier).disconnect();
    await windowManager.destroy();
    exit(0);
  }
}
