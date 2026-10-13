import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/theme/cat/cat_theme.dart';
import 'package:hiddify/core/widget/cat/cat_face.dart';
import 'package:hiddify/core/widget/cat/yarn_breaker.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The game to play while connecting, with the connection status kept in view
/// so the player sees the moment it's ready.
class YarnBreakerPage extends ConsumerStatefulWidget {
  const YarnBreakerPage({super.key});

  static Future<void> show(BuildContext context) => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const YarnBreakerPage()));

  @override
  ConsumerState<YarnBreakerPage> createState() => _YarnBreakerPageState();
}

class _YarnBreakerPageState extends ConsumerState<YarnBreakerPage> {
  int _score = 0;
  int _lives = YarnBreakerState.startLives;
  YarnBreakerPhase _phase = YarnBreakerPhase.ready;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final cat = CatTheme.of(context);
    final status = ref.watch(connectionNotifierProvider).valueOrNull;
    final connected = status is Connected;

    final String? message = switch (_phase) {
      YarnBreakerPhase.ready => t.cat.game.launch,
      YarnBreakerPhase.won => t.cat.game.won,
      YarnBreakerPhase.lost => t.cat.game.lost,
      YarnBreakerPhase.playing => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(t.cat.game.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: t.common.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // the connection, so nobody has to leave the game to check on it
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (connected ? cat.auraConnected : cat.auraBusy).withValues(alpha: .16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CatFace(mood: connected ? CatMood.purring : CatMood.wakingUp, size: 32),
                  const Gap(10),
                  Expanded(
                    child: Text(status?.present(t) ?? t.connection.connecting, style: theme.textTheme.titleSmall),
                  ),
                  if (connected) FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.common.done)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('${t.cat.game.score}: $_score', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  for (var i = 0; i < YarnBreakerState.startLives; i++)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 20,
                        color: i < _lives ? cat.heart : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      YarnBreaker(
                        onChanged: (score, lives, phase) => setState(() {
                          _score = score;
                          _lives = lives;
                          _phase = phase;
                        }),
                      ),
                      if (message != null)
                        IgnorePointer(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(message, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                              if (_phase != YarnBreakerPhase.ready) ...[
                                const Gap(8),
                                Text(t.cat.game.again, style: theme.textTheme.bodyMedium),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
