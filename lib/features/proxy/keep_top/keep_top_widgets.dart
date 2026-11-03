import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The proxies as dots: the running ones lit, the paused ones dim, and how many more there are.
/// The lit ones light up one after the other.
class KeepTopDots extends HookWidget {
  const KeepTopDots({super.key, required this.running, required this.total});

  final int running;
  final int total;

  static const _shown = 16;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final controller = useAnimationController(duration: const Duration(milliseconds: 1100));
    useEffect(() {
      controller.forward();
      return null;
    }, const []);
    final shown = min(total, _shown);
    final lit = min(running, shown);
    final more = total - shown;
    return Directionality(
      // the count reads after the dots in every language
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < shown; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: i < lit
                  ? AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        final v = Interval(
                          i / shown * 0.6,
                          i / shown * 0.6 + 0.4,
                          curve: Curves.easeOutBack,
                        ).transform(controller.value);
                        return _Dot(
                          color: Color.lerp(s.outlineVariant, s.primary, v.clamp(0, 1))!,
                          scale: 0.6 + 0.4 * v,
                          glow: s.primary.withValues(alpha: .45 * v.clamp(0, 1)),
                        );
                      },
                    )
                  : _Dot(color: s.outlineVariant.withValues(alpha: 0.6), scale: 0.8),
            ),
          if (more > 0) ...[
            const Gap(6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: s.onSurface.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+$more',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: s.onSurfaceVariant,
                  letterSpacing: .3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A dot; a change of its look, when how many run changes, animates.
class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.scale, this.glow});

  final Color color;
  final double scale;

  /// The halo of a running proxy.
  final Color? glow;

  static const _change = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: scale,
    duration: _change,
    child: AnimatedContainer(
      duration: _change,
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [if (glow case final glow?) BoxShadow(color: glow, blurRadius: 6, spreadRadius: .5)],
      ),
    ),
  );
}

/// Asks how many of a profile's [count] proxies run, the fastest, starting at [keep]. Pops that
/// number, or -1 to run them all.
class KeepTopDialog extends HookConsumerWidget {
  const KeepTopDialog({super.key, required this.count, required this.keep});

  final int count;
  final int keep;

  static const _choices = [3, 5, 10, 20, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final choices = {..._choices.where((n) => n < count), if (keep < count) keep}.toList()..sort();
    final chosen = useState(keep);
    // the dots show what the button in focus (or under the mouse) runs
    final keepIt = useState(true);
    final n = chosen.value;
    return AlertDialog(
      icon: const Icon(Icons.bolt_rounded),
      title: Text(t.dialogs.keepTop.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
                decoration: BoxDecoration(color: s.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: KeepTopDots(running: keepIt.value ? n : count, total: count),
                    ),
                    const Gap(10),
                    Text(
                      keepIt.value ? t.dialogs.keepTop.keeping(keep: n) : t.dialogs.keepTop.all(count: count),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(color: keepIt.value ? s.primary : s.onSurfaceVariant),
                    ),
                    const Gap(14),
                    Text(
                      t.dialogs.keepTop.howMany,
                      style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant),
                    ),
                    const Gap(8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: [for (final c in choices) ButtonSegment(value: c, label: Text('$c'))],
                        selected: {n},
                        onSelectionChanged: (value) {
                          chosen.value = value.first;
                          keepIt.value = true;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Text(
                t.dialogs.keepTop.description(count: count, keep: n),
                style: theme.textTheme.bodyMedium,
              ),
              const Gap(12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.unfold_more_rounded, size: 18, color: s.onSurfaceVariant),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      t.dialogs.keepTop.hint,
                      style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        Focus(
          onFocusChange: (focused) => keepIt.value = !focused,
          child: MouseRegion(
            onEnter: (_) => keepIt.value = false,
            onExit: (_) => keepIt.value = true,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(-1),
              child: Text(t.dialogs.keepTop.useAll(count: count)),
            ),
          ),
        ),
        FilledButton.icon(
          // the TV remote's center button keeps them
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(n),
          icon: const Icon(Icons.bolt_rounded),
          label: Text(t.dialogs.keepTop.keep(keep: n)),
        ),
      ],
    );
  }
}

/// At the end of the proxy list, of a big profile: how many of its proxies run, and the buttons
/// that run all of them, or only the fastest. [listed] is how many proxies the list has now.
class KeepTopFooter extends HookConsumerWidget {
  const KeepTopFooter({super.key, required this.listed});

