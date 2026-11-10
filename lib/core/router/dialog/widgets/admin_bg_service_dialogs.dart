import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Result of the VPN (Mode B) admin_bgservice consent dialog.
enum VpnAdminBgDialogResult { connectWithAdmin, switchToSystemProxy, cancel }

/// Result of the proxy (Mode C) optional-admin dialog.
enum ProxyAdminBgDialogResult { runAsAdmin, continueWithout, cancel }

bool get _isAppImage => Platform.isLinux && (Platform.environment['APPIMAGE'] ?? '').isNotEmpty;

/// VPN mode needs an administrator once (Windows, Linux and macOS outside the App Store). A standard
/// alert dialog: both modes by name, as list tiles, with what each covers in plain words; VPN mode
/// asks for administrator permission, system proxy mode for nothing. [waiting] while the system's
/// permission prompt is up, with the step to take there: Back, or refusing that prompt, comes back
/// to this choice.
class VpnAdminBgServiceDialog extends ConsumerWidget {
  const VpnAdminBgServiceDialog({super.key, this.waiting = false});

  /// When true, show a waiting state (elevation / service starting) with Stop.
  final bool waiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final d = t.dialogs.adminBgService.vpnNeedsAdmin;
    void close(VpnAdminBgDialogResult result) => Navigator.of(context).pop(result);

    if (waiting) {
      final (platformIcon, step) = Platform.isWindows
          ? (Icons.desktop_windows_outlined, d.waitingWindows)
          : Platform.isMacOS
          ? (Icons.laptop_mac_outlined, d.waitingMac)
          : (Icons.computer_outlined, d.waitingLinux);
      final theme = Theme.of(context);
      return AlertDialog(
        icon: const Icon(Icons.admin_panel_settings_outlined),
        title: Text(d.waitingTitle),
        content: ConstrainedBox(
          constraints: AlertDialogConst.boxConstraints,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(d.waitingMsg, textAlign: TextAlign.center),
              const Gap(16),
              Card.filled(
                margin: EdgeInsets.zero,
                color: theme.colorScheme.secondaryContainer,
                child: ListTile(
                  leading: Icon(platformIcon, color: theme.colorScheme.onSecondaryContainer),
                  title: Text(d.waitingWhere),
                  subtitle: Text(
                    step,
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                  ),
                ),
              ),
              const Gap(20),
              const LinearProgressIndicator(borderRadius: BorderRadius.all(Radius.circular(4))),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => close(VpnAdminBgDialogResult.cancel), child: Text(d.back))],
      );
    }

    return AlertDialog(
      icon: const Icon(Icons.shield_outlined),
      title: Text(d.title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: SingleChildScrollView(
          child: _ModeChoices(
            vpn: _ModeCard(
              icon: Icons.apps_rounded,
              title: d.vpnMode,
              covers: d.allApps,
              requirement: _isAppImage ? d.needsAdminAppImage : d.needsAdmin,
              requirementIcon: Icons.admin_panel_settings_outlined,
              action: d.useVpn,
              badge: d.recommended,
              help: _ModeHelp(
                what: d.helpVpn.what,
                pros: d.helpVpn.pros,
                cons: d.helpVpn.cons,
                prosTitle: d.helpProsTitle,
                consTitle: d.helpConsTitle,
                whatTitle: d.helpWhatTitle,
                tooltip: d.helpTooltip,
              ),
              onTap: () => close(VpnAdminBgDialogResult.connectWithAdmin),
            ),
            systemProxy: _ModeCard(
              icon: Icons.web_rounded,
              title: d.systemProxyMode,
              covers: d.someApps,
              footnote: d.someAppsExcept,
              requirement: d.noAdmin,
              requirementIcon: Icons.check_circle_outline,
              action: d.useSystemProxy,
              help: _ModeHelp(
                what: d.helpSystemProxy.what,
                pros: d.helpSystemProxy.pros,
                cons: d.helpSystemProxy.cons,
                prosTitle: d.helpProsTitle,
                consTitle: d.helpConsTitle,
                whatTitle: d.helpWhatTitle,
                tooltip: d.helpTooltip,
              ),
              onTap: () => close(VpnAdminBgDialogResult.switchToSystemProxy),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => close(VpnAdminBgDialogResult.cancel),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}

/// The two modes side by side, of equal height, with their requirements lined up at the bottom;
/// one above the other in a narrow window. Decided by the window, as an alert dialog measures its
/// content first, which a LayoutBuilder can not take part in.
class _ModeChoices extends StatelessWidget {
  const _ModeChoices({required this.vpn, required this.systemProxy});

  final _ModeCard vpn;
  final _ModeCard systemProxy;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 600) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [vpn, const Gap(12), systemProxy],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: vpn.sideBySide()),
          const Gap(12),
          Expanded(child: systemProxy.sideBySide()),
        ],
      ),
    );
  }
}

