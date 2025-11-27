// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/connection/widget/experimental_feature_notice.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/utils/alerts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef AsyncCallback = Future<void> Function();

class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    // ----- Providers -----
    final connectionStatus = ref.watch(connectionProvider);
    final delay = ref.watch(
      activeProxyProvider.select(
        (value) => value.asData?.value.urlTestDelay ?? 0,
      ),
    );
    final requiresReconnect = ref.watch(
      configOptionProvider.select((value) => value.asData?.value ?? false),
    );

    // ----- Error / failure pop-ups -----
    ref.listen(connectionProvider, (_, next) {
      switch (next) {
        case AsyncError(:final error):
          CustomAlertDialog.fromErr(t.presentError(error)).show(context);
        case AsyncData(value: Disconnected(:final connectionFailure?)):
          CustomAlertDialog.fromErr(
            t.presentError(connectionFailure),
          ).show(context);
        default:
      }
    });

    // ----- Helpers -----
    final btnTheme = Theme.of(context).extension<ConnectionButtonTheme>()!;
    final today = DateTime.now();

    Future<bool> showExperimentalNotice() async {
      final hasExperimental = ref.read(hasExperimentalFeaturesProvider);
      final canShowNotice = !ref.read(disableExperimentalFeatureNoticeProvider);
      if (hasExperimental && canShowNotice) {
        return (await const ExperimentalFeatureNoticeDialog().show(context)) ??
            false;
      }
      return true;
    }

    // ----- Determine state-specific values -----
    final (AsyncCallback? onTap, bool enabled) = switch (connectionStatus) {
      AsyncData(value: Disconnected()) || AsyncError() => (
        () async {
          if (await showExperimentalNotice()) {
            await ref.read(connectionProvider.notifier).toggleConnection();
          }
        },
        true,
      ),
      AsyncData(value: Connected()) => (
        () async {
          if (requiresReconnect && await showExperimentalNotice()) {
            await ref
                .read(connectionProvider.notifier)
                .reconnect(await ref.read(activeProfileProvider.future));
          } else {
            await ref.read(connectionProvider.notifier).toggleConnection();
          }
        },
        true,
      ),
      _ => (null, false),
    };

    final String label = switch (connectionStatus) {
      AsyncData(value: Connected()) when requiresReconnect =>
        t.connection.reconnect,
      AsyncData(value: Connected()) when delay <= 0 || delay >= 65 * 1000 =>
        t.connection.connecting,
      AsyncData(value: final status) => status.present(t),
      _ => '',
    };

    final Color btnColor = switch (connectionStatus) {
      AsyncData(value: Connected()) when requiresReconnect => Colors.teal,
      AsyncData(value: Connected()) when delay <= 0 || delay >= 65 * 1000 =>
        const Color(0xFFB9B067),
      AsyncData(value: Connected()) => btnTheme.connectedColor!,
      AsyncError() => Colors.red,
      _ => btnTheme.idleColor!,
    };

    final AssetGenImage iconImg = switch (connectionStatus) {
      AsyncData(value: Connected()) => Assets.images.connectNorouz,
      _ => Assets.images.disconnectNorouz,
    };

    final bool showNowruz =
        today.month == 3 && today.day >= 19 && today.day <= 23;

    // ----- UI -----
    return _ConnectionButton(
      enabled: enabled,
      onTap: onTap,
      label: label,
      buttonColor: btnColor,
      image: iconImg,
      useImage: showNowruz,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//                           Internal presentation widget
// ──────────────────────────────────────────────────────────────────────────────
class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.buttonColor,
    required this.image,
    required this.useImage,
  });

  final AsyncCallback? onTap;
  final bool enabled;
  final String label;
  final Color buttonColor;
  final AssetGenImage image;
  final bool useImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          value: label,
          child:
              Container(
                    width: 148,
                    height: 148,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        // withOpacity() → withAlpha() to avoid deprecation warning
                        BoxShadow(
                          blurRadius: 16,
                          color: buttonColor.withAlpha((0.5 * 255).round()),
                        ),
                      ],
                    ),
                    child: Material(
                      key: const ValueKey('home_connection_button'),
                      shape: const CircleBorder(),
                      color: Colors.white,
                      child: InkWell(
                        onTap: enabled
                            ? () {
                                // ignore the returned Future
                                unawaited(onTap?.call());
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(36),
                          child: TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: buttonColor),
                            duration: const Duration(milliseconds: 250),
                            builder: (_, value, _) {
                              return useImage
                                  ? image.image()
                                  : Assets.images.logo.svg(
                                      colorFilter: ColorFilter.mode(
                                        value ?? buttonColor,
                                        BlendMode.srcIn,
                                      ),
                                    );
                            },
                          ),
                        ),
                      ),
                    ).animate(target: enabled ? 0 : 1).blurXY(end: 1),
                  )
                  .animate(target: enabled ? 0 : 1)
                  .scaleXY(end: .88, curve: Curves.easeIn),
        ),
        const Gap(16),
        ExcludeSemantics(
          child: AnimatedText(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
