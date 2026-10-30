import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChainModeIcon extends HookConsumerWidget {
  const ChainModeIcon({super.key, required this.mode, this.size = 16});

  final ChainMode mode;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Icon(mode.icon(), color: mode.color(), size: size);
  }
}

/// A chain type's icon, as on the home proxy card: extra security's shield with an orbiting light,
/// unblocker's turning key. Still and grey while [animate] is false.
class ChainTypeIcon extends StatelessWidget {
  const ChainTypeIcon({super.key, required this.type, required this.mode, this.animate = true});

  final ChainType type;
  final ChainMode mode;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final (main, accent) = type.colors(mode);
    final still = Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox.square(
      dimension: 22,
      child: switch (type) {
        ChainType.extraSecurity =>
          animate ? _OrbitShield(main, accent) : Icon(Icons.shield_rounded, size: 17, color: still),
        ChainType.unblocker => animate ? _TurningKey(main, accent) : Icon(Icons.key_rounded, size: 18, color: still),
      },
    );
  }
}

/// Extra security: a light orbits the shield on a tilted path, with a short comet tail. It passes
/// behind the shield (dimmer, smaller) and in front of it, and the shield glints as it crosses.
class _OrbitShield extends StatelessWidget {
  const _OrbitShield(this.main, this.light);
  final Color main;
  final Color light;

  @override
  Widget build(BuildContext context) => Animate(
    onPlay: (c) => c.repeat(),
    effects: [
      CustomEffect(
        duration: 2400.ms,
        builder: (context, v, child) {
          Widget dot(double lag, {required bool front}) {
            final angle = (v - lag) * 2 * pi;
            final depth = sin(angle); // > 0: in front of the shield
            if ((depth > 0) != front) return const SizedBox.shrink();
            final fade = 1 - lag * 3.2;
            final size = (lag == 0 ? 4.5 : 3.2 - lag * 6) * (front ? 1 : .75);
            return Transform.translate(
              offset: Offset(cos(angle) * 10, depth * 3.5),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: light.withValues(alpha: (front ? 1 : .45) * fade),
                  boxShadow: lag == 0 ? [BoxShadow(color: light.withValues(alpha: front ? .9 : .4), blurRadius: 5)] : null,
                ),
              ),
            );
          }

          // the glint: strongest when the light crosses in front of the shield's middle
          final glint = pow(max(0.0, cos((v - .25) * 2 * pi)), 6).toDouble();
          const lags = [.24, .16, .08, 0.0];
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final lag in lags) dot(lag, front: false),
              Icon(Icons.shield_rounded, size: 17, color: Color.lerp(main, Colors.white, glint * .55)),
              for (final lag in lags) dot(lag, front: true),
            ],
          );
        },
      ),
    ],
    child: const SizedBox.square(dimension: 22),
  );
}

/// Unblocker: a key slides in, turns a quarter with a bounce, sparks once, rests, then turns back out.
class _TurningKey extends StatelessWidget {
  const _TurningKey(this.main, this.turned);
  final Color main;
  final Color turned;

  @override
  Widget build(BuildContext context) => Animate(
    onPlay: (c) => c.repeat(),
    effects: [
      CustomEffect(
        duration: 3000.ms,
        builder: (context, v, child) {
          double part(double from, double to) => ((v - from) / (to - from)).clamp(0.0, 1.0);
          final slideIn = Curves.easeOutCubic.transform(part(0, .12));
          final turn = Curves.easeOutBack.transform(part(.14, .34));
          final back = Curves.easeInCubic.transform(part(.82, .94));
          final slideOut = Curves.easeInCubic.transform(part(.94, 1));
          final spark = part(.32, .5);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(-4 * (1 - slideIn) + 4 * slideOut, 0),
                child: Transform.rotate(
                  angle: (-turn + back) * pi / 2,
                  child: Icon(Icons.key_rounded, size: 18, color: Color.lerp(main, turned, turn - back)),
                ),
              ),
              if (spark > 0 && spark < 1)
                PositionedDirectional(
                  end: -1,
                  top: -1,
                  child: Opacity(
                    opacity: 1 - spark,
                    child: Transform.scale(
                      scale: .4 + spark,
                      child: const Icon(Icons.auto_awesome_rounded, size: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
    child: const SizedBox.square(dimension: 22),
  );
}
