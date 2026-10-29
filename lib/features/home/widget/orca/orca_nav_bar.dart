import 'package:flutter/material.dart';

import 'glass_kit.dart';
import 'orca_strings.dart';

enum OrcaTab { home, servers, stats, settings }

/// Floating glass bottom bar: Home / Servers / Stats / Settings.
/// Stateless — the shell decides what each tab does.
class OrcaNavBar extends StatelessWidget {
  const OrcaNavBar({
    super.key,
    required this.selected,
    required this.onTap,
  });

  final OrcaTab selected;
  final ValueChanged<OrcaTab> onTap;

  @override
  Widget build(BuildContext context) {
    final s = OrcaStrings.of(context);
    final items = <(OrcaTab, IconData, String)>[
      (OrcaTab.home, Icons.home_rounded, s.navHome),
      (OrcaTab.servers, Icons.storage_rounded, s.navServers),
      (OrcaTab.stats, Icons.bar_chart_rounded, s.navStats),
      (OrcaTab.settings, Icons.settings_outlined, s.navSettings),
    ];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: GlassCard(
            radius: 34,
            blur: 28,
            glow: OrcaColors.cyan,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Row(
              children: [
                for (final it in items)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(it.$1),
                      child: _NavItem(
                        icon: it.$2,
                        label: it.$3,
                        active: it.$1 == selected,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? OrcaColors.cyan : const Color(0xFFA9B3EA);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 32,
          color: color,
          shadows: [
            if (active)
              Shadow(color: OrcaColors.cyan.withValues(alpha: 0.9), blurRadius: 14),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: active ? 48 : 0,
          height: 3,
          decoration: BoxDecoration(
            color: OrcaColors.cyan,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: OrcaColors.cyan.withValues(alpha: 0.9),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
