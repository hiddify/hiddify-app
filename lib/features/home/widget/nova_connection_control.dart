import 'package:flutter/material.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';

class NovaConnectionControl extends StatelessWidget {
  const NovaConnectionControl({
    super.key,
    required this.enabled,
    required this.connected,
    required this.loading,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final bool connected;
  final bool loading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations || media.accessibleNavigation;
    final accent = !enabled
        ? nova.disabled
        : connected
        ? nova.accent
        : nova.secondaryText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          key: const ValueKey('home_connection_button'),
          button: true,
          enabled: enabled,
          label: label,
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              width: 168,
              height: 168,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: connected ? 0.34 : 0.16)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: connected ? 0.34 : 0.12),
                    blurRadius: connected ? 34 : 18,
                    spreadRadius: connected ? 4 : 0,
                  ),
                ],
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [if (connected) NovaColors.ritualRedContainer else nova.elevatedSurface, nova.background],
                  ),
                  border: Border.all(color: accent.withValues(alpha: connected ? 0.72 : 0.28)),
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: enabled ? onTap : null,
                    customBorder: const CircleBorder(),
                    splashColor: nova.accent.withValues(alpha: 0.18),
                    highlightColor: nova.accent.withValues(alpha: 0.08),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.power_settings_new_rounded,
                          size: 58,
                          color: accent,
                          shadows: connected ? const [Shadow(color: NovaColors.ritualRedGlow, blurRadius: 16)] : null,
                        ),
                        if (loading)
                          SizedBox(
                            width: 112,
                            height: 112,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: nova.accent,
                              backgroundColor: nova.border,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: NovaSpacing.md),
        Container(
          constraints: const BoxConstraints(minHeight: 30),
          padding: const EdgeInsets.symmetric(horizontal: NovaSpacing.lg, vertical: NovaSpacing.sm),
          decoration: BoxDecoration(
            color: connected ? nova.accentFill : nova.surface,
            borderRadius: BorderRadius.circular(NovaRadii.pill),
            border: Border.all(color: connected ? nova.accent.withValues(alpha: 0.32) : nova.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: !enabled
                  ? nova.disabled
                  : connected
                  ? nova.accentHover
                  : nova.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