/// One mode to pick: its icon, name and which apps it covers on top; what it needs and the button
/// that picks it at the bottom, lined up with the other card's. The card with a [badge] is the
/// recommended one: a band across its top names it, and it is filled and outlined in the primary
/// color, with a filled button. The whole card picks it too.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.covers,
    required this.requirement,
    required this.requirementIcon,
    required this.action,
    required this.help,
    required this.onTap,
    this.badge,
    this.footnote,
    this.fill = false,
  });

  /// The same card filling the height of its row, its requirement and button at the bottom.
  _ModeCard sideBySide() => _ModeCard(
    icon: icon,
    title: title,
    covers: covers,
    requirement: requirement,
    requirementIcon: requirementIcon,
    action: action,
    help: help,
    onTap: onTap,
    badge: badge,
    footnote: footnote,
    fill: true,
  );

  final IconData icon;
  final String title;

  /// Which apps go through it.
  final String covers;

  /// What it needs, beside [requirementIcon].
  final String requirement;
  final IconData requirementIcon;

  /// The button's label.
  final String action;

  /// The explanation behind the card's help button.
  final _ModeHelp help;
  final VoidCallback onTap;
  final String? badge;

  /// Under [covers]: what it leaves out.
  final String? footnote;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final badge = this.badge;
    final footnote = this.footnote;
    final recommended = badge != null;
    final fg = recommended ? s.onSecondaryContainer : s.onSurface;
    final muted = recommended ? s.onSecondaryContainer.withValues(alpha: .75) : s.onSurfaceVariant;
    final button = recommended
        ? FilledButton(
            onPressed: onTap,
            child: Text(action, textAlign: TextAlign.center),
          )
        : OutlinedButton(
            onPressed: onTap,
            child: Text(action, textAlign: TextAlign.center),
          );

    // A band across the top names the recommended card; the other keeps the room, so both line up.
    // A band across the top names the recommended card; the other keeps the room, so both line up.
    // The help button sits at its end on both.
    final band = SizedBox(
      height: 36,
      child: ColoredBox(
        color: recommended ? s.primary : Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (recommended)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 18, color: s.onPrimary),
                  const Gap(6),
                  Text(
                    badge,
                    style: theme.textTheme.labelLarge?.copyWith(color: s.onPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            PositionedDirectional(
              end: 2,
              child: IconButton(
                tooltip: help.tooltip,
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                color: recommended ? s.onPrimary : s.onSurfaceVariant,
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () async {
                  final use = await showDialog<bool>(
                    context: context,
                    builder: (context) => _ModeHelpDialog(icon: icon, title: title, help: help, action: action),
                  );
                  if (use ?? false) onTap();
                },
              ),
            ),
          ],
        ),
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 30,
              backgroundColor: recommended ? s.primary : s.surfaceContainerHighest,
              child: Icon(icon, size: 32, color: recommended ? s.onPrimary : s.onSurfaceVariant),
            ),
          ),
          const Gap(14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
          const Gap(2),
          Text(
            covers,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          if (footnote != null) ...[
            const Gap(2),
            Text(
              footnote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          if (fill) const Spacer(),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(requirementIcon, size: 16, color: muted),
              const Gap(6),
              Flexible(
                child: Text(requirement, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
              ),
            ],
          ),
          const Gap(10),
          button,
        ],
      ),
    );

    final body = InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          band,
          if (fill) Expanded(child: content) else content,
        ],
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: recommended ? BorderSide(color: s.primary, width: 2) : BorderSide(color: s.outlineVariant),
    );
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: shape,
      color: recommended ? s.secondaryContainer : Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}