  final int listed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final busy = useState(false);
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    final total = ref.watch(profileProxyCountProvider(profile.id)).valueOrNull ?? 0;
    final keepTop = profile.keepTop;
    final keeping = keepTop > 0 && total > keepTop;
    if (!keeping && total <= bigProfileProxies) return const SizedBox.shrink();

    Future<void> apply(Future<void> Function(KeepTopNotifier notifier) change) async {
      busy.value = true;
      try {
        await change(ref.read(keepTopNotifierProvider.notifier));
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    void showAll() => apply((notifier) => notifier.set(profile, -1));
    void choose() => apply((notifier) => notifier.choose(profile, total));

    // the core runs them all until their first pings are in; the one the user chose stays as well
    final picking = keeping && listed > keepTop + 1;
    final running = keeping && !picking ? listed : total;
    final text = t.pages.proxies.keepTop;
    final (String title, String body) = switch ((keeping, picking)) {
      (true, true) => (text.picking(keep: keepTop, count: total), text.pickingBody),
      (true, false) => (text.kept(n: listed), text.keptBody(paused: max(0, total - listed))),
      _ => (text.big(count: total), text.bigBody(keep: keepTopDefault)),
    };
    const compact = VisualDensity(horizontal: -1, vertical: -2);
    final buttons = keeping
        ? [
            TextButton.icon(
              style: TextButton.styleFrom(visualDensity: compact),
              onPressed: busy.value ? null : choose,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(text.change),
            ),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(visualDensity: compact),
              onPressed: busy.value ? null : showAll,
              icon: const Icon(Icons.unfold_more_rounded, size: 18),
              label: Text(text.showAll(count: total)),
            ),
          ]
        : [
            const SizedBox.shrink(),
            FilledButton.icon(
              style: FilledButton.styleFrom(visualDensity: compact),
              onPressed: busy.value ? null : choose,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(text.keep(keep: keepTopDefault)),
            ),
          ];

    Widget dots = KeepTopDots(key: ValueKey((keeping, picking)), running: picking ? 0 : running, total: total);
    if (picking) {
      // the first pings still come in
      dots = dots
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1400.ms, color: s.primary.withValues(alpha: .6), angle: .4);
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [Color.alphaBlend(s.primary.withValues(alpha: .12), s.surfaceContainerLow), s.surfaceContainerLow],
          ),
          border: Border.all(color: s.primary.withValues(alpha: .16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Badge(picking: picking || busy.value),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const Gap(2),
                      Text(body, style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant, height: 1.35)),
                    ],
                  ),
                ),
                if (keeping) ...[const Gap(8), _CountPill(running: picking ? keepTop : listed, total: total)],
              ],
            ),
            const Gap(14),
            // the proxies at a glance, on a track of their own
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: s.onSurface.withValues(alpha: .04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: dots),
            ),
            const Gap(10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: buttons),
          ],
        ),
      ).animate().fadeIn(duration: 350.ms).slideY(begin: .06, duration: 350.ms, curve: Curves.easeOutCubic),
    );
  }
}

/// The bolt of keep top, in the accent's circle; a ring turns around it while the fastest are
/// being found.
class _Badge extends StatelessWidget {
  const _Badge({required this.picking});

  final bool picking;

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [s.primary.withValues(alpha: .28), s.primary.withValues(alpha: .12)]),
            ),
          ),
          Icon(Icons.bolt_rounded, size: 22, color: s.primary),
          if (picking)
            SizedBox.square(
              dimension: _size,
              child: CircularProgressIndicator(strokeWidth: 2, color: s.primary, strokeCap: StrokeCap.round),
            ),
        ],
      ),
    );
  }
}

/// How many run of how many, as the app's chips show a count.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.running, required this.total});

  final int running;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    const figures = [FontFeature.tabularFigures()];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: s.primary.withValues(alpha: .16), borderRadius: BorderRadius.circular(12)),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$running',
              style: theme.textTheme.labelLarge?.copyWith(
                color: s.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: figures,
              ),
            ),
            TextSpan(
              text: ' / $total',
              style: theme.textTheme.labelMedium?.copyWith(
                color: s.onSurfaceVariant,
                letterSpacing: .3,
                fontFeatures: figures,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}
