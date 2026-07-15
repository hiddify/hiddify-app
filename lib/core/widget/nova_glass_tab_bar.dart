import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/router/adaptive_layout/nova_tab_route.dart';
import 'package:hiddify/core/theme/nova_tokens.dart';

class NovaGlassTabBar extends StatelessWidget {
  const NovaGlassTabBar({super.key, required this.selected, required this.labels, required this.onSelected});

  final NovaTab selected;
  final Map<NovaTab, String> labels;
  final ValueChanged<NovaTab> onSelected;

  static const _icons = <NovaTab, IconData>{
    NovaTab.home: Icons.home_rounded,
    NovaTab.servers: Icons.public_rounded,
    NovaTab.rules: Icons.shield_outlined,
    NovaTab.settings: Icons.settings_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    final shadowColor = Theme.of(context).shadowColor;
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations || media.accessibleNavigation;
    final highContrast = media.highContrast;
    final reduceEffects = reduceMotion || highContrast;
    final surface = DecoratedBox(
      key: const ValueKey('nova_dock_surface'),
      decoration: BoxDecoration(
        color: reduceEffects ? nova.elevatedSurface : nova.glass,
        borderRadius: BorderRadius.circular(NovaDockTokens.radius),
        border: Border.all(color: highContrast ? nova.separator : nova.border, width: highContrast ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: NovaSpacing.sm),
        child: Row(
          children: NovaTab.values
              .map(
                (tab) => Expanded(
                  child: _NovaTabItem(
                    tab: tab,
                    label: labels[tab] ?? tab.name,
                    icon: _icons[tab]!,
                    selected: tab == selected,
                    reduceMotion: reduceMotion,
                    highContrast: highContrast,
                    onTap: () {
                      if (tab != selected) HapticFeedback.selectionClick();
                      onSelected(tab);
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );

    return PositionedDirectional(
      start: NovaDockTokens.horizontalInset,
      end: NovaDockTokens.horizontalInset,
      bottom: media.padding.bottom + NovaDockTokens.bottomGap,
      height: NovaDockTokens.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NovaDockTokens.radius),
          boxShadow: [
            BoxShadow(color: shadowColor.withValues(alpha: 0.34), blurRadius: 32, offset: const Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(NovaDockTokens.radius),
          child: reduceEffects
              ? surface
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: NovaDockTokens.blur, sigmaY: NovaDockTokens.blur),
                  child: surface,
                ),
        ),
      ),
    );
  }
}

class _NovaTabItem extends StatelessWidget {
  const _NovaTabItem({
    required this.tab,
    required this.label,
    required this.icon,
    required this.selected,
    required this.reduceMotion,
    required this.highContrast,
    required this.onTap,
  });

  final NovaTab tab;
  final String label;
  final IconData icon;
  final bool selected;
  final bool reduceMotion;
  final bool highContrast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nova = NovaThemeData.of(context);
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 220);
    final inactiveColor = highContrast ? nova.secondaryText : nova.tertiaryText;

    return Semantics(
      key: ValueKey('nova_tab_${tab.name}'),
      label: label,
      button: true,
      selected: selected,
      container: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(NovaRadii.extraLarge),
            child: Center(
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minWidth: NovaAccessibilityTokens.minimumTapTarget),
                padding: const EdgeInsets.symmetric(horizontal: NovaSpacing.md, vertical: NovaSpacing.xs),
                decoration: BoxDecoration(
                  color: selected ? nova.accentFill : Colors.transparent,
                  borderRadius: BorderRadius.circular(NovaRadii.extraLarge),
                ),
                transform: reduceMotion || !selected ? null : Matrix4.diagonal3Values(1.02, 1.02, 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 20, color: selected ? nova.accentHover : inactiveColor),
                    const SizedBox(height: NovaSpacing.xxs),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: selected ? nova.accentHover : inactiveColor,
                        fontSize: 11,
                        height: 1,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
