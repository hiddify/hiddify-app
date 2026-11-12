import 'dart:math';

import 'package:flutter/foundation.dart';
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
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
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
    if (!keeping && !profile.offersKeepTop(total)) return const SizedBox.shrink();
    return IconButton(
      tooltip: t.dialogs.keepTop.howMany,
      isSelected: keeping,
      icon: const Icon(Icons.filter_alt_outlined),
      selectedIcon: const Icon(Icons.filter_alt_rounded),
      onPressed: () => ref.read(keepTopNotifierProvider.notifier).choose(profile, total),
    );
  }
}

/// Under the proxies in use: the fold that shows, or hides, the [count] proxies keep top left at
/// rest. They stay in the profile; a tap on one selects it, which loads it and tests it.
class RestingProxiesHeader extends ConsumerWidget {
  const RestingProxiesHeader({super.key, required this.count, required this.shown, required this.onToggle});

  final int count;
  final bool shown;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final text = t.pages.proxies.keepTop;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onToggle,
            icon: Icon(shown ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20),
            label: Text(shown ? text.restingHide : text.restingShow(n: count)),
          ),
          if (shown)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, bottom: 4),
              child: Text(
                text.restingHint,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

/// At the end of the proxies in use, of a big profile: how many of its proxies run, as one big
/// figure over a bar, the facts about them as chips, and the button that changes how many run.
/// The chips change what they say: the one of how many opens the counts, the one of where the
/// countries.
/// [listed] is how many proxies are in use now (the ones keep top left at rest are not),
/// [picking] whether the core still looks for the fastest. With regions chosen, a line says when
/// proxies of other regions answered faster, and offers to keep any region.
class KeepTopFooter extends HookConsumerWidget {
  const KeepTopFooter({super.key, required this.listed, required this.picking, this.proxies = const []});

  final int listed;
  final bool picking;

  /// The profile's proxies as the core lists them, the paused ones too: they tell when proxies of
  /// other regions are faster.
  final List<OutboundInfo> proxies;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final busy = useState(false);
    final countMenu = useMemoized(MenuController.new);
    final regionMenu = useMemoized(MenuController.new);
    // the profile's countries, read when their menu opens
    final available = useState(const <(String, int)>[]);
    // the countries ticked in the open menu: applied when it closes
    final ticked = useState<Set<String>?>(null);
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
    if (!keeping && !profile.offersKeepTop(total)) return const SizedBox.shrink();

    Future<void> apply(Future<void> Function(KeepTopNotifier notifier) change) async {
      busy.value = true;
      try {
        await change(ref.read(keepTopNotifierProvider.notifier));
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    void choose() => apply((notifier) => notifier.choose(profile, total));

    Future<void> setRegions(Set<String> value) async {
      if (!setEquals(value, regions.toSet())) {
        await apply((notifier) => notifier.set(profile, keepTop, countries: value.toList()));
      }
      if (context.mounted) ticked.value = null;
    }

    // the core goes through them a few at a time, and says while it does
    final picking = keeping && !chosen && this.picking;
    final running = keeping && !picking ? listed : total;
    final paused = max(0, total - running);
    // a count was asked for: the bar shows it behind the ones that run
    final wanted = !chosen && keepTop > 0 ? min(keepTop, total) : 0;
    // fewer than asked for: no more of them answer, of the regions when there are
    final fewer = !picking && wanted > listed;
    final text = t.pages.proxies.keepTop;
    final warn = theme.brightness == Brightness.dark ? const Color(0xFFFFB74D) : const Color(0xFFB45309);

    final enabled = !busy.value;
    // which ones run: a tap opens the counts, or the proxies picked by hand
    final Widget mode;
    if (chosen) {
      mode = _Fact(
        icon: Icons.checklist_rounded,
        label: text.modeChosen,
        onTap: enabled ? () => apply((notifier) => notifier.pick(profile)) : null,
      );
    } else {
      void toggle() => countMenu.isOpen ? countMenu.close() : countMenu.open();
      final onTap = enabled ? toggle : null;
      mode = MenuAnchor(
        controller: countMenu,
        alignmentOffset: const Offset(0, 6),
        style: MenuStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        ),
        menuChildren: [
          _CountPicker(
            title: t.dialogs.keepTop.howMany,
            counts: {..._keepCounts.where((c) => c < total), if (keepTop > 0 && keepTop < total) keepTop}.toList()
              ..sort(),
            extras: [
              (value: keepTopAnswering, label: t.dialogs.keepTop.answering),
              (value: -1, label: t.dialogs.keepTop.everyOne),
            ],
            count: keepTop,
            onCount: (n) {
              countMenu.close();
              if (n != keepTop) apply((notifier) => notifier.set(profile, n));
            },
          ),
        ],
        child: fewer
            ? _Fact(
                icon: Icons.error_outline_rounded,
                label: text.onlyAnswer(keep: wanted, n: listed),
                color: warn,
                onTap: onTap,
              )
            : wanted > 0 && keeping
            ? _Fact(
                icon: Icons.bolt_rounded,
                label: text.modeTop(keep: wanted),
                onTap: onTap,
              )
            : answering
            ? _Fact(icon: Icons.check_circle_outline_rounded, label: text.modeWorking, onTap: onTap)
            : _Fact(icon: Icons.all_inclusive_rounded, label: t.dialogs.keepTop.everyOne, onTap: onTap),
      );
    }
    final shownRegions = ticked.value ?? regions.toSet();
    // the regions keep the slower ones: proxies elsewhere answered faster
    final faster = chosen || picking ? 0 : fasterOutsideRegions(proxies, regions);
    // each fact on a chip of its own: which ones run, where they are, how many rest
    final facts = [
      mode,
      // where they are: a tap opens the countries; the ticked ones apply when the menu closes
      if (!chosen)
        _CountryPill(
          controller: regionMenu,
          available: available.value,
          chosen: shownRegions,
          onChanged: (value) {
            ticked.value = value;
            // "any region" closes the menu before it says so
            if (!regionMenu.isOpen) setRegions(value);
          },
          onClose: () {
            if (ticked.value case final value?) setRegions(value);
          },
          builder: (context, menu) => _Fact(
            icon: Icons.public_rounded,
            label: [t.dialogs.keepTop.region, ...shownRegions.map(flagOf)].join(' '),
            emoji: true,
            onTap: enabled
                ? () async {
                    if (menu.isOpen) return menu.close();
                    available.value = await ref.read(keepTopNotifierProvider.notifier).countries(profile);
                    menu.open();
                  }
                : null,
          ),
        ),
    ];

    const figures = [FontFeature.tabularFigures()];
    final figure = Directionality(
      // the count reads the same way in every language
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: running.toDouble()),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '${value.round()}',
              style: theme.textTheme.displaySmall?.copyWith(
                color: s.primary,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: -1,
                fontFeatures: figures,
              ),
            ),
          ),
          if (running < total) ...[
            const Gap(6),
            Text(
              '/ $total',
              style: theme.textTheme.titleMedium?.copyWith(color: s.onSurfaceVariant, fontFeatures: figures),
            ),
          ],
          const Gap(8),
          Flexible(
            child: Text(
              picking ? text.testing : text.running,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: Directionality.of(context),
              style: theme.textTheme.titleMedium?.copyWith(color: s.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        padding: const EdgeInsets.all(16),
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
              children: [
                Expanded(
                  child: Align(alignment: AlignmentDirectional.centerStart, child: figure),
                ),
                const Gap(12),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.comfortable),
                  onPressed: busy.value ? null : choose,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(keeping ? text.change : t.dialogs.keepTop.howMany),
                ),
              ],
            ),
            const Gap(14),
            _RunBar(running: running, wanted: picking ? 0 : wanted, total: total, busy: picking || busy.value),
            const Gap(12),
            Wrap(spacing: 8, runSpacing: 8, children: facts),
            if (faster > 0) ...[
              const Gap(12),
              _FasterElsewhere(n: faster, onAnyRegion: enabled ? () => setRegions(const {}) : null),
            ],
            if (paused > 0 && !picking) ...[const Gap(12), _RestingNote(paused: paused)],
            if (!keeping) ...[
              const Gap(10),
              Text(
                text.bigBody(keep: keepTopDefault),
                style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 350.ms).slideY(begin: .06, duration: 350.ms, curve: Curves.easeOutCubic),
    );
  }
}

