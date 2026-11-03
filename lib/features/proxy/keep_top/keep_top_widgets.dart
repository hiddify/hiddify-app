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
/// number, -1 to run them all, or [pickByHand] to choose them one by one.
class KeepTopDialog extends HookConsumerWidget {
  const KeepTopDialog({super.key, required this.count, required this.keep});

  final int count;
  final int keep;

  /// Popped when the user chooses the proxies that run themselves.
  static const pickByHand = 0;

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
              const Gap(12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(pickByHand),
                  icon: const Icon(Icons.checklist_rounded, size: 18),
                  label: Text(t.dialogs.keepTop.pickByHand),
                ),
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
    // how many "keep the fastest" keeps, picked beside its button
    final keepCount = useState(keepTopDefault);
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    final total = ref.watch(profileProxyCountProvider(profile.id)).valueOrNull ?? 0;
    final keepTop = profile.keepTop;
    // the proxies the user chose run, and only them; the core runs them all when none is left
    final chosen = profile.keepTags.isNotEmpty && listed < total;
    final keeping = chosen || (keepTop > 0 && total > keepTop);
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
    void pick() => apply((notifier) => notifier.pick(profile));

    // the core runs them all until their first pings are in
    final picking = keeping && !chosen && listed > keepTop;
    final running = keeping && !picking ? listed : total;
    final text = t.pages.proxies.keepTop;
    final (String title, String body) = switch ((keeping, picking)) {
      _ when chosen => (text.chosen(n: listed), text.keptBody(paused: max(0, total - listed))),
      (true, true) => (text.picking(keep: keepTop, count: total), text.pickingBody),
      (true, false) => (text.kept(n: listed), text.keptBody(paused: max(0, total - listed))),
      _ => (text.big(count: total), text.bigBody(keep: keepCount.value)),
    };
    const compact = VisualDensity(horizontal: -1, vertical: -2);
    // a big profile: one button keeps the fastest; the chevron at its end picks how many
    final counts = [
      for (final n in _keepCounts)
        if (n < total) n,
    ];
    Widget keepButton({required bool expand}) => _KeepButton(
      label: text.keep(keep: keepCount.value),
      tooltip: t.dialogs.keepTop.howMany,
      counts: counts,
      count: keepCount.value,
      onCount: (n) => keepCount.value = n,
      onKeep: busy.value ? null : () => apply((notifier) => notifier.set(profile, keepCount.value)),
      expand: expand,
    );

    // the buttons: side by side under the card, or one over the other filling its end column
    List<Widget> buttonsFor({required bool wide}) {
      // in a column, the second is outlined, as wide as the first
      Widget secondary(VoidCallback? onPressed, IconData icon, String label) => wide
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(visualDensity: compact, minimumSize: const Size(0, 40)),
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
            )
          : TextButton.icon(
              style: TextButton.styleFrom(visualDensity: compact),
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label),
            );
      if (keeping) {
        return [
          secondary(busy.value ? null : choose, Icons.tune_rounded, text.change),
          FilledButton.tonalIcon(
            // one over the other, the buttons are one height
            style: FilledButton.styleFrom(visualDensity: compact, minimumSize: wide ? const Size(0, 40) : null),
            onPressed: busy.value ? null : showAll,
            icon: const Icon(Icons.unfold_more_rounded, size: 18),
            label: Text(text.showAll(count: total)),
          ),
        ];
      }
      final chooseButton = secondary(busy.value ? null : pick, Icons.checklist_rounded, text.choose);
      // in a column the main action leads; side by side, it ends the row
      return wide ? [keepButton(expand: true), chooseButton] : [chooseButton, keepButton(expand: false)];
    }

    Widget dots = KeepTopDots(key: ValueKey((keeping, picking)), running: picking ? 0 : running, total: total);
    if (picking) {
      // the first pings still come in
      dots = dots
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1400.ms, color: s.primary.withValues(alpha: .6), angle: .4);
    }

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Badge(picking: picking || busy.value, chosen: chosen),
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
        if (keeping) ...[const Gap(8), KeepTopCountPill(running: picking ? keepTop : listed, total: total)],
      ],
    );
    // the proxies at a glance, on a track of their own
    final track = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: s.onSurface.withValues(alpha: .04), borderRadius: BorderRadius.circular(14)),
      child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: dots),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // room for two columns: what runs on the start, what to do about it on the end
        final wide = constraints.maxWidth >= _twoColumns;
        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: wide ? 860 : 520),
            margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
            padding: wide ? const EdgeInsets.all(16) : const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  Color.alphaBlend(s.primary.withValues(alpha: .12), s.surfaceContainerLow),
                  s.surfaceContainerLow,
                ],
              ),
              border: Border.all(color: s.primary.withValues(alpha: .16)),
            ),
            child: wide
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [header, const Gap(14), track],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: VerticalDivider(width: 1, color: s.primary.withValues(alpha: .14)),
                        ),
                        // the buttons one over the other, filling the column
                        SizedBox(
                          width: 240,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, button) in buttonsFor(wide: true).indexed) ...[
                                if (i > 0) const Gap(8),
                                button,
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      const Gap(14),
                      track,
                      const Gap(10),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: buttonsFor(wide: false)),
                    ],
                  ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: .06, duration: 350.ms, curve: Curves.easeOutCubic),
        );
      },
    );
  }
}

