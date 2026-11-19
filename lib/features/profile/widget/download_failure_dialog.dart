import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/profile/model/download_problem.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Why a subscription could not be downloaded, for someone without technical knowledge: an icon and
/// a title for the problem, its error number, what happened, where on the way to the provider it
/// stopped, the steps to try, and the technical details folded away for support.
class DownloadFailureDialog extends HookConsumerWidget {
  const DownloadFailureDialog({super.key, required this.failure, this.action, this.showDetails = false});

  final ProfileDownloadFailure failure;

  /// What failed, such as "Failed to add profile"; shown above the title.
  final String? action;

  /// Whether the technical details start unfolded.
  final bool showDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = failure.problem.text(t, code: failure.statusCode);
    final tone = _Tone.of(failure.problem.side, colors);
    final surface = DialogTheme.of(context).backgroundColor ?? colors.surfaceContainerHigh;
    final code = failure.problem.code(failure.statusCode);
    final detailsOpen = useState(showDetails);
    // the error number first, then what each download met
    final detail = [
      '${t.errors.download.errorCode}: $code',
      if (failure.detail case final d? when d.isNotEmpty) d,
    ].join('\n');

    return Dialog(
      // the card is drawn below: the icon stands half out of its top edge
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          // room for the icon's glow above it
          padding: const EdgeInsets.only(top: 12),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: _Badge.size / 2),
                child: Material(
                  color: surface,
                  elevation: 6,
                  shadowColor: Colors.black,
                  surfaceTintColor: Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Stack(
                    children: [
                      // the problem's color washes down from the top, behind the icon and the title
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 190,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [tone.container, tone.container.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, _Badge.size / 2 + 16, 24, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (action != null) ...[
                              Text(
                                action!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelLarge!.copyWith(
                                  color: tone.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Gap(6),
                            ],
                            Semantics(
                              header: true,
                              child: Text(
                                text.title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                              ),
                            ),
                            const Gap(14),
                            Center(
                              child: _CodeChip(code: code, label: t.errors.download.errorCode, tone: tone),
                            ),
                            const Gap(16),
                            Center(
                              child: Container(
                                width: 36,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: tone.accent.withValues(alpha: .35),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const Gap(14),
                            Text(
                              text.why,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium!.copyWith(color: colors.onSurfaceVariant, height: 1.5),
                            ),
                            const Gap(18),
                            _Path(problem: failure.problem, tone: tone),
                            const Gap(20),
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded, size: 16, color: colors.primary),
                                const Gap(6),
                                Text(
                                  t.errors.download.whatToTry,
                                  style: theme.textTheme.labelLarge!.copyWith(color: colors.primary, letterSpacing: .3),
                                ),
                              ],
                            ),
                            const Gap(8),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surface.withValues(alpha: .6),
                                border: Border.all(color: colors.outlineVariant.withValues(alpha: .7)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  for (final (index, tip) in text.tips.indexed) ...[
                                    if (index > 0)
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: colors.outlineVariant.withValues(alpha: .5),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: colors.primary.withValues(alpha: .12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${index + 1}',
                                              style: theme.textTheme.labelSmall!.copyWith(
                                                color: colors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const Gap(12),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 1),
                                              child: Text(
                                                tip,
                                                style: theme.textTheme.bodyMedium!.copyWith(height: 1.4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Gap(6),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => detailsOpen.value = !detailsOpen.value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.code_rounded, size: 16, color: colors.onSurfaceVariant),
                                    const Gap(8),
                                    Expanded(
                                      child: Text(
                                        t.errors.download.technicalDetails,
                                        style: theme.textTheme.labelLarge!.copyWith(color: colors.onSurfaceVariant),
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: detailsOpen.value ? .5 : 0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(Icons.expand_more_rounded, size: 20, color: colors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.topCenter,
                              child: detailsOpen.value
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colors.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: SelectableText(
                                        detail,
                                        textDirection: TextDirection.ltr,
                                        style: theme.textTheme.bodySmall!.copyWith(
                                          fontFamily: 'monospace',
                                          fontFamilyFallback: const ['Menlo', 'Consolas', 'Roboto Mono'],
                                          color: colors.onSurfaceVariant,
                                          height: 1.5,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(width: double.infinity),
                            ),
                            const Gap(16),
                            Row(
                              children: [
                                Expanded(
                                  // the wider of the two: its label is the longer one
                                  flex: 3,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(44),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    // everything the dialog says and the technical details, for a report
                                    onPressed: () async {
                                      final shown = failure.present(t);
                                      final report = [
                                        if (action != null) action!,
                                        shown.type,
                                        shown.message ?? '',
                                      ].join('\n\n');
                                      await Clipboard.setData(ClipboardData(text: report));
                                      ref
                                          .read(inAppNotificationControllerProvider)
                                          .showSuccessToast(t.common.msg.export.clipboard.success);
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 18),
                                    label: Text(t.errors.download.copyDetails, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                const Gap(12),
                                Expanded(
                                  flex: 2,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                                    onPressed: () => context.pop(),
                                    child: Text(t.common.ok),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _Badge(icon: _icon(failure.problem), tone: tone, ring: surface),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _icon(DownloadProblem problem) => switch (problem) {
    DownloadProblem.serverError => Icons.dns_rounded,
    DownloadProblem.notFound => Icons.link_off_rounded,
    DownloadProblem.denied => Icons.do_not_disturb_on_rounded,
    DownloadProblem.tooManyRequests => Icons.hourglass_top_rounded,
    DownloadProblem.badStatus => Icons.report_gmailerrorred_rounded,
    DownloadProblem.tooLarge => Icons.inventory_2_rounded,
    DownloadProblem.noInternet => Icons.wifi_off_rounded,
    DownloadProblem.dns => Icons.travel_explore_rounded,
    DownloadProblem.certificate => Icons.gpp_bad_rounded,
    DownloadProblem.reset => Icons.block_rounded,
    DownloadProblem.tls => Icons.no_encryption_gmailerrorred_rounded,
    DownloadProblem.refused => Icons.cloud_off_rounded,
    DownloadProblem.timeout => Icons.timer_off_rounded,
    DownloadProblem.unknown => Icons.error_outline_rounded,
  };
}

/// The colors of a problem by its side: the user's connection in the error colors, the provider's
/// side and the subscription in calmer ones, since there the user can only wait or ask.
class _Tone {
  const _Tone(this.container, this.onContainer, this.accent);
  final Color container;
  final Color onContainer;
  final Color accent;

  factory _Tone.of(DownloadProblemSide side, ColorScheme colors) => switch (side) {
    DownloadProblemSide.network => _Tone(colors.errorContainer, colors.onErrorContainer, colors.error),
    DownloadProblemSide.provider => _Tone(colors.tertiaryContainer, colors.onTertiaryContainer, colors.tertiary),
    DownloadProblemSide.subscription => _Tone(colors.primaryContainer, colors.onPrimaryContainer, colors.primary),
    DownloadProblemSide.unknown => _Tone(colors.surfaceContainerHighest, colors.onSurfaceVariant, colors.outline),
  };
}

/// The problem's icon on a disc of its color, ringed in the dialog's own color so that it stands
/// out of the wash behind it.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.tone, required this.ring});
  final IconData icon;
  final _Tone tone;
  final Color ring;

  /// Its diameter: half of it stands above the card.
  static const double size = 96;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ring,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: tone.accent.withValues(alpha: .35),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        width: size - 14,
        height: size - 14,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(tone.accent, Colors.white, .18)!, tone.accent],
          ),
        ),
        child: Icon(icon, size: 40, color: tone.container),
      ),
    );
  }
}

/// The way of the download in three stops, the device, the internet and the provider, with the one
/// where it stopped marked: the stops before it worked, the ones after it were never reached. It
/// answers "is it me, my internet, or my provider?" at a glance.
class _Path extends ConsumerWidget {
  const _Path({required this.problem, required this.tone});
  final DownloadProblem problem;
  final _Tone tone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labels = t.errors.download.path;
    final failed = problem.failedStop;
    final ok = theme.brightness == Brightness.dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    final idle = colors.outline;
    // the third stop is the subscription itself when the provider's server answered about it
    final ofSubscription = problem.side == DownloadProblemSide.subscription;
    final stops = [
      (Icons.smartphone_rounded, labels.device),
      (Icons.public_rounded, labels.internet),
      if (ofSubscription)
        (Icons.confirmation_number_outlined, t.errors.download.side.subscription)
      else
        (Icons.dns_outlined, labels.provider),
    ];
    Color colorOf(int stop) => failed == null
        ? idle
        : stop < failed
        ? ok
        : stop == failed
        ? tone.accent
        : idle;

    return Semantics(
      container: true,
      label: failed == null ? null : '${labels.title}: ${stops[failed].$2}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: .6),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: .7)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                labels.title,
                style: theme.textTheme.labelMedium!.copyWith(color: colors.onSurfaceVariant, letterSpacing: .4),
              ),
              const Gap(12),
              Stack(
                children: [
                  // the lines between the stops, from one disc to the next: it worked up to the stop
                  // that failed
                  Positioned(
                    top: 21,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        const Spacer(),
                        for (final index in [1, 2])
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 30),
                              decoration: BoxDecoration(
                                color: (failed != null && index <= failed ? colorOf(index) : idle).withValues(
                                  alpha: failed != null && index <= failed ? .8 : .3,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        const Spacer(),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (index, (icon, label)) in stops.indexed)
                        Expanded(
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: colorOf(index).withValues(alpha: index == failed ? 1 : .12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 22,
                                      color: index == failed ? tone.container : colorOf(index),
                                    ),
                                  ),
                                  if (failed != null && index <= failed)
                                    PositionedDirectional(
                                      end: -4,
                                      bottom: -4,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: index == failed ? tone.accent : ok,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: colors.surfaceContainerLowest, width: 2),
                                        ),
                                        child: Icon(
                                          index == failed ? Icons.close_rounded : Icons.check_rounded,
                                          size: 11,
                                          color: colors.surfaceContainerLowest,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Gap(8),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium!.copyWith(
                                  color: index == failed ? tone.accent : colors.onSurfaceVariant,
                                  fontWeight: index == failed ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The error number, always shown as "ERROR 403": what the user quotes to support.
class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code, required this.label, required this.tone});
  final String code;
  final String label;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $code',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(9, 5, 13, 5),
        decoration: BoxDecoration(
          color: Color.alphaBlend(tone.container.withValues(alpha: .6), Theme.of(context).colorScheme.surface),
          border: Border.all(color: tone.accent.withValues(alpha: .25)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_rounded, size: 15, color: tone.accent),
            const Gap(6),
            // left to right in every language: a code, not a sentence
            Text(
              'ERROR $code',
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: tone.onContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
