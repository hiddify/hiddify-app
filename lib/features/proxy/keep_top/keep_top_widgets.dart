import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/keep_top/country_names.dart';
import 'package:hiddify/features/proxy/keep_top/keep_tags_dialog.dart';
import 'package:hiddify/features/proxy/keep_top/keep_top.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/utils/platform_utils.dart';
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

/// What the keep top dialog answers: how many run, the fastest (-1 for all of them, or
/// [KeepTopDialog.pickByHand]), and whether they are picked by a quick test.
typedef KeepTopChoice = ({int keep, bool quick, List<String> countries});

/// Asks how many of a profile's [count] proxies run, the fastest, starting at [keep], and whether
/// a quick test picks them, starting at [quick]. Pops the choice: -1 to run them all,
/// [keepTopAnswering] for the ones that answer, or [pickByHand] to choose them one by one.
class KeepTopDialog extends HookConsumerWidget {
  const KeepTopDialog({
    super.key,
    required this.count,
    required this.keep,
    this.quick = true,
    this.countries = const [],
    this.available = const [],
  });

  final int count;
  final int keep;
  final bool quick;

  /// The countries chosen to keep proxies of; none for any.
  final List<String> countries;

  /// The countries of the profile's proxies, with how many each has, in the order offered.
  final List<(String, int)> available;

