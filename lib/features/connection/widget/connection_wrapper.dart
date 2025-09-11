import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
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
    ref.listen(connectionNotifierProvider, (_, __) {});

    ref.listen(configOptionNotifierProvider, (previous, next) async {
      if (next case AsyncData(value: true)) {
        final t = ref.read(translationsProvider);
        ref.watch(inAppNotificationControllerProvider).showInfoToast(
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

  @override
  void initState() {
    super.initState();
    // remove for now...
    //
    // Future.delayed(const Duration(seconds: 2)).then(
    //   (_) async {
    //     if (ref.read(startedByUserProvider) && PlatformUtils.isDesktop) {
    //       loggy.debug("previously started by user, trying to connect");
    //       return ref.read(connectionNotifierProvider.notifier).mayConnect();
    //     }
    //   },
    // );
  }
}
