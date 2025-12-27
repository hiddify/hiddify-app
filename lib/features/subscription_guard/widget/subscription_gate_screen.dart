import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/subscription_guard/notifier/subscription_guard_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SubscriptionGateScreen extends HookConsumerWidget {
  const SubscriptionGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final subscriptionGuard = ref.watch(subscriptionGuardProvider);
    final theme = Theme.of(context);

    final urlController = useTextEditingController();
    final isValidating = useState(false);
    final errorMessage = useState<String?>(null);

    Future<void> validateUrl() async {
      if (urlController.text.isEmpty) {
        errorMessage.value = "Please enter a subscription URL";
        return;
      }

      isValidating.value = true;
      errorMessage.value = null;

      try {
        final isValid = await ref.read(subscriptionGuardProvider.notifier).validateSubscription(urlController.text);

        if (!isValid) {
          errorMessage.value = "Invalid subscription. Only Go-bull subscriptions are accepted.";
        }
      } catch (e) {
        errorMessage.value = "Error validating subscription: $e";
      } finally {
        isValidating.value = false;
      }
    }

    Future<void> pasteFromClipboard() async {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        urlController.text = clipboardData!.text!;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Assets.images.logo.svg(width: 120, height: 120),
                const Gap(32),

                // Title
                Text(
                  'Go-bull',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(16),

                // Subtitle
                Text(
                  'Subscription Required',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const Gap(8),

                // Description
                Text(
                  'Please enter your Go-bull subscription URL to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(48),

                // Input field
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: 'Subscription URL',
                      hintText: 'https://...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(FluentIcons.link_24_regular),
                      suffixIcon: IconButton(
                        icon: const Icon(FluentIcons.clipboard_paste_24_regular),
                        onPressed: isValidating.value ? null : pasteFromClipboard,
                        tooltip: 'Paste from clipboard',
                      ),
                      errorText: errorMessage.value,
                    ),
                    enabled: !isValidating.value,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => validateUrl(),
                  ),
                ),
                const Gap(24),

                // Validate button
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: isValidating.value ? null : validateUrl,
                    icon: isValidating.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(FluentIcons.checkmark_24_regular),
                    label: Text(
                      isValidating.value ? 'Validating...' : 'Validate Subscription',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const Gap(32),

                // Info card
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.info_24_regular,
                        color: theme.colorScheme.primary,
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          'Only Go-bull subscription URLs are accepted. Contact support at t.me/go_bull for assistance.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
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
