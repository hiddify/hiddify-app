import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;
    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;
    final buttonTheme = Theme.of(context).extension<ConnectionButtonTheme>() ?? ConnectionButtonTheme.spriteNet;

    final visualState = switch (connectionStatus) {
      AsyncData(value: Connected()) when requiresReconnect == true => _ButtonVisualState.connecting,
      AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => _ButtonVisualState.connecting,
      AsyncData(value: Connected()) => _ButtonVisualState.connected,
      AsyncData(value: Connecting()) || AsyncData(value: Disconnecting()) => _ButtonVisualState.connecting,
      AsyncData(value: Disconnected(connectionFailure: _?)) => _ButtonVisualState.error,
      AsyncError() => _ButtonVisualState.error,
      AsyncData() => _ButtonVisualState.idle,
      _ => _ButtonVisualState.connecting,
    };

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
          return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
        },
        _ => () {},
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
      visualState: visualState,
      color: switch (visualState) {
        _ButtonVisualState.idle => buttonTheme.idleColor!,
        _ButtonVisualState.connecting => buttonTheme.connectingColor!,
        _ButtonVisualState.connected => buttonTheme.connectedColor!,
        _ButtonVisualState.error => buttonTheme.errorColor!,
      },
    );
  }
}

enum _ButtonVisualState { idle, connecting, connected, error }

/// SpriteNet power button: a round button with a neon ring around the logo.
/// idle: muted ring, connecting: rotating dashed ring, connected: pulsing glowing ring, error: red ring.
class _ConnectionButton extends HookWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.visualState,
    required this.color,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final _ButtonVisualState visualState;
  final Color color;

  static const double _size = 200;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spin = useAnimationController(duration: const Duration(milliseconds: 1600));
    final pulse = useAnimationController(duration: const Duration(milliseconds: 1800));

    useEffect(() {
      if (visualState == _ButtonVisualState.connecting) {
        spin.repeat();
      } else {
        spin.stop();
      }
      if (visualState == _ButtonVisualState.connected) {
        pulse.repeat(reverse: true);
      } else {
        pulse
          ..stop()
          ..value = 0;
      }
      return null;
    }, [visualState]);

    final glowing = visualState == _ButtonVisualState.connected || visualState == _ButtonVisualState.error;
    final logoColor = switch (visualState) {
      _ButtonVisualState.connecting => color.withValues(alpha: .35),
      _ => color,
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: AnimatedBuilder(
            animation: Listenable.merge([spin, pulse]),
            builder: (context, child) {
              final pulseValue = Curves.easeInOut.transform(pulse.value);
              return Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: glowing
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: .28 + .22 * pulseValue),
                            blurRadius: 28 + 18 * pulseValue,
                            spreadRadius: 2 + 4 * pulseValue,
                          ),
                        ]
                      : null,
                ),
                child: CustomPaint(
                  painter: _RingPainter(
                    color: color,
                    dashed: visualState == _ButtonVisualState.connecting,
                    rotation: spin.value * 2 * math.pi,
                    glow: glowing,
                  ),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Material(
                key: const ValueKey("home_connection_button"),
                shape: CircleBorder(side: BorderSide(color: color.withValues(alpha: .25))),
                color: const Color(0xFF121214),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: TweenAnimationBuilder(
                      tween: ColorTween(end: logoColor),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, value, child) =>
                          Assets.images.logo.svg(colorFilter: ColorFilter.mode(value!, BlendMode.srcIn)),
                    ),
                  ),
                ),
              ),
            ),
          ).animate(target: enabled ? 0 : 1).scaleXY(end: .94, curve: Curves.easeIn),
        ),
        const Gap(20),
        ExcludeSemantics(
          child: AnimatedText(
            label.toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: visualState == _ButtonVisualState.idle ? theme.colorScheme.onSurfaceVariant : color,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color, required this.dashed, required this.rotation, required this.glow});

  final Color color;
  final bool dashed;
  final double rotation;
  final bool glow;

  static const double _strokeWidth = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _strokeWidth;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    if (glow) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: .5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth * 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    if (!dashed) {
      canvas.drawCircle(center, radius, paint);
      return;
    }
    const dashCount = 18;
    const sweep = 2 * math.pi / dashCount;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashCount; i++) {
      // Fade one dash out to suggest motion, like the "connecting" mockup.
      paint.color = color.withValues(alpha: i == 0 ? .25 : 1);
      canvas.drawArc(rect, rotation + i * sweep, sweep * .5, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashed != dashed ||
      oldDelegate.rotation != rotation ||
      oldDelegate.glow != glow;
}
