import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RegionDialog extends HookConsumerWidget {
  const RegionDialog({super.key, required this.selected});

  final Region selected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return SimpleDialog(
      title: Text(t.pages.settings.routing.region),
      children: Region.values
          .map((e) => RadioListTile(title: Text(e.present(t)), value: e, groupValue: selected, onChanged: context.pop))
          .toList(),
    );
  }
}