/// In the keep top card, with regions chosen: [n] proxies of other regions answered faster than
/// the ones running, and a button that keeps the fastest of any region ([onAnyRegion]).
class _FasterElsewhere extends ConsumerWidget {
  const _FasterElsewhere({required this.n, required this.onAnyRegion});

  final int n;
  final VoidCallback? onAnyRegion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(translationsProvider).requireValue.pages.proxies.keepTop;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: s.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.primary.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 20, color: s.primary),
          const Gap(8),
          Expanded(
            child: Text(text.fasterElsewhere(n: n), style: theme.textTheme.bodyMedium),
          ),
          const Gap(8),
          TextButton(onPressed: onAnyRegion, child: Text(text.anyRegion)),
        ],
      ),
    );
  }
}

/// Under the keep top card's chips: why [paused] proxies rest, in plain words, and that any of them
/// wakes with a tap.
class _RestingNote extends ConsumerWidget {
  const _RestingNote({required this.paused});

  final int paused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(translationsProvider).requireValue.pages.proxies.keepTop;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: s.tertiary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: s.tertiary.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: s.tertiary.withValues(alpha: .16), shape: BoxShape.circle),
            child: Icon(Icons.bedtime_rounded, size: 18, color: s.tertiary),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.restingTitle(n: paused),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Gap(2),
                Text(
                  text.restingWhy,
                  style: theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The share of the proxies that run, as a bar: the ones asked for faint behind the ones that run.
/// It moves on its own while they are being tested.
class _RunBar extends StatelessWidget {
  const _RunBar({required this.running, required this.wanted, required this.total, required this.busy});

  final int running;
  final int wanted;
  final int total;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final track = s.onSurface.withValues(alpha: .08);
    // a few of many still show
    double share(int n) => n <= 0 || total <= 0 ? 0 : max(n / total, .025).clamp(0, 1).toDouble();
    Widget part(int n, Color color) => TweenAnimationBuilder<double>(
      tween: Tween(end: share(n)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: value,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: busy
            ? LinearProgressIndicator(backgroundColor: track, color: s.primary)
            : Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: track),
                  part(wanted, s.primary.withValues(alpha: .28)),
                  part(running, s.primary),
                ],
              ),
      ),
    );
  }
}

