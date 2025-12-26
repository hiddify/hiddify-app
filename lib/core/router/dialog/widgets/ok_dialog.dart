import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OkDialog extends HookConsumerWidget {
  const OkDialog({super.key, required this.title, required this.description});
  final String title;
  final String description;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: [TextButton(child: Text(t.common.ok), onPressed: () => context.pop())],
    );
  }
}