  /// Popped when the user chooses the proxies that run themselves.
  static const pickByHand = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.dialogs.keepTop;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final chosen = useState(keep);
    final quickTest = useState(quick);
    final chosenCountries = useState(<String>{...countries});
    final n = chosen.value;
    // the counts the chevron offers, below the profile's proxy count
    final counts = {..._keepCounts.where((c) => c < count), if (keep > 0 && keep < count) keep}.toList()..sort();
    final button = switch (n) {
      keepTopAnswering => text.keepAnswering,
      < 0 => text.useAll(count: count),
      _ => text.keep(keep: n),
    };
    Widget dots = KeepTopDots(key: ValueKey(n), running: n > 0 ? n : count, total: count);
    if (n == keepTopAnswering && !MediaQuery.disableAnimationsOf(context)) {
      // which ones answer is known once they are tested
      dots = dots
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1400.ms, color: s.primary.withValues(alpha: .6), angle: .4);
    }
    void done(int keep) =>
        Navigator.of(context).pop((keep: keep, quick: quickTest.value, countries: chosenCountries.value.toList()));

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // what this is about
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: s.primaryContainer),
                    child: Icon(Icons.filter_alt_rounded, size: 22, color: s.onPrimaryContainer),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text.title, style: theme.textTheme.titleLarge),
                        const Gap(2),
                        Text(
                          text.subtitle(count: count),
                          style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(24),
              // what that answer runs
              Row(
                children: [
                  Expanded(
                    child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: dots),
                  ),
                  const Gap(12),
                  Text(
                    n > 0 ? '$n / $count' : (n == keepTopAnswering ? '? / $count' : '$count / $count'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: s.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              // how they are picked; nothing is picked when all of them run
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: n == -1
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _QuickTestSwitch(value: quickTest.value, onChanged: (value) => quickTest.value = value),
                      ),
              ),
              const Gap(24),
              // the TV remote's center button keeps them; the chevron picks how many
              _KeepButton(
                label: chosenCountries.value.isEmpty
                    ? button
                    : '$button  ${chosenCountries.value.map(flagOf).join(' ')}',
                tooltip: text.howMany,
                counts: counts,
                extras: [(value: keepTopAnswering, label: text.answering), (value: -1, label: text.everyOne)],
                // where they are: between "working" and "all"
                beforeLastExtra: _CountryPill(
                  available: available,
                  chosen: chosenCountries.value,
                  onChanged: (value) => chosenCountries.value = value,
                ),
                count: n,
                onCount: (value) => chosen.value = value,
                onKeep: () => done(n),
                autofocus: true,
                expand: true,
              ),
              const Gap(4),
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                onPressed: () => done(pickByHand),
                icon: const Icon(Icons.checklist_rounded, size: 18),
                label: Text(text.pickByHand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In the proxy list's action bar, of a big profile, or one that runs only some of its proxies:
/// opens the keep top dialog.
class KeepTopAction extends ConsumerWidget {
  const KeepTopAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    final total = ref.watch(profileProxyCountProvider(profile.id)).valueOrNull ?? 0;
    final keepTop = profile.keepTop;
    final keeping = profile.keepTags.isNotEmpty || keepTop == keepTopAnswering || (keepTop > 0 && total > keepTop);
    if (!keeping && total <= bigProfileProxies) return const SizedBox.shrink();
    return IconButton(
      tooltip: t.dialogs.keepTop.howMany,
      isSelected: keeping,
      icon: const Icon(Icons.filter_alt_outlined),
      selectedIcon: const Icon(Icons.filter_alt_rounded),
      onPressed: () => ref.read(keepTopNotifierProvider.notifier).choose(profile, total),
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
    // the proxies the user chose run, and only them; the core runs them all when none is left
    final chosen = profile.keepTags.isNotEmpty && listed < total;
    final regions = profile.userOverride?.keepTopCountries ?? const <String>[];
    // every one that answers, of the regions when there are: the count is known after the test
    final answering = keepTop == keepTopAnswering || (keepTop <= 0 && regions.isNotEmpty);
    final keeping = chosen || answering || (keepTop > 0 && total > keepTop);
    if (!keeping && total <= bigProfileProxies) return const SizedBox.shrink();

    Future<void> apply(Future<void> Function(KeepTopNotifier notifier) change) async {
      busy.value = true;
      try {
        await change(ref.read(keepTopNotifierProvider.notifier));
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    void choose() => apply((notifier) => notifier.choose(profile, total));

    // the core runs them all until their first pings are in
    final picking = keeping && !chosen && (answering ? listed >= total : listed > keepTop);
    final running = keeping && !picking ? listed : total;
    final text = t.pages.proxies.keepTop;
    // what stays after the test: how many, or which, and where
    final where = regions.isEmpty ? '' : text.inRegions(flags: regions.map(flagOf).join(' '));
    final then = switch (keepTop) {
      > 0 => text.thenFastest(keep: keepTop, where: where),
      keepTopAnswering => text.thenWorking(where: where),
      _ => text.thenAll(where: where),
    };
    final (String title, String body) = switch ((keeping, picking)) {
      _ when chosen => (text.chosen(n: listed), text.keptBody(paused: max(0, total - listed))),
      (true, true) when answering => (text.pickingAnswering(count: total), then),
      (true, true) => (text.picking(keep: keepTop, count: total), then),
      (true, false) when answering => (
        text.keptAnswering(n: listed, where: where),
        text.keptBody(paused: max(0, total - listed)),
      ),
      (true, false) => (text.keptFastest(n: listed, where: where), text.keptBody(paused: max(0, total - listed))),
      _ => (text.big(count: total), text.bigBody(keep: keepTopDefault)),
    };
    // one button: the keep top dialog, where how many run, or which, is chosen
    List<Widget> buttonsFor({required bool wide}) => [
      FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
          minimumSize: wide ? const Size(0, 40) : null,
        ),
        onPressed: busy.value ? null : choose,
        icon: const Icon(Icons.filter_alt_rounded, size: 18),
        label: Text(keeping ? text.change : t.dialogs.keepTop.howMany),
      ),
    ];

    Widget dots = KeepTopDots(key: ValueKey((keeping, picking)), running: picking ? 0 : running, total: total);
    if (picking && !MediaQuery.disableAnimationsOf(context)) {
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
        if (keeping) ...[
          const Gap(8),
          KeepTopCountPill(running: picking && !answering ? keepTop : listed, total: total),
        ],
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
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: buttonsFor(wide: false)),
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

/// The counts the keep top dialog offers, those below the profile's proxy count.
const _keepCounts = [3, 5, 10, 20, 50, 100];

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
    this.extras = const [],
    this.beforeLastExtra,
    this.autofocus = false,
    this.expand = false,
  });

  final String label;
  final String tooltip;
  final List<int> counts;

  /// Choices that are not a count, under the counts: their value and label.
  final List<({int value, String label})> extras;

  /// What the menu shows among the choices that are not a count, before the last of them.
  final Widget? beforeLastExtra;
  final int count;
  final ValueChanged<int> onCount;
  final VoidCallback? onKeep;
  final bool autofocus;

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
          extras: extras,
          beforeLastExtra: beforeLastExtra,
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
          autofocus: autofocus,
          onTap: onKeep,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt_rounded, size: 18, color: on),
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
  const _CountPicker({
    required this.title,
    required this.counts,
    this.extras = const [],
    this.beforeLastExtra,
    required this.count,
    required this.onCount,
  });

  final String title;
  final List<int> counts;
  final List<({int value, String label})> extras;
  final Widget? beforeLastExtra;
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
              Icon(Icons.filter_alt_rounded, size: 16, color: s.primary),
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
          if (extras.isNotEmpty) ...[
            const Gap(10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, extra) in extras.indexed) ...[
                  if (i == extras.length - 1 && beforeLastExtra != null) beforeLastExtra!,
                  ChoiceChip(
                    label: Text(extra.label),
                    selected: extra.value == count,
                    showCheckmark: false,
                    shape: const StadiumBorder(),
                    onSelected: (_) => onCount(extra.value),
                  ),
                ],
              ],
            ),
          ],
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

/// The funnel of keep top, in the accent's circle, or a checklist for the proxies the user chose; a
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
          Icon(chosen ? Icons.checklist_rounded : Icons.filter_alt_rounded, size: 22, color: s.primary),
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

