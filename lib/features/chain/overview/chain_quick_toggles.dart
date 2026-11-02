import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/features/chain/overview/chain_mode_icon.dart';
import 'package:hiddify/features/chain/overview/chain_mode_menu.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The chain in the quick settings as two independent-looking switches, extra security first.
/// Only one can be on: there is a single chain status, so switching one on switches the other off.
/// The previous layout is [ChainQuickSettings]; the quick settings sheet picks between them.
class ChainQuickToggles extends StatelessWidget {
  const ChainQuickToggles({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _ChainRow(type: ChainType.extraSecurity),
      Divider(height: 2, thickness: 2),
      _ChainRow(type: ChainType.unblocker),
    ],
  );
}

const _duration = Duration(milliseconds: 280);
const _curve = Curves.easeOutCubic;

/// Hints shown one by one under the title while the feature is on.
List<String> _tips(Translations t, ChainType type, ChainMode mode) {
  final q = t.pages.settings.chain.quick;
  return switch (type) {
    ChainType.extraSecurity => [
      q.extraSecurity.ipBy(mode: mode.present(t)),
      q.extraSecurity.notTracked,
      q.extraSecurity.forPublic,
      q.extraSecurity.slower,
    ],
    ChainType.unblocker => [
      q.unblocker.mayConnect,
      q.unblocker.personalOnly,
      q.unblocker.notForPublic,
      q.unblocker.slower,
    ],
  };
}

/// One feature as a row like the others in the sheet: a tap on the row turns it on or off, the method
/// button opens the menu in place (off, Psiphon, WARP, configuration). Its icon lights up while on.
class _ChainRow extends HookConsumerWidget {
  const _ChainRow({required this.type});

  final ChainType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final on = type.isEnable(ref.watch(ConfigOptions.chainStatus));
    final mode = switch (type) {
      ChainType.extraSecurity => ref.watch(ConfigOptions.extraSecurityMode),
      ChainType.unblocker => ref.watch(ConfigOptions.unblockerMode),
    };
    final q = t.pages.settings.chain.quick;
    final title = type.isExtraSecurity() ? q.extraSecurity.title : q.unblocker.title;
    final subtitle = type.isExtraSecurity() ? q.extraSecurity.subtitle : q.unblocker.subtitle;

    // the hints turn slowly, only while on; a new mode starts them over
    final tips = _tips(t, type, mode);
    final tip = useState(0);
    useEffect(() {
      tip.value = 0;
      if (!on) return null;
      final timer = Timer.periodic(const Duration(seconds: 5), (_) => tip.value = (tip.value + 1) % tips.length);
      return timer.cancel;
    }, [on, mode]);

    Future<void> setOn(bool value) => ref
        .read(ConfigOptions.chainStatus.notifier)
        .update(value ? ChainStatus.values.byName(type.name) : ChainStatus.off);

    final muted = scheme.onSurfaceVariant;
    return ListTile(
      // green shield for extra security, orange key for the unblocker; grey and still while off
      // drawn at 22, shown a little larger so it reads at a glance
      leading: Transform.scale(
        scale: 1.15,
        child: ChainTypeIcon(type: type, mode: mode, animate: on),
      ),
      title: Text(title),
      subtitle: _SlidingText(
        on ? tips[tip.value % tips.length] : subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: on ? scheme.primary : muted),
      ),
      onTap: () => setOn(!on),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChainModeMenu(
            (context, toggleVisibility, _) => TextButton(
              onPressed: toggleVisibility,
              style: TextButton.styleFrom(
                foregroundColor: on ? scheme.onSurface : muted,
                padding: const EdgeInsetsDirectional.only(start: 10, end: 4),
                minimumSize: const Size(0, 36),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: _duration,
                    switchInCurve: _curve,
                    switchOutCurve: _curve,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: Tween(begin: .85, end: 1.0).animate(animation), child: child),
                    ),
                    child: on
                        ? Row(
                            key: ValueKey(mode),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ChainModeIcon(mode: mode),
                              const Gap(6),
                              Text(mode.present(t), style: theme.textTheme.labelLarge),
                            ],
                          )
                        : Text(
                            q.off,
                            key: const ValueKey('off'),
                            style: theme.textTheme.labelLarge?.copyWith(color: muted),
                          ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded, size: 20),
                ],
              ),
            ),
            type: type,
            showConfiguration: true,
          ),
        ],
      ),
    );
  }
}

/// One line whose text changes in turn: the old text fades out in the first half, then the new one
/// fades in with a small lift, so the two never share the line.
class _SlidingText extends StatelessWidget {
  const _SlidingText(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 560),
    // for the outgoing text the animation runs backwards, so this interval is its first half
    switchInCurve: const Interval(.5, 1, curve: Curves.easeOutCubic),
    switchOutCurve: const Interval(.5, 1, curve: Curves.easeInCubic),
    layoutBuilder: (current, previous) =>
        Stack(alignment: AlignmentDirectional.centerStart, children: [...previous, ?current]),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .25), end: Offset.zero).animate(animation),
        child: child,
      ),
    ),
    child: Text(text, key: ValueKey(text), maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
  );
}