/// From this wide, the footer lays out in two columns.
const _twoColumns = 640.0;

/// The counts "keep the fastest" offers beside its button.
const _keepCounts = [3, 5, 10, 20, 30, 50];

/// "Keep the N fastest" as one pill: a tap keeps them; the round chevron at its end opens the counts
/// to pick N from.
class _KeepButton extends HookWidget {
  const _KeepButton({
    required this.label,
    required this.tooltip,
    required this.counts,
    required this.count,
    required this.onCount,
    required this.onKeep,
    this.expand = false,
  });

  final String label;
  final String tooltip;
  final List<int> counts;
  final int count;
  final ValueChanged<int> onCount;
  final VoidCallback? onKeep;

  /// Fills the width it is given.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final menu = useMemoized(MenuController.new);
    final enabled = onKeep != null;
    final on = enabled ? s.onPrimary : s.onSurface.withValues(alpha: .38);
    return MenuAnchor(
      controller: menu,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _CountPicker(
          title: tooltip,
          counts: counts,
          count: count,
          onCount: (n) {
            onCount(n);
            menu.close();
          },
        ),
      ],
      builder: (context, controller, _) => Material(
        color: enabled ? s.primary : s.onSurface.withValues(alpha: .12),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onKeep,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: on),
                  const Gap(8),
                  Flexible(
                    fit: expand ? FlexFit.tight : FlexFit.loose,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: expand ? TextAlign.center : TextAlign.start,
                      style: theme.textTheme.labelLarge?.copyWith(color: on, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Gap(8),
                  // how many: a round chevron inside the pill
                  Tooltip(
                    message: tooltip,
                    child: Material(
                      color: on.withValues(alpha: .16),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: enabled ? () => controller.isOpen ? controller.close() : controller.open() : null,
                        child: SizedBox.square(
                          dimension: 32,
                          child: Icon(Icons.expand_more_rounded, size: 20, color: on),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The counts "keep the fastest" offers, as round buttons in a row under [title]: the current one
/// lit in the accent, a tap picks another.
class _CountPicker extends StatelessWidget {
  const _CountPicker({required this.title, required this.counts, required this.count, required this.onCount});

  final String title;
  final List<int> counts;
  final int count;
  final ValueChanged<int> onCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: s.primary),
              const Gap(6),
              Text(title, style: theme.textTheme.labelLarge?.copyWith(color: s.onSurfaceVariant)),
            ],
          ),
          const Gap(12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, n) in counts.indexed) ...[
                if (i > 0) const Gap(8),
                _CountBubble(n: n, chosen: n == count, onTap: () => onCount(n)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One count of "keep the fastest": a circle, filled in the accent when chosen.
class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.n, required this.chosen, required this.onTap});

  final int n;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      scale: chosen ? 1.08 : 1,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: chosen ? s.primary : s.surfaceContainerHighest,
              border: Border.all(color: chosen ? s.primary : s.outlineVariant.withValues(alpha: .6)),
              boxShadow: chosen
                  ? [BoxShadow(color: s.primary.withValues(alpha: .35), blurRadius: 10, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Text(
              '$n',
              style: theme.textTheme.labelLarge?.copyWith(
                color: chosen ? s.onPrimary : s.onSurface,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bolt of keep top, in the accent's circle, or a checklist for the proxies the user chose; a
/// ring turns around it while the fastest are being found.
class _Badge extends StatelessWidget {
  const _Badge({required this.picking, this.chosen = false});

  final bool picking;
  final bool chosen;

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
          Icon(chosen ? Icons.checklist_rounded : Icons.bolt_rounded, size: 22, color: s.primary),
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
class KeepTopCountPill extends StatelessWidget {
  const KeepTopCountPill({super.key, required this.running, required this.total});

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