/// The quick test, on or off: the last row of the choice card. Its help button unfolds what it
/// does, under it.
class _QuickTestSwitch extends HookConsumerWidget {
  const _QuickTestSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final help = useState(false);
    const duration = Duration(milliseconds: 200);
    // a plain row: a small icon, the name with its help, the line under it, and the switch
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 0, 2),
            child: Row(
              children: [
                Icon(Icons.speed_rounded, size: 18, color: value ? s.primary : s.onSurfaceVariant),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(t.dialogs.keepTop.quick, style: theme.textTheme.labelLarge)),
                          IconButton(
                            tooltip: t.dialogs.keepTop.quickHelp,
                            onPressed: () => help.value = !help.value,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                            iconSize: 15,
                            color: help.value ? s.primary : s.onSurfaceVariant,
                            icon: Icon(help.value ? Icons.help_rounded : Icons.help_outline_rounded),
                          ),
                        ],
                      ),
                      Text(
                        t.dialogs.keepTop.quickHint,
                        style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: .75,
                  child: Switch(value: value, onChanged: onChanged),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: duration,
          curve: Curves.easeOutCubic,
          alignment: AlignmentDirectional.topStart,
          child: help.value
              ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: s.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (final (i, (icon, point)) in [
                        (Icons.history_rounded, t.dialogs.keepTop.quickFirst),
                        (Icons.flag_rounded, t.dialogs.keepTop.quickStop),
                        (Icons.fiber_new_rounded, t.dialogs.keepTop.quickNew),
                      ].indexed) ...[
                        if (i > 0) const Gap(8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, size: 16, color: s.primary),
                            const Gap(10),
                            Expanded(child: Text(point, style: theme.textTheme.bodySmall)),
                          ],
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The countries keep top keeps proxies of, as a pill among the choices of its menu: "Country",
/// or the chosen flags. It opens the countries to tick, under a field that finds one by its name
/// or code. With the field empty, the chosen and the profile's own countries are listed, with how
/// many proxies each has; any other can be found by typing, as the profile's are not all known
/// before the proxies are tested.
class _CountryPill extends HookConsumerWidget {
  const _CountryPill({required this.available, required this.chosen, required this.onChanged});

  final List<(String, int)> available;
  final Set<String> chosen;
  final ValueChanged<Set<String>> onChanged;

  /// The most countries listed for what is typed.
  static const _found = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final s = Theme.of(context).colorScheme;
    final emoji = PlatformUtils.isWindows ? FontFamily.emoji : null;
    final query = useTextEditingController();
    useListenable(query);
    final counts = {for (final (code, n) in available) code: n};
    String nameOf(String code) => countryNames[code] ?? code;
    final q = query.text.trim().toLowerCase();
    // the profile's countries by how many proxies (as given), then the preferred ones, then every
    // other by name
    final preferred = preferredCountries.where((code) => !counts.containsKey(code));
    final order = [
      ...available.map((e) => e.$1),
      ...preferred,
      ...countryNames.keys.where((code) => !counts.containsKey(code) && !preferredCountries.contains(code)),
    ];
    // with the field empty: the chosen ones not otherwise listed, the profile's, and the preferred
    final listed = q.isEmpty
        ? {
            ...chosen.where((code) => !counts.containsKey(code) && !preferredCountries.contains(code)),
            ...available.map((e) => e.$1),
            ...preferred,
          }.toList()
        : order
              .where(
                (code) =>
                    code.toLowerCase() == q || nameOf(code).toLowerCase().contains(q) || (q == 'uk' && code == 'GB'),
              )
              .take(_found)
              .toList();
    final flags = TextStyle(fontFamily: emoji);

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      // a short list, scrolled for the rest
      style: const MenuStyle(maximumSize: WidgetStatePropertyAll(Size(300, 380))),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: SizedBox(
            width: 240,
            child: TextField(
              controller: query,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                hintText: t.dialogs.keepTop.region,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        MenuItemButton(
          leadingIcon: Icon(Icons.public_rounded, size: 20, color: chosen.isEmpty ? s.primary : null),
          onPressed: () => onChanged({}),
          child: Text(t.dialogs.keepTop.anyRegion),
        ),
        const Divider(height: 1),
        for (final code in listed)
          CheckboxMenuButton(
            value: chosen.contains(code),
            closeOnActivate: false,
            onChanged: (checked) => onChanged(checked ?? false ? {...chosen, code} : ({...chosen}..remove(code))),
            trailingIcon: counts.containsKey(code)
                ? Text(
                    '${counts[code]}',
                    style: TextStyle(color: s.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()]),
                  )
                : null,
            child: Text('${flagOf(code)}  ${nameOf(code)}', style: flags),
          ),
      ],
      builder: (context, controller, _) => FilterChip(
        avatar: chosen.isEmpty ? const Icon(Icons.public_rounded, size: 16) : null,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(chosen.isEmpty ? t.dialogs.keepTop.region : chosen.map(flagOf).join(' '), style: flags),
            const Gap(2),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
        selected: chosen.isNotEmpty,
        showCheckmark: false,
        shape: const StadiumBorder(),
        onSelected: (_) => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
