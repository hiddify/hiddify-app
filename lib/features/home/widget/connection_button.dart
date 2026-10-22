import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/router/dialog/widgets/custom_alert_dialog.dart';
import 'package:hiddify/core/theme/blizzard_tokens.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_glass.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_presentation.dart';
import 'package:hiddify/core/widget/blizzard/blizzard_scene.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/diagnostics/home_presentation_probe.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// TODO: rewrite
class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;

    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;
    final today = DateTime.now();
    // final animationController = useAnimationController(
    //   duration: const Duration(seconds: 1),
    // )..repeat(reverse: true); // Ensure the animation loops indefinitely

    //   // Listen to the animation's value
    //   final animationValue = useAnimation(Tween<double>(begin: 0.8, end: 1).animate(animationController));

    //   // useEffect(() {
    //   //   if (true) {
    //   // Start repeating animation
    //   //   } else {
    //   //     animationController.stop(); // Stop animation if connected, disconnected, or error
    //   //   }

    //   //   // Cleanup when widget is disposed
    //   //   return animationController.dispose;
    //   // }, [connectionStatus.value]);

    //   // ref.listen(
    //   //   connectionNotifierProvider,
    //   //   (_, next) {
    //   //     if (next case AsyncError(:final error)) {
    //   //       CustomAlertDialog.fromErr(t.presentError(error)).show(context);
    //   //     }
    //   //     if (next case AsyncData(value: Disconnected(:final connectionFailure?))) {
    //   //       CustomAlertDialog.fromErr(t.presentError(connectionFailure)).show(context);
    //   //     }
    //   //   },
    //   // );

    const buttonTheme = ConnectionButtonTheme.light;

    //   // return CircleDesignWidget(
    //   //   onTap: switch (connectionStatus) {
    //   //     // AsyncData(value: Disconnected()) || AsyncError() => () async {
    //   //     //     if (await showExperimentalNotice()) {
    //   //     //       return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    //   //     //     }
    //   //     //   },
    //   //     // AsyncData(value: Connected()) => () async {
    //   //     //     if (requiresReconnect == true && await showExperimentalNotice()) {
    //   //     //       return await ref.read(connectionNotifierProvider.notifier).reconnect(await ref.read(activeProfileProvider.future));
    //   //     //     }
    //   //     //     return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    //   //     //   },
    //   //     _ => () {},
    //   //   },
    //   //   // enabled: switch (connectionStatus) {
    //   //   //   AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
    //   //   //   _ => false,
    //   //   // },
    //   //   // label: switch (connectionStatus) {
    //   //   //   AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
    //   //   //   AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
    //   //   //   AsyncData(value: final status) => status.present(t),
    //   //   //   _ => "",
    //   //   // },
    //   //   color: switch (connectionStatus) {
    //   //     AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
    //   //     AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => Color.fromARGB(255, 157, 139, 1),
    //   //     AsyncData(value: Connected()) => Colors.green.shade900,
    //   //     AsyncData(value: _) => Colors.indigo.shade700, // Color(0xFF3446A5), //buttonTheme.idleColor!,
    //   //     _ => Colors.red,
    //   //   },

    //   //   animated: true ||
    //   //       switch (connectionStatus) {
    //   //         AsyncData(value: Connected()) when requiresReconnect == true => false,
    //   //         AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => false,
    //   //         AsyncData(value: Connected()) => true,
    //   //         AsyncData(value: _) => true,
    //   //         _ => false,
    //   //       },
    //   //   animationValue: animationValue,
    //   // );
    // }
    var secureLabel =
        (ref.watch(ConfigOptions.enableWarp) && ref.watch(ConfigOptions.warpDetourMode) == WarpDetourMode.warpOverProxy)
        ? t.connection.secure
        : "";
    if (delay <= 0 || delay > 65000 || connectionStatus.valueOrNull != const Connected()) {
      secureLabel = "";
    }
    final label =
        Theme.of(context).platform == TargetPlatform.iOS &&
            connectionStatus.asData?.value is Connected &&
            requiresReconnect != true
        ? t.connection.connected
        : switch (connectionStatus) {
            AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
            AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
            AsyncData(value: final status) => status.present(t),
            _ => "",
          };
    final actionLabel = switch (connectionStatus) {
      AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
      AsyncData(value: Connected()) => t.connection.disconnect,
      AsyncData(value: Disconnected()) || AsyncError() => t.connection.connect,
      AsyncData(value: final status) => status.present(t),
      _ => '',
    };
    final button = _ConnectionButton(
      onTap: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => () async {
          final activeProfile = await ref.read(activeProfileProvider.future);
          return await ref.read(connectionNotifierProvider.notifier).reconnect(activeProfile);
        },
        AsyncData(value: Disconnected()) || AsyncError() => () async {
          if (ref.read(activeProfileProvider).valueOrNull == null) {
            await ref.read(dialogNotifierProvider.notifier).showNoActiveProfile();
            ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
          }
          if (await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
            return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
          }
        },
        AsyncData(value: Connected()) => () async {
          if (requiresReconnect == true &&
              await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
            return await ref
                .read(connectionNotifierProvider.notifier)
                .reconnect(await ref.read(activeProfileProvider.future));
          }
          return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
        },
        _ => () {},
      },
      enabled: switch (connectionStatus) {
        AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
        _ => false,
      },
      label: label,
      actionLabel: actionLabel,
      buttonColor: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => const Color.fromARGB(255, 185, 176, 103),
        AsyncData(value: Connected()) => buttonTheme.connectedColor!,
        AsyncData(value: _) => buttonTheme.idleColor!,
        _ => Colors.red,
      },
      image: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Assets.images.disconnectNorouz,
        AsyncData(value: Connected()) => Assets.images.connectNorouz,
        AsyncData(value: _) => Assets.images.disconnectNorouz,
        _ => Assets.images.disconnectNorouz,
        AsyncData(value: Disconnected()) || AsyncError() => Assets.images.disconnectNorouz,
        AsyncData(value: Connected()) => Assets.images.connectNorouz,
        _ => Assets.images.disconnectNorouz,
      },
      newButtonColor: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => const Color.fromARGB(255, 185, 176, 103),
        AsyncData(value: Connected()) => buttonTheme.connectedColor!,
        AsyncData(value: _) => buttonTheme.idleColor!,
        _ => Colors.red,
      },
      animated: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => false,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => false,
        AsyncData(value: Connected()) => true,
        AsyncData(value: _) => true,
        _ => false,
      },
      useImage: today.day >= 19 && today.day <= 23 && today.month == 3,
      secureLabel: secureLabel,
    );
    return HomePresentationProbe(
      connectionStatus: connectionStatus,
      label: label,
      translations: t,
      requiresReconnect: requiresReconnect,
      delay: delay,
      themePlatform: Theme.of(context).platform,
      tickersEnabled: TickerMode.of(context),
      child: BlizzardPresentation.isActive(context)
          ? _BlizzardConnectionHero(
              statusLabel: label,
              actionLabel: actionLabel,
              secureLabel: secureLabel,
              control: button,
            )
          : button,
    );
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.actionLabel,
    required this.buttonColor,
    required this.image,
    required this.useImage,
    required this.newButtonColor,
    required this.animated,
    required this.secureLabel,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final String actionLabel;
  final Color buttonColor;
  final AssetGenImage image;
  final bool useImage;
  final String secureLabel;

  final Color newButtonColor;

  final bool animated;

  @override
  Widget build(BuildContext context) {
    final blizzard = BlizzardPresentation.isActive(context);
    final media = MediaQuery.of(context);
    final reduceMotion = blizzard && (media.disableAnimations || media.accessibleNavigation);
    final materials = BlizzardMaterials(highContrast: media.highContrast);
    final control = Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child:
              Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: blizzard ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: blizzard ? BorderRadius.circular(BlizzardRadii.connection) : null,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: blizzard ? 36 : 16,
                          color: blizzard ? BlizzardPalette.connectionHalo : buttonColor.withValues(alpha: .5),
                        ),
                      ],
                    ),
                    width: 148,
                    height: 148,
                    child: BlizzardGlass(
                      active: blizzard,
                      radius: BlizzardRadii.connection,
                      lens: true,
                      child: Material(
                        key: const ValueKey("home_connection_button"),
                        shape: blizzard
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(BlizzardRadii.connection),
                                side: BorderSide(color: media.highContrast ? materials.edge : Colors.transparent),
                              )
                            : const CircleBorder(),
                        color: blizzard ? Colors.transparent : Colors.white,
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: blizzard ? BorderRadius.circular(BlizzardRadii.connection) : null,
                          ),
                          child: InkWell(
                            focusColor: Colors.grey,
                            onTap: onTap,
                            child: Padding(
                              padding: const EdgeInsets.all(36),
                              child: TweenAnimationBuilder(
                                tween: ColorTween(end: buttonColor),
                                duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
                                builder: (context, value, child) {
                                  if (useImage) {
                                    return image.image();
                                  } else {
                                    return Assets.images.logo.svg(
                                      colorFilter: ColorFilter.mode(
                                        blizzard ? BlizzardPalette.accent : value!,
                                        BlendMode.srcIn,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ).animate(target: enabled ? 0 : 1).blurXY(end: 1, duration: reduceMotion ? Duration.zero : null),
                    ),
                  )
                  .animate(target: enabled ? 0 : 1)
                  .scaleXY(end: .88, curve: Curves.easeIn, duration: reduceMotion ? Duration.zero : null),
        );
    if (blizzard) return control;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        control,
        const Gap(16),
        ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (Theme.of(context).platform == TargetPlatform.iOS)
                Text(actionLabel, style: Theme.of(context).textTheme.titleMedium)
              else
                AnimatedText(
                  actionLabel,
                  duration: reduceMotion ? Duration.zero : kAnimationDuration,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (secureLabel.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const Gap(8),
                    Icon(FontAwesomeIcons.shieldHalved, size: 16, color: Theme.of(context).colorScheme.secondary),
                    const Gap(4),
                    Text(
                      secureLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BlizzardConnectionHero extends StatelessWidget {
  const _BlizzardConnectionHero({
    required this.statusLabel,
    required this.actionLabel,
    required this.secureLabel,
    required this.control,
  });

  final String statusLabel;
  final String actionLabel;
  final String secureLabel;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0, BlizzardMetrics.waveSize.width).toDouble();
        return SizedBox(
          width: width,
          height: 336,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
          Positioned(
            top: 0,
            left: 0,
            child: SizedBox(
              key: const ValueKey('blizzard_home_status_slot'),
              width: width,
              height: BlizzardMetrics.connectionStatusHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    statusLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Flexible(child: ActiveProxyDelayIndicator()),
                        if (secureLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(FontAwesomeIcons.shieldHalved, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              secureLabel,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: BlizzardMetrics.waveTopFromStatus,
            left: 0,
            child: SizedBox.fromSize(
              key: const ValueKey('blizzard_home_wave_envelope'),
              size: Size(width, BlizzardMetrics.waveSize.height),
              child: const BlizzardScene(preset: BlizzardParticlePreset.hero),
            ),
          ),
          Positioned(
            top: BlizzardMetrics.controlTopFromStatus,
            left: 0,
            child: SizedBox(
              key: const ValueKey('blizzard_home_control_group'),
              width: width,
              height: BlizzardMetrics.connectionControlGroupHeight,
              child: Column(
                children: [
                  const SizedBox(height: 23),
                  SizedBox.square(dimension: BlizzardMetrics.connectionButton, child: control),
                  const SizedBox(height: BlizzardMetrics.connectionLabelGap),
                  SizedBox(
                    height: 22,
                    child: Text(
                      actionLabel,
                      key: const ValueKey('blizzard_home_action_label'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        );
      },
    );
  }
}
