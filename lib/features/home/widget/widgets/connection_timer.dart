import 'package:flutter/material.dart';
import 'package:hiddify/core/core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LiveConnectionTimer extends HookConsumerWidget {
  const LiveConnectionTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durationAsync = ref.watch(connectionDurationProvider);
    final duration = durationAsync.asData?.value.duration ?? Duration.zero;

    return ConnectionTimer(duration: duration);
  }
}

class ConnectionTimer extends StatelessWidget {
  const ConnectionTimer({required this.duration, super.key});

  final Duration duration;

  String get _formatted {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.x4,
        vertical: tokens.spacing.x2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(tokens.radius.full),
      ),
      child: Text(
        _formatted,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
