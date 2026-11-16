import 'dart:async';
import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/crash_report/notifier/trace_session_notifier.dart';

const _motion = Duration(milliseconds: 280);

/// The first page of Report a problem: catch the problem in detail before writing about it.
/// Before the start it offers the three steps; once started it counts down and shows where the
/// user is in them.
class TraceSessionView extends StatelessWidget {
  const TraceSessionView({
    super.key,
    required this.t,
    required this.until,
    required this.disconnected,
    required this.onConnect,
  });

  final Translations t;

  /// When detailed logging ends; null before it started.
  final DateTime? until;

  /// The connection is down: step two gets a Connect button.
  final bool disconnected;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final s = t.dialogs.crashReport.trace;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final on = until != null;
    final minutes = TraceSessionNotifier.duration.inMinutes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // the hero: the pitch, then the live countdown in the same place
        AnimatedContainer(
          duration: _motion,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: (on ? colors.error : colors.primary).withValues(alpha: .35)),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: on
                  ? [colors.errorContainer.withValues(alpha: .4), colors.surfaceContainerHigh]
                  : [colors.primaryContainer.withValues(alpha: .7), colors.tertiaryContainer.withValues(alpha: .35)],
            ),
          ),
          child: AnimatedSwitcher(
            duration: _motion,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: Tween(begin: .96, end: 1.0).animate(animation), child: child),
            ),
            child: on
                ? _Countdown(key: const ValueKey('on'), until: until!, title: s.onTitle, msg: s.onMsg)
                : Row(
                    key: const ValueKey('offer'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Glow(
                        color: colors.primary,
                        child: Icon(FluentIcons.search_sparkle_24_filled, color: colors.onPrimary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.offerTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.offerMsg,
                              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 18),
        _TimelineStep(
          number: 1,
          title: s.step1(minutes: minutes),
          detail: on ? null : s.step1Msg,
          state: on ? _Step.done : _Step.active,
          last: false,
        ),
        _TimelineStep(
          number: 2,
          title: s.step2,
          detail: on && !disconnected ? s.step2Connected : s.step2Msg,
          state: on ? _Step.active : _Step.waiting,
          last: false,
          action: on && disconnected
              ? FilledButton.tonalIcon(
                  onPressed: onConnect,
                  icon: const Icon(FluentIcons.plug_connected_20_regular, size: 18),
                  label: Text(s.connect),
                )
              : null,
        ),
        _TimelineStep(number: 3, title: s.step3, detail: s.step3Msg, state: _Step.waiting, last: true),
        if (!on) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(FluentIcons.shield_checkmark_16_regular, size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.privacy(minutes: minutes),
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A slim strip over the description while detailed logging runs: the user came back to send.
class TraceSessionBanner extends StatelessWidget {
  const TraceSessionBanner({super.key, required this.t, required this.until, required this.onStop});

  final Translations t;
  final DateTime until;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final s = t.dialogs.crashReport.trace;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.errorContainer.withValues(alpha: .45),
        border: Border.all(color: colors.error.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          _PulseDot(color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Ticker(
                  until: until,
                  builder: (left) => Text(
                    s.bannerTitle(time: _mmss(left)),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(s.bannerMsg, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onStop,
            icon: const Icon(FluentIcons.stop_16_filled, size: 16),
            label: Text(s.stop),
          ),
        ],
      ),
    );
  }
}

String _mmss(Duration d) {
  final s = max(0, d.inSeconds);
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Rebuilds every second with the time left until [until].
class _Ticker extends StatefulWidget {
  const _Ticker({required this.until, required this.builder});

  final DateTime until;
  final Widget Function(Duration left) builder;

  @override
  State<_Ticker> createState() => _TickerState();
}

class _TickerState extends State<_Ticker> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(widget.until.difference(DateTime.now()));
}

/// A ring that empties as the time runs out, the minutes and seconds in it.
class _Countdown extends StatelessWidget {
  const _Countdown({super.key, required this.until, required this.title, required this.msg});

  final DateTime until;
  final String title;
  final String msg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final total = TraceSessionNotifier.duration.inMilliseconds;
    return Row(
      children: [
        _Ticker(
          until: until,
          builder: (left) => SizedBox.square(
            dimension: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(end: (left.inMilliseconds / total).clamp(0, 1)),
                  duration: const Duration(milliseconds: 900),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    color: colors.error,
                    backgroundColor: colors.error.withValues(alpha: .15),
                    constraints: const BoxConstraints.tightFor(width: 72, height: 72),
                  ),
                ),
                Text(
                  _mmss(left),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PulseDot(color: colors.error),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(msg, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A recording light: a dot with a ring breathing out of it.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final v = Curves.easeOut.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 6 + 8 * v,
                height: 6 + 8 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: .45 * (1 - v)),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The hero's icon on a soft halo of its own color.
class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Theme.of(context).colorScheme.tertiary, .55)!],
        ),
        boxShadow: [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Center(child: child),
    );
  }
}

enum _Step { waiting, active, done }

/// One step of three, joined to the next by a line down the side.
class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.number,
    required this.title,
    required this.state,
    required this.last,
    this.detail,
    this.action,
  });

  final int number;
  final String title;
  final String? detail;
  final _Step state;
  final bool last;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final active = state == _Step.active;

    final badge = AnimatedContainer(
      duration: _motion,
      curve: Curves.easeOutCubic,
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (state) {
          _Step.done => colors.primary,
          _Step.active => colors.primaryContainer,
          _Step.waiting => colors.surfaceContainerHighest,
        },
        border: active ? Border.all(color: colors.primary, width: 2) : null,
        boxShadow: active
            ? [BoxShadow(color: colors.primary.withValues(alpha: .25), blurRadius: 10, offset: const Offset(0, 3))]
            : const [],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: _motion,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
          child: state == _Step.done
              ? Icon(Icons.check_rounded, key: const ValueKey('done'), size: 18, color: colors.onPrimary)
              : Text(
                  '$number',
                  key: const ValueKey('n'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: active ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                badge,
                if (!last)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: AnimatedContainer(
                        duration: _motion,
                        width: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: state == _Step.done ? colors.primary : colors.outlineVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: last ? 4 : 16),
              child: AnimatedOpacity(
                duration: _motion,
                opacity: state == _Step.waiting ? .6 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (detail case final detail?) ...[
                      const SizedBox(height: 2),
                      Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                    if (action case final action?) ...[const SizedBox(height: 8), action],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
