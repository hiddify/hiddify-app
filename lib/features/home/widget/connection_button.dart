import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// What the button shows, one value per look.
enum _Look { loading, disconnected, connecting, connected, noPing, disconnecting, failed }

/// The core reports the tunnel as up before the first ping answers, so a tunnel
/// with no ping yet still looks like connecting: the user waits once, not twice.
/// A delay of 0 is a ping not measured yet; any other invalid delay timed out.
///
/// The status reloads after every core start; until the new stream answers,
/// the last status holds. A failed start comes back as disconnected with the
/// failure attached.
_Look _lookOf(AsyncValue<ConnectionStatus> status, int delay) => switch (status) {
  AsyncError() => _Look.failed,
  AsyncValue(valueOrNull: Disconnected(connectionFailure: _?)) => _Look.failed,
  AsyncValue(valueOrNull: Disconnected()) => _Look.disconnected,
  AsyncValue(valueOrNull: Connecting()) => _Look.connecting,
  AsyncValue(valueOrNull: Connected()) when delay == 0 => _Look.connecting,
  AsyncValue(valueOrNull: Connected()) when !ConnectionConst.isValidDelay(delay) => _Look.noPing,
  AsyncValue(valueOrNull: Connected()) => _Look.connected,
  AsyncValue(valueOrNull: Disconnecting()) => _Look.disconnecting,
  _ => _Look.loading,
};

class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final status = ref.watch(connectionNotifierProvider);
    // After a disconnect Riverpod keeps the last ping as the previous value,
    // which would show the next connection as up before its own ping answers.
    final delay = ref.watch(activeProxyNotifierProvider).unwrapPrevious().valueOrNull?.urlTestDelay ?? 0;
    final look = _lookOf(status, delay);

    // What a tap does follows the core alone: a tunnel that is up can be
    // turned off even while it still looks like connecting.
    final onTap = switch (status) {
      AsyncData(value: Disconnected()) || AsyncError() => () => _connect(ref),
      AsyncData(value: Connected()) => () => ref.read(connectionNotifierProvider.notifier).toggleConnection(),
      _ => null,
    };

    const buttonTheme = ConnectionButtonTheme.light;
    final today = DateTime.now();
    return _ConnectionButton(
      onTap: onTap,
      label: switch (look) {
        _Look.loading || _Look.failed => "",
        _Look.disconnected => t.connection.tapToConnect,
        _Look.connecting => t.connection.connecting,
        _Look.connected || _Look.noPing => t.connection.connected,
        _Look.disconnecting => t.connection.disconnecting,
      },
      buttonColor: switch (look) {
        _Look.connected => buttonTheme.connectedColor!,
        _Look.noPing => const Color.fromARGB(255, 185, 176, 103),
        _Look.failed => Colors.red,
        _ => buttonTheme.idleColor!,
      },
      image: switch (look) {
        _Look.connected || _Look.noPing => Assets.images.connectNorouz,
        _ => Assets.images.disconnectNorouz,
      },
      useImage: today.day >= 19 && today.day <= 23 && today.month == 3,
    );
  }

  /// Connects, or sends the user to add a profile when there is none.
  Future<void> _connect(WidgetRef ref) async {
    final dialogs = ref.read(dialogNotifierProvider.notifier);
    if (ref.read(activeProfileProvider).valueOrNull == null) {
      await dialogs.showNoActiveProfile();
      ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
      return;
    }
    if (await dialogs.showExperimentalFeatureNotice()) {
      await ref.read(connectionNotifierProvider.notifier).toggleConnection();
    }
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.label,
    required this.buttonColor,
    required this.image,
    required this.useImage,
  });

  final VoidCallback? onTap;
  final String label;
  final Color buttonColor;
  final AssetGenImage image;
  final bool useImage;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(blurRadius: 16, color: buttonColor.withValues(alpha: .5))],
            ),
            width: 148,
            height: 148,
            child: Material(
              key: const ValueKey("home_connection_button"),
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                focusColor: Colors.grey,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: TweenAnimationBuilder(
                    tween: ColorTween(end: buttonColor),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, value, child) {
                      if (useImage) {
                        return image.image();
                      } else {
                        return Assets.images.logo.svg(colorFilter: ColorFilter.mode(value!, BlendMode.srcIn));
                      }
                    },
                  ),
                ),
              ),
            ).animate(target: enabled ? 0 : 1).blurXY(end: 1),
          ).animate(target: enabled ? 0 : 1).scaleXY(end: .88, curve: Curves.easeIn),
        ),
        const Gap(16),
        ExcludeSemantics(child: AnimatedText(label, style: Theme.of(context).textTheme.titleMedium)),
      ],
    );
  }
}
