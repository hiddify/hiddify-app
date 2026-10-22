import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/profile/add/widgets/widgets.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FixBtns extends ConsumerWidget {
  const FixBtns({super.key, required this.height, this.blizzardPresentation = false});
  final double height;
  final bool blizzardPresentation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    final isDesktop = PlatformUtils.isDesktop && !blizzardPresentation;
    return LayoutBuilder(
      builder: (context, constraints) {
        var effectiveHeight = height;
        if (blizzardPresentation) {
          const gaps = AddProfileModalConst.fixBtnsGap * AddProfileModalConst.fixBtnsGapCount;
          final itemWidth = math.max(1.0, (constraints.maxWidth - gaps) / AddProfileModalConst.fixBtnsItemCount);
          final textWidth = math.max(1.0, itemWidth - 8);
          final style = Theme.of(context).textTheme.titleSmall!;
          final textScaler = MediaQuery.textScalerOf(context);
          final direction = Directionality.of(context);
          var labelHeight = 0.0;
          for (final label in [t.common.scanQr, t.common.clipboard, t.common.manually]) {
            final painter = TextPainter(
              text: TextSpan(text: label, style: style),
              textAlign: TextAlign.center,
              textDirection: direction,
              textScaler: textScaler,
            )..layout(maxWidth: textWidth);
            labelHeight = math.max(labelHeight, painter.height);
          }
          effectiveHeight = math.max(height, 20 + 24 + 8 + labelHeight);
        }
        return Row(
          children: [
            if (!isDesktop) ...[
              const Gap(AddProfileModalConst.fixBtnsGap),
              FixBtn(
                key: const ValueKey('add_by_qr_code_button'),
                height: effectiveHeight,
                title: t.common.scanQr,
                icon: blizzardPresentation ? Icons.qr_code_scanner_outlined : Icons.qr_code_scanner,
                wrapLabel: blizzardPresentation,
                onTap: () async {
                  final cr = await ref.read(dialogNotifierProvider.notifier).showQrScanner();
                  if (cr == null) return;
                  ref.read(addProfileNotifierProvider.notifier).addClipboard(cr);
                },
              ),
            ],
            const Gap(AddProfileModalConst.fixBtnsGap),
            FixBtn(
              key: const ValueKey('add_from_clipboard_button'),
              height: effectiveHeight,
              title: t.common.clipboard,
              icon: blizzardPresentation ? Icons.content_paste_outlined : Icons.content_paste,
              wrapLabel: blizzardPresentation,
              onTap: () async {
                final cr = await Clipboard.getData(Clipboard.kTextPlain).then((value) => value?.text ?? '');
                ref.read(addProfileNotifierProvider.notifier).addClipboard(cr);
              },
            ),
            const Gap(AddProfileModalConst.fixBtnsGap),
            FixBtn(
              key: const ValueKey('add_manually_button'),
              height: effectiveHeight,
              title: t.common.manually,
              icon: Icons.add,
              wrapLabel: blizzardPresentation,
              onTap: () {
                ref.read(addProfilePageNotifierProvider.notifier).goManual();
              },
            ),
            const Gap(AddProfileModalConst.fixBtnsGap),
          ],
        );
      },
    );
  }
}
