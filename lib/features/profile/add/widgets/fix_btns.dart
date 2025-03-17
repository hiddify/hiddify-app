import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/profile/add/widgets/widgets.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FixBtns extends ConsumerWidget {
  const FixBtns({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue.profile.add;
    final addProfileState = ref.watch(addProfileProvider);

    final isDesktop = PlatformUtils.isDesktop;
    return Row(
      children: [
        if (!isDesktop) ...[
          const Gap(AddProfileModalConst.fixBtnsGap),
          FixBtn(
            key: const ValueKey('add_by_qr_code_button'),
            height: height,
            title: t.scanQr,
            icon: Icons.qr_code_scanner,
            onTap: () async {
              final cr = await ref.read(dialogNotifierProvider.notifier).showQrScanner<String>();
              if (cr == null) return;
              if (addProfileState.isLoading) return;
              ref.read(addProfileProvider.notifier).add(cr);
            },
          ),
        ],
        const Gap(AddProfileModalConst.fixBtnsGap),
        FixBtn(
          key: const ValueKey('add_from_clipboard_button'),
          height: height,
          title: t.fromClipboard,
          icon: Icons.content_paste,
          onTap: () async {
            final captureResult = await Clipboard.getData(Clipboard.kTextPlain).then((value) => value?.text ?? '');
            if (addProfileState.isLoading) return;
            ref.read(addProfileProvider.notifier).add(captureResult);
          },
        ),
        const Gap(AddProfileModalConst.fixBtnsGap),
        FixBtn(
          key: const ValueKey('add_manually_button'),
          height: height,
          title: t.manually,
          icon: Icons.add,
          onTap: () {
            context.pop();
            ref.read(buttomSheetsNotifierProvider.notifier).showAddManualProfile();
          },
        ),
        const Gap(AddProfileModalConst.fixBtnsGap),
      ],
    );
  }
}
