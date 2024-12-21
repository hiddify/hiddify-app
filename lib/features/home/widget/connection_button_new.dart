import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/connection/widget/experimental_feature_notice.dart';
import 'package:hiddify/features/home/widget/new_con_button.dart';
// import 'package:hiddify/features/home/widget/new_connection_button.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/utils/alerts.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loggy/loggy.dart';

class ConnectionButton extends ConsumerStatefulWidget {
  const ConnectionButton({Key? key}) : super(key: key);

  @override
  _ConnectionButtonState createState() => _ConnectionButtonState();
}

class _ConnectionButtonState extends ConsumerState<ConnectionButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;

    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;
    final today = DateTime.now();

    ref.listen(
      connectionNotifierProvider,
      (_, next) {
        if (next case AsyncError(:final error)) {
          CustomAlertDialog.fromErr(t.presentError(error)).show(context);
        }
        if (next case AsyncData(value: Disconnected(:final connectionFailure?))) {
          CustomAlertDialog.fromErr(t.presentError(connectionFailure)).show(context);
        }
      },
    );

    final buttonTheme = ConnectionButtonTheme.light;

    Future<bool> showExperimentalNotice() async {
      final hasExperimental = ref.read(ConfigOptions.hasExperimentalFeatures);
      final canShowNotice = !ref.read(disableExperimentalFeatureNoticeProvider);
      if (hasExperimental && canShowNotice && context.mounted) {
        return await const ExperimentalFeatureNoticeDialog().show(context) ?? false;
      }
      return true;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CircleDesignWidget(
          animationValue: switch (connectionStatus) {
            AsyncData(value: Connected()) when requiresReconnect != true => _animation.value,
            _ => 1,
          },
          onTap: () async {
            if (ref.read(activeProfileProvider).value == null) {
              await showDialog<bool>(
                context: context,
                builder: (context) => PlatformAlertDialog(
                  title: Text(t.home.noActiveProfileMsg),
                  content: Text(t.home.emptyProfilesMsg.text),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await UriUtils.tryLaunch(
                          Uri.parse(t.home.emptyProfilesMsg.buttonHelp.url),
                        );
                      },
                      child: Text(t.home.emptyProfilesMsg.buttonHelp.label),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(t.home.ok),
                    )
                  ],
                ),
              );
              return await AddProfileRoute().push(context);
            }
            ;
            // return await showNewConnectionButton(context, ref);
            switch (connectionStatus) {
              case AsyncData(value: Disconnected()) || AsyncError():
                {
                  if (await showExperimentalNotice()) {
                    return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
                  }
                }
              case AsyncData(value: Connected()):
                {
                  if (requiresReconnect == true && await showExperimentalNotice()) {
                    return await ref.read(connectionNotifierProvider.notifier).reconnect(await ref.read(activeProfileProvider.future));
                  }
                  return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
                }
              case _:
                {
                  // logger.warning("switching status, debounce");
                }
              // _ => () {}
            }
          },
          color: switch (connectionStatus) {
            AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
            AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => Color.fromARGB(255, 157, 139, 1),
            AsyncData(value: Connected()) => Colors.green.shade900,
            AsyncData(value: _) => Colors.indigo.shade700, // Color(0xFF3446A5), //buttonTheme.idleColor!,
            _ => Colors.red,
          },
          enabled: switch (connectionStatus) {
            AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
            _ => false,
          },
          label: switch (connectionStatus) {
            AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
            AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
            AsyncData(value: final status) => status.present(t),
            _ => "",
          },
        );
      },
    );
  }
}
