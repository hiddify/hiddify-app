import 'package:flutter/material.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/home/widget/orca/glass_kit.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// One server row, drawn as a glass card (the selected one glows cyan).
class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(this.proxy, {super.key, required this.selected, required this.onTap});

  final OutboundInfo proxy;
  final bool selected;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final delay = proxy.urlTestDelay;
    final valid = ConnectionConst.isValidDelay(delay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: GlassCard(
        frosted: false, // many tiles in a list: skip the expensive backdrop blur
        radius: 22,
        highlight: selected,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: onTap,
        onLongPress: () async => await ref.read(dialogNotifierProvider.notifier).showProxyInfo(outboundInfo: proxy),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [OrcaColors.cyan, OrcaColors.violet]),
                boxShadow: [
                  BoxShadow(
                    color: OrcaColors.blue.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: ClipOval(
                child: IPCountryFlag(
                  countryCode: proxy.ipinfo.countryCode,
                  organization: proxy.ipinfo.org,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proxy.tagDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: OrcaColors.textPrimary,
                      fontFamily: PlatformUtils.isWindows ? FontFamily.emoji : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      text: proxy.type,
                      children: [
                        if (proxy.isGroup)
                          TextSpan(
                            text: ' (${proxy.groupSelectedTagDisplay.trim()})',
                            style: textTheme.bodySmall,
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: OrcaColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (delay != 0) ...[
              const SizedBox(width: 8),
              _DelayChip(delay: delay, valid: valid),
            ],
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: OrcaColors.cyan, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class _DelayChip extends StatelessWidget {
  const _DelayChip({required this.delay, required this.valid});

  final int delay;
  final bool valid;

  Color get _color => !valid
      ? Colors.redAccent
      : switch (delay) {
          < 800 => OrcaColors.success,
          < 1500 => Colors.orangeAccent,
          _ => Colors.redAccent,
        };

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: c.withValues(alpha: 0.8), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            valid ? '$delay ms' : '×',
            textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c),
          ),
        ],
      ),
    );
  }
}
