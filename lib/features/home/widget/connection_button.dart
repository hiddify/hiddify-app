import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/cat/cat_theme.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/core/widget/cat/cat_face.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
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
    final hotReloading = ref.watch(hotReloadingProvider).valueOrNull ?? false;
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
    // var secureLabel =
    //     (ref.watch(ConfigOptions.enableWarp) && ref.watch(ConfigOptions.warpDetourMode) == WarpDetourMode.warpOverProxy)
    //     ? t.connection.secure
    //     : "";
    var secureLabel = '';
    if (!ConnectionConst.isValidDelay(delay) || connectionStatus.value != const Connected()) {
      secureLabel = "";
    }
    return _ConnectionButton(
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
        AsyncData(value: Connected()) when hotReloading => false,
        AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
        _ => false,
      },
      label: switch (connectionStatus) {
        AsyncData(value: Connected()) when hotReloading => t.connection.hotReloading,
        AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
        AsyncData(value: Connected()) when !ConnectionConst.isValidDelay(delay) => t.connection.connecting,
        AsyncData(value: final status) => status.present(t),
        _ => "",
      },
      mood: switch (connectionStatus) {
        AsyncData(value: Connected()) when hotReloading => CatMood.grooming,
        AsyncData(value: Connected()) when requiresReconnect == true => CatMood.curious,
        AsyncData(value: Connected()) when !ConnectionConst.isValidDelay(delay) => CatMood.wakingUp,
        AsyncData(value: Connected()) => CatMood.purring,
        AsyncData(value: Connecting()) => CatMood.wakingUp,
        AsyncData(value: Disconnecting()) => CatMood.dozingOff,
        AsyncData(value: Disconnected(connectionFailure: _?)) || AsyncError() => CatMood.hissing,
        _ => CatMood.napping,
      },
      secureLabel: secureLabel,
    );
  }
}

/// The home cat: asleep while disconnected, waking up while connecting,
/// purring once connected, hissing on failure. Tap it to connect or
/// disconnect; long-press it to pet it.
class _ConnectionButton extends HookConsumerWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.mood,
    required this.secureLabel,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final CatMood mood;
  final String secureLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final cat = CatTheme.of(context);
    final face = useMemoized(GlobalKey<CatFaceState>.new);
    final aura = switch (mood) {
      CatMood.purring => cat.auraConnected,
      CatMood.hissing => cat.auraError,
      CatMood.curious => cat.auraCurious,
      CatMood.napping => cat.auraIdle,
      CatMood.wakingUp || CatMood.dozingOff || CatMood.grooming => cat.auraBusy,
    };
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: AnimatedScale(
            scale: enabled ? 1 : .94,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Material(
              key: const ValueKey("home_connection_button"),
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: aura.withValues(alpha: .18),
                highlightColor: aura.withValues(alpha: .08),
                hoverColor: aura.withValues(alpha: .06),
                focusColor: aura.withValues(alpha: .24),
                onTap: () {
                  face.currentState?.boop();
                  onTap();
                },
                child: CatFace(
                  key: face,
                  mood: mood,
                  size: 196,
                  aura: aura,
                  collar: aura,
                  followPointer: true,
                  pettable: true,
                  onPurr: ref.read(hapticServiceProvider.notifier).lightImpact,
                ),
              ),
            ),
          ),
        ),
        const Gap(8),
        ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedText(label, style: theme.textTheme.titleMedium),
              const Gap(2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets_rounded, size: 12, color: muted?.color),
                  const Gap(6),
                  AnimatedText(mood.present(t), style: muted),
                  const Gap(6),
                  Icon(Icons.pets_rounded, size: 12, color: muted?.color),
                ],
              ),
              if (secureLabel.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const Gap(8),
                    Icon(FontAwesomeIcons.shieldCat, size: 16, color: theme.colorScheme.secondary),
                    const Gap(4),
                    Text(secureLabel, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary)),
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

extension on CatMood {
  String present(TranslationsEn t) => switch (this) {
    CatMood.napping => t.cat.mood.napping,
    CatMood.wakingUp => t.cat.mood.wakingUp,
    CatMood.purring => t.cat.mood.purring,
    CatMood.dozingOff => t.cat.mood.dozingOff,
    CatMood.hissing => t.cat.mood.hissing,
    CatMood.curious => t.cat.mood.curious,
    CatMood.grooming => t.cat.mood.grooming,
  };
}
