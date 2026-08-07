import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/app_config.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/auth/widgets/telegram_login_webview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// First screen shown to unauthenticated users.
///
/// A deliberately minimal UI: a single prominent CTA ("Sign in with Telegram").
/// The actual Telegram OIDC handshake runs inside a [TelegramLoginWebView].
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  String? _webviewError;

  Future<void> _startTelegramLogin() async {
    if (!AppConfig.isConfigured) {
      setState(() => _webviewError = 'not_configured');
      return;
    }
    setState(() => _webviewError = null);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TelegramLoginDialog(
        onError: (message) => Navigator.of(context).pop(message),
      ),
    );

    if (!mounted || result == null) return;

    final authError = _translateWebviewError(result);
    if (authError != null) {
      setState(() => _webviewError = authError);
      return;
    }

    await ref.read(authNotifierProvider.notifier).loginWithTelegram(result);
  }

  String? _translateWebviewError(String key) {
    final t = ref.read(translationsProvider).requireValue;
    return switch (key) {
      'not_configured' => t.errors.auth.notConfigured,
      'telegram_login_error' => t.errors.auth.telegramLogin,
      'invalid_response' => t.errors.auth.invalidToken,
      _ => t.errors.auth.unexpected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final errorMessage = switch (authState) {
      AuthError(:final failure) => failure.present(t).type,
      _ => _webviewError,
    };

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.verified_user_rounded, size: 72, color: theme.colorScheme.primary),
                const Gap(16),
                Text(
                  t.pages.auth.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const Gap(8),
                Text(
                  t.pages.auth.subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Gap(32),
                FilledButton.icon(
                  onPressed: isLoading ? null : _startTelegramLogin,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.telegram),
                  label: Text(isLoading ? t.pages.auth.signingIn : t.pages.auth.signIn),
                ),
                if (errorMessage != null) ...[
                  const Gap(16),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hosts the [TelegramLoginWebView] in a dialog that pops with the extracted
/// `id_token` on success, or a (non-technical) error key on failure.
class _TelegramLoginDialog extends StatelessWidget {
  const _TelegramLoginDialog({required this.onError});

  final void Function(String message) onError;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 360,
        height: 480,
        child: TelegramLoginWebView(
          onResult: (idToken) => Navigator.of(context).pop(idToken),
          onError: onError,
        ),
      ),
    );
  }
}