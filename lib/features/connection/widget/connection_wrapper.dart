import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConnectionWrapper extends StatefulHookConsumerWidget {
  const ConnectionWrapper(this.child, {super.key});

  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ConnectionWrapperState();
}

class _ConnectionWrapperState extends ConsumerState<ConnectionWrapper> with AppLogger {
  @override
  Widget build(BuildContext context) {
    ref.listen(connectionNotifierProvider, (previous, next) async {
      // a big profile that connected: ask once whether only its fastest proxies run
      if (next case AsyncData(value: Connected()) when previous?.valueOrNull is! Connected) {
        await ref.read(keepTopNotifierProvider.notifier).askIfBig(await ref.read(activeProfileProvider.future));
      }
    });
    // proxy mode routes nothing by itself: when the user picks it, how apps are pointed at it
    ref.listen(ConfigOptions.serviceMode, (previous, next) async {
      if (previous != next && next == ServiceMode.proxy && !ref.read(ConfigOptions.hideLocalProxyOnPick)) {
        await ref.read(dialogNotifierProvider.notifier).showLocalProxy(onPick: true);
      }
    });
    // a profile added, or chosen; not the one loaded at start, nothing was asked of the user yet
    ref.listen(activeProfileProvider, (previous, next) async {
      if (previous == null || previous.isLoading) return;
      if (next.valueOrNull case final profile? when profile.id != previous.valueOrNull?.id) {
        await ref.read(keepTopNotifierProvider.notifier).askIfBig(profile);
      }
    });

    ref.listen(configOptionNotifierProvider, (previous, next) async {
      if (next case AsyncData(value: true)) {
        final t = ref.read(translationsProvider).requireValue;
        ref
            .read(inAppNotificationControllerProvider)
            .showInfoToast(
              t.connection.reconnectMsg,
              // actionText: t.connection.reconnect,
              // callback: () async {
              //   await ref
              //       .read(connectionNotifierProvider.notifier)
              //       .reconnect(await ref.read(activeProfileProvider.future));
              // },
            );
        await ref.read(connectionNotifierProvider.notifier).reconnect(await ref.read(activeProfileProvider.future));
      }
    });

    return widget.child;
  }
}
