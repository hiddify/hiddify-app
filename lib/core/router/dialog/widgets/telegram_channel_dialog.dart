import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/utils/uri_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Invites the user to the official Telegram channel, for news, new releases and help.
class TelegramChannelDialog extends HookConsumerWidget {
  const TelegramChannelDialog({super.key});

  static const _telegramBlue = Color(0xFF229ED9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final text = t.dialogs.telegramChannel;
    return AlertDialog(
      icon: const Icon(Icons.telegram, color: _telegramBlue, size: 48),
      title: Text(text.title),
      content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: Text(text.msg)),
      actions: [
        TextButton(onPressed: () => context.pop(), child: Text(t.common.later)),
        FilledButton.icon(
          icon: const Icon(Icons.telegram),
          label: Text(text.join),
          onPressed: () async {
            context.pop();
            await UriUtils.tryLaunch(Uri.parse(Constants.telegramChannelUrl));
          },
        ),
      ],
    );
  }
}
