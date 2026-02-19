import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FreeProfileConsentDialog extends HookConsumerWidget {
  const FreeProfileConsentDialog({super.key, required this.title, required this.consent});
  final String title;
  final String consent;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: AlertDialogConst.boxConstraints,
        child: MarkdownBody(
          data: consent,
          // styleSheet: MarkdownStyleSheet(textAlign: WrapAlignment.spaceBetween),
          onTapLink: (text, href, title) => UriUtils.tryLaunch(Uri.parse(href!)),
        ),
      ),
      actions: [
        TextButton(child: Text(t.common.cancel), onPressed: () => context.pop(false)),
        TextButton(child: Text(t.common.kContinue), onPressed: () => context.pop(true)),
      ],
    );
  }
}