/// One fact about the proxies that run, as a small chip: an icon and a word or two. With [onTap]
/// it is a button, and says so with an arrow at its end.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, this.color, this.onTap, this.emoji = false});

  final IconData icon;
  final String label;

  /// Its tint, when it says something is off.
  final Color? color;
  final VoidCallback? onTap;

  /// The label is flags.
  final bool emoji;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final on = color ?? s.onSurfaceVariant;
    final radius = BorderRadius.circular(10);
    final chip = Material(
      color: (color ?? s.onSurface).withValues(alpha: color == null ? .06 : .14),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(8, 5, onTap == null ? 10 : 4, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: on),
              const Gap(6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color ?? s.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFamily: emoji && PlatformUtils.isWindows ? FontFamily.emoji : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (onTap != null) Icon(Icons.arrow_drop_down_rounded, size: 18, color: on),
            ],
          ),
        ),
      ),
    );
    return chip;
  }
}

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
  const _CountryPill({
    required this.available,
    required this.chosen,
    required this.onChanged,
    this.controller,
    this.onClose,
    this.builder,
  });

  final List<(String, int)> available;
  final Set<String> chosen;
  final ValueChanged<Set<String>> onChanged;
  final MenuController? controller;
  final VoidCallback? onClose;

  /// What opens the menu, in place of the pill.
  final Widget Function(BuildContext context, MenuController menu)? builder;

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
      controller: controller,
      onClose: onClose,
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
      builder: (context, controller, _) => builder != null
          ? builder!(context, controller)
          : FilterChip(
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