/// What a mode's help explains: how it works, what is good about it, and what to keep in mind.
class _ModeHelp {
  const _ModeHelp({
    required this.what,
    required this.pros,
    required this.cons,
    required this.whatTitle,
    required this.prosTitle,
    required this.consTitle,
    required this.tooltip,
  });

  final String what;
  final List<String> pros;
  final List<String> cons;
  final String whatTitle;
  final String prosTitle;
  final String consTitle;

  /// The help button's tooltip.
  final String tooltip;
}

/// A mode explained in full, from its card's help button. Pops true when the user picks the mode
/// from here.
class _ModeHelpDialog extends StatelessWidget {
  const _ModeHelpDialog({required this.icon, required this.title, required this.help, required this.action});

  final IconData icon;
  final String title;
  final _ModeHelp help;
  final String action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;

    Widget section(IconData sectionIcon, Color color, String heading, List<String> points) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(sectionIcon, size: 20, color: color),
            const Gap(8),
            Text(heading, style: theme.textTheme.titleSmall?.copyWith(color: color)),
          ],
        ),
        const Gap(8),
        for (final point in points)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(Icons.circle, size: 6, color: s.onSurfaceVariant),
                ),
                const Gap(12),
                Expanded(child: Text(point, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );

    return AlertDialog(
      icon: Icon(icon),
      title: Text(title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card.filled(
                margin: EdgeInsets.zero,
                color: s.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(help.whatTitle, style: theme.textTheme.titleSmall?.copyWith(color: s.primary)),
                      const Gap(6),
                      Text(help.what, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ),
              const Gap(20),
              section(Icons.thumb_up_alt_outlined, s.primary, help.prosTitle, help.pros),
              const Gap(8),
              section(Icons.info_outline_rounded, s.tertiary, help.consTitle, help.cons),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(action)),
      ],
    );
  }
}

class ProxyAdminBgServiceDialog extends ConsumerStatefulWidget {
  const ProxyAdminBgServiceDialog({super.key, required this.proxies, this.elevationFailed = false});

  final List<AdminNeededProxy> proxies;
  final bool elevationFailed;

  @override
  ConsumerState<ProxyAdminBgServiceDialog> createState() => _ProxyAdminBgServiceDialogState();
}

class _ProxyAdminBgServiceDialogState extends ConsumerState<ProxyAdminBgServiceDialog> {
  bool _neverAskAgain = false;
  bool _showConfigs = false;

  bool get neverAskAgain => _neverAskAgain;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final d = t.dialogs.adminBgService.proxyNeedsAdmin;

    return AlertDialog(
      title: Text(widget.elevationFailed ? d.elevationFailedTitle : d.title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 468,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.elevationFailed ? d.elevationFailedMsg : d.msg),
              const Gap(8),
              if (widget.proxies.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _showConfigs = !_showConfigs),
                  child: Text(_showConfigs ? d.hideConfigs : d.seeConfigs),
                ),
              if (_showConfigs)
                ...widget.proxies.map(
                  (p) => ListTile(
                    dense: true,
                    title: Text(p.summary.isNotEmpty ? p.summary : p.tag),
                    subtitle: p.detail.isNotEmpty ? Text(p.detail) : null,
                  ),
                ),
              CheckboxListTile(
                value: _neverAskAgain,
                title: Text(d.neverAskAgain),
                onChanged: (value) => setState(() => _neverAskAgain = value ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop((ProxyAdminBgDialogResult.cancel, _neverAskAgain)),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop((ProxyAdminBgDialogResult.continueWithout, _neverAskAgain)),
          child: Text(d.continueWithoutAdmin),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop((ProxyAdminBgDialogResult.runAsAdmin, _neverAskAgain)),
          child: Text(widget.elevationFailed ? d.tryAgain : d.runAsAdmin),
        ),
      ],
    );
  }
}
