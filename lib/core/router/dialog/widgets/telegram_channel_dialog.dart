import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Invites the user to the official Telegram channel, for news, new releases and help.
/// A Telegram-blue header with a floating paper plane over soft rings, the channel's handle,
/// then the message and one clear button.
class TelegramChannelDialog extends HookConsumerWidget {
  const TelegramChannelDialog({super.key});

  static const _telegramLight = Color(0xFF37BBFE);
  static const _telegramBlue = Color(0xFF229ED9);
  static const _telegramDeep = Color(0xFF1A7FC1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.dialogs.telegramChannel;
    final theme = Theme.of(context);
    // one slow loop drives the plane's float and the rings' breathing
    final float = useAnimationController(duration: const Duration(seconds: 4));
    useEffect(() {
      float.repeat();
      return null;
    }, const []);

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(float: float),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                children: [
                  Text(
                    text.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text.msg,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _telegramBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.telegram, size: 22),
                label: Text(text.join),
                onPressed: () async {
                  context.pop();
                  await UriUtils.tryLaunchAppOrWeb(
                    Uri.parse(Constants.telegramChannelAppUrl),
                    Uri.parse(Constants.telegramChannelUrl),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurfaceVariant),
                  onPressed: () => context.pop(),
                  child: Text(t.common.later),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.float});

  final Animation<double> float;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TelegramChannelDialog._telegramLight,
              TelegramChannelDialog._telegramBlue,
              TelegramChannelDialog._telegramDeep,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: float,
          builder: (context, _) {
            final phase = float.value * 2 * math.pi;
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: CustomPaint(painter: _RingsPainter(phase))),
                // a few faint sparkles, drifting with the plane
                for (final s in _sparkles)
                  Align(
                    alignment: Alignment(s.$1, s.$2 + math.sin(phase + s.$3) * 0.05),
                    child: Icon(Icons.auto_awesome, size: s.$4, color: Colors.white.withValues(alpha: 0.55)),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(0, math.sin(phase) * 5),
                      child: Transform.rotate(
                        angle: math.sin(phase) * 0.05,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: TelegramChannelDialog._telegramDeep.withValues(alpha: 0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.telegram, size: 84, color: TelegramChannelDialog._telegramBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        Constants.telegramChannelHandle,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// x, y, phase offset, size
  static const _sparkles = [
    (-0.72, -0.55, 0.0, 14.0),
    (0.78, -0.35, 2.1, 18.0),
    (-0.55, 0.62, 4.2, 10.0),
    (0.62, 0.7, 1.3, 12.0),
  ];
}

/// Soft concentric rings behind the plane, gently breathing.
class _RingsPainter extends CustomPainter {
  _RingsPainter(this.phase);

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 14);
    final breath = 1 + math.sin(phase) * 0.03;
    for (var i = 1; i <= 4; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.22 - i * 0.04);
      canvas.drawCircle(center, (42 + i * 26) * breath, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) => oldDelegate.phase != phase;
}
