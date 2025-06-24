import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxyInfoDialog extends HookConsumerWidget {
  const ProxyInfoDialog({super.key, required this.outboundInfo});

  final OutboundInfo outboundInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    return AlertDialog(
      title: SelectionArea(child: Text(outboundInfo.tagDisplay)),
      content: OutboundInfoWidget(outboundInfo: outboundInfo),
      actions: [
        TextButton(
          onPressed: context.pop,
          child: Text(t.general.close),
        ),
      ],
    );
  }
}
