import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Result of the VPN (Mode B) admin_bgservice consent dialog.
enum VpnAdminBgDialogResult { connectWithAdmin, cancel }

/// Result of the proxy (Mode C) optional-admin dialog.
enum ProxyAdminBgDialogResult { runAsAdmin, continueWithout, cancel }

class VpnAdminBgServiceDialog extends ConsumerWidget {
  const VpnAdminBgServiceDialog({super.key, this.waiting = false});

  /// When true, show a waiting state (elevation / service starting) with Stop.
  final bool waiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final d = t.dialogs.adminBgService.vpnNeedsAdmin;

    return AlertDialog(
      title: Text(waiting ? d.waitingTitle : d.title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 468,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(waiting ? d.waitingMsg : d.msg),
              if (waiting) ...[
                const Gap(16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(VpnAdminBgDialogResult.cancel),
          child: Text(waiting ? d.stop : MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        if (!waiting)
          TextButton(
            onPressed: () => Navigator.of(context).pop(VpnAdminBgDialogResult.connectWithAdmin),
            child: Text(d.connectWithAdmin),
          ),
      ],
    );
  }
}

class ProxyAdminBgServiceDialog extends ConsumerStatefulWidget {
  const ProxyAdminBgServiceDialog({
    super.key,
    required this.proxies,
    this.elevationFailed = false,
  });

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
          onPressed: () => Navigator.of(context).pop(
            (ProxyAdminBgDialogResult.cancel, _neverAskAgain),
          ),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            (ProxyAdminBgDialogResult.continueWithout, _neverAskAgain),
          ),
          child: Text(d.continueWithoutAdmin),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            (ProxyAdminBgDialogResult.runAsAdmin, _neverAskAgain),
          ),
          child: Text(widget.elevationFailed ? d.tryAgain : d.runAsAdmin),
        ),
      ],
    );
  }
}
