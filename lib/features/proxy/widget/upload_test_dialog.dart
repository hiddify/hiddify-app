import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/upload_speed.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Which proxies a speed test from the proxy picker runs on.
enum SpeedTestTarget { shown, chosen }

/// How a speed test of the proxy list runs: download or upload, how much through each proxy, and
/// how many of the fastest proxies; with the data that takes at a glance. Saves the choices and
/// pops the proxies it runs on (always [SpeedTestTarget.shown] without [chosen]); the button starts
/// the test when [start], else saves. [count] is how many proxies the list shows, when known;
/// [chosen], how many the user chose, offers to test those instead.
class SpeedTestDialog extends HookConsumerWidget {
  const SpeedTestDialog({super.key, this.count, this.chosen, this.start = true});

  final int? count;
  final int? chosen;
  final bool start;

  static const _limits = [5, 10, 20, 50];

  /// Above this many megabytes in all, the estimate turns to a warning color.
  static const _heavy = 500;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.pages.proxies.speedTest;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final direction = useState(ref.read(ConfigOptions.speedTestDirection));
    final size = useState(ref.read(ConfigOptions.uploadTestSize));
    final target = useState(SpeedTestTarget.shown);
    final cleared = useState(false);
    final count = target.value == SpeedTestTarget.chosen ? chosen : this.count;
    // 0: all of them
    final limit = useState(ref.read(ConfigOptions.uploadTestLimit));
    // a limit at or above what there is to test is all of it
    final effective = limit.value <= 0 || (count != null && limit.value >= count) ? 0 : limit.value;

    final sizes = {...uploadTestSizes, size.value}.toList()..sort();
    final limits = {..._limits, if (limit.value > 0) limit.value}.where((n) => count == null || n < count).toList()
      ..sort();
    final tested = effective > 0 ? effective : count;
    final both = direction.value == SpeedTestDirection.both;
    // both ways, each proxy takes its megabytes twice
    final total = tested == null ? null : tested * size.value * (both ? 2 : 1);
    final warn = theme.brightness == Brightness.dark ? const Color(0xFFFFB74D) : Colors.orange.shade800;
    final accent = (total ?? 0) >= _heavy ? warn : s.primary;

    Future<void> confirm() async {
      await ref.read(ConfigOptions.speedTestDirection.notifier).update(direction.value);
      await ref.read(ConfigOptions.uploadTestSize.notifier).update(size.value);
      await ref.read(ConfigOptions.uploadTestLimit.notifier).update(limit.value);
      if (context.mounted) Navigator.of(context).pop(target.value);
    }

    return AlertDialog(
      icon: const Icon(Icons.speed_rounded),
      title: Text(text.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Section(
                label: text.what,
                child: SegmentedButton<SpeedTestDirection>(
                  // the arrows tell the two apart; a check would hide one
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: SpeedTestDirection.download,
                      icon: const Icon(Icons.arrow_downward_rounded),
                      label: Text(text.download),
                    ),
                    ButtonSegment(
                      value: SpeedTestDirection.upload,
                      icon: const Icon(Icons.arrow_upward_rounded),
                      label: Text(text.upload),
                    ),
                    ButtonSegment(
                      value: SpeedTestDirection.both,
                      icon: const Icon(Icons.swap_vert_rounded),
                      label: Text(text.both),
                    ),
                  ],
                  selected: {direction.value},
                  onSelectionChanged: (value) => direction.value = value.first,
                ),
              ),
              if (chosen case final chosen?) ...[
                const Gap(10),
                _Section(
                  label: text.which,
                  child: SegmentedButton<SpeedTestTarget>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: SpeedTestTarget.shown,
                        icon: const Icon(Icons.filter_list_rounded),
                        label: Text(text.shown(n: this.count ?? 0)),
                      ),
                      ButtonSegment(
                        value: SpeedTestTarget.chosen,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: Text(text.chosen(n: chosen)),
                        enabled: chosen > 0,
                      ),
                    ],
                    selected: {target.value},
                    onSelectionChanged: (value) => target.value = value.first,
                  ),
                ),
              ],
              const Gap(10),
              _Section(
                label: text.amount,
                hint: text.amountHint,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    for (final n in sizes)
                      ButtonSegment(
                        value: n,
                        label: Text(t.pages.settings.general.megabytes(n: n)),
                      ),
                  ],
                  selected: {size.value},
                  onSelectionChanged: (value) => size.value = value.first,
                ),
              ),
              if (count == null || count > 1) ...[
                const Gap(10),
                _Section(
                  label: text.proxies,
                  hint: text.proxiesHint,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: [
                      for (final n in limits) ButtonSegment(value: n, label: Text('$n')),
                      ButtonSegment(value: 0, label: Text(count == null ? text.all : '${text.all} $count')),
                    ],
                    selected: {effective},
                    onSelectionChanged: (value) => limit.value = value.first,
                  ),
                ),
              ],
              const Gap(14),
              // the data it takes, at a glance
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(accent.withValues(alpha: .12), s.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: accent.withValues(alpha: .18), shape: BoxShape.circle),
                      child: Icon(
                        switch (direction.value) {
                          SpeedTestDirection.download => Icons.arrow_downward_rounded,
                          SpeedTestDirection.upload => Icons.arrow_upward_rounded,
                          SpeedTestDirection.both => Icons.swap_vert_rounded,
                        },
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _amount(total ?? size.value),
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            [
                              switch ((tested, effective)) {
                                (null, _) => text.throughEach(n: size.value),
                                (final n?, 0) => text.throughAll(n: size.value, count: n),
                                (final n?, _) => text.through(n: size.value, count: n),
                              },
                              if (both) text.bothWays,
                            ].join(', '),
                            style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // the results the rows keep, of this run and the earlier ones
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: cleared.value
                      ? null
                      : () async {
                          await ref.read(proxiesOverviewNotifierProvider.notifier).clearSpeedTests();
                          cleared.value = true;
                        },
                  style: TextButton.styleFrom(foregroundColor: s.error, visualDensity: VisualDensity.compact),
                  icon: Icon(cleared.value ? Icons.check_rounded : Icons.delete_sweep_outlined, size: 18),
                  label: Text(cleared.value ? text.cleared : text.clear),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.common.cancel)),
        FilledButton.icon(
          autofocus: true,
          onPressed: confirm,
          icon: Icon(start ? Icons.speed_rounded : Icons.check_rounded),
          label: Text(start ? text.start : text.save),
        ),
      ],
    );
  }

  static String _amount(int megabytes) =>
      megabytes < 1024 ? '≈ $megabytes MB' : '≈ ${(megabytes / 1024).toStringAsFixed(1)} GB';
}

/// One choice of the speed test, on a tinted card of its own.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child, this.hint});

  final String label;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(color: s.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label),
                if (hint != null)
                  TextSpan(
                    text: ' · $hint',
                    style: TextStyle(color: s.onSurfaceVariant.withValues(alpha: .7)),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(color: s.onSurfaceVariant),
          ),
          const Gap(8),
          FittedBox(fit: BoxFit.scaleDown, child: child),
        ],
      ),
    );
  }
}
