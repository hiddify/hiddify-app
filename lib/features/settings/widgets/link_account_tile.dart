import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/telemetry/telemetry_config.dart';
import 'package:hiddify/core/telemetry/telemetry_service.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Settings tile that lets the user link their Pasarguard account to this
/// device's anonymous installId.
///
/// Only visible when [TelemetryConfig.isEnabled] is true.
class LinkAccountTile extends HookConsumerWidget {
  const LinkAccountTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hide entirely when telemetry is compiled out.
    if (!TelemetryConfig.isEnabled) return const SizedBox.shrink();

    final prefs = ref.watch(sharedPreferencesProvider).requireValue;
    final linkedUsername = TelemetryService.getLinkedUsername(prefs);

    return ListTile(
      title: const Text('اتصال به حساب'),
      subtitle: linkedUsername != null
          ? Text(linkedUsername, style: const TextStyle(fontSize: 12))
          : const Text(
              'حساب پاسارگارد خود را متصل کنید',
              style: TextStyle(fontSize: 12),
            ),
      leading: const Icon(FluentIcons.person_link_24_regular),
      trailing: linkedUsername != null
          ? Icon(
              FluentIcons.checkmark_circle_24_filled,
              color: Theme.of(context).colorScheme.tertiary,
            )
          : null,
      onTap: () => _showLinkDialog(context, prefs, linkedUsername),
    );
  }

  Future<void> _showLinkDialog(
    BuildContext context,
    dynamic prefs,
    String? currentUsername,
  ) async {
    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => _LinkAccountDialog(initialValue: currentUsername),
    );

    if (result == null || !context.mounted) return;

    final username = result.trim();
    if (username.isEmpty) return;

    // Show a loading indicator via a brief toast.
    if (context.mounted) {
      const CustomToast('در حال ارسال...').show(context);
    }

    final ok = await TelemetryService.linkUser(prefs, username);

    if (!context.mounted) return;
    if (ok) {
      const CustomToast.success('حساب با موفقیت متصل شد').show(context);
    } else {
      const CustomToast.error('خطا در اتصال حساب. لطفاً دوباره تلاش کنید')
          .show(context);
    }
  }
}

// ── Dialog ──────────────────────────────────────────────────────────────

class _LinkAccountDialog extends HookWidget {
  const _LinkAccountDialog({this.initialValue});

  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialValue ?? '');
    final localizations = MaterialLocalizations.of(context);

    return AlertDialog(
      title: const Text('اتصال به حساب'),
      icon: const Icon(FluentIcons.person_link_24_regular),
      content: TextField(
        controller: controller,
        autofocus: true,
        textDirection: TextDirection.ltr,
        decoration: const InputDecoration(
          labelText: 'نام کاربری پاسارگارد',
          hintText: 'username',
          prefixIcon: Icon(FluentIcons.person_24_regular),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(localizations.cancelButtonLabel.toUpperCase()),
        ),
        TextButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.isNotEmpty) {
              Navigator.of(context).maybePop(value);
            }
          },
          child: Text(localizations.okButtonLabel.toUpperCase()),
        ),
      ],
    );
  }
}
