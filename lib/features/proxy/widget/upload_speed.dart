import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The megabytes an upload test can send through each proxy.
const uploadTestSizes = [1, 5, 10, 50];

/// The bytes an upload test sends through each proxy, as the settings name.
int uploadTestBytes(Ref ref) => ref.read(ConfigOptions.uploadTestSize).clamp(1, 50) << 20;

/// Asks how many megabytes an upload test sends through each proxy, and keeps the answer.
Future<void> chooseUploadTestSize(WidgetRef ref) async {
  final t = ref.read(translationsProvider).requireValue;
  final size = await ref
      .read(dialogNotifierProvider.notifier)
      .showSettingRadio<int>(
        title: t.pages.settings.general.uploadTestSize,
        values: uploadTestSizes,
        value: ref.read(ConfigOptions.uploadTestSize),
        defaultValue: uploadTestSizes.first,
        t: {for (final n in uploadTestSizes) '$n': t.pages.settings.general.megabytes(n: n)},
      );
  if (size != null) await ref.read(ConfigOptions.uploadTestSize.notifier).update(size);
}

/// Megabits a second of [bytesPerSecond], as a speed test reports it: three decimals below 1, so a
/// slow proxy is not shown as 0 (40 kbit/s is 0.040), one below 10, none above.
String formatMbps(int bytesPerSecond) {
  final value = bytesPerSecond * 8 / 1e6;
  if (value < 1) return value.toStringAsFixed(3);
  return value < 10 ? value.toStringAsFixed(1) : value.round().toString();
}

/// The color of an upload speed, as pings have theirs: green for 10 Mbit/s or more, orange for 2
/// or more, red below.
Color uploadSpeedColor(BuildContext context, int bytesPerSecond) {
  final value = bytesPerSecond * 8 / 1e6;
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (value) {
    >= 10 => dark ? Colors.lightGreen : Colors.green,
    >= 2 => dark ? Colors.orange : Colors.deepOrangeAccent,
    _ => dark ? Colors.redAccent : Colors.red,
  };
}

/// A proxy's upload speed ([speed] bytes a second; 0 untested, -1 failed): a spinner while
/// [testing], the arrow alone before the first test. A tap tests again ([onTest]), a long press
/// sets how much a test sends. [dense] fits it under a proxy row's ping; else it is a pill.
class UploadSpeedChip extends ConsumerWidget {
  const UploadSpeedChip({super.key, required this.speed, required this.testing, this.onTest, this.dense = false});

  final int speed;
  final bool testing;
  final VoidCallback? onTest;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final failed = speed < 0 && !testing;
    final color = testing
        ? s.primary
        : failed
        ? s.error
        : speed == 0
        ? s.onSurfaceVariant
        : uploadSpeedColor(context, speed);
    final iconSize = dense ? 13.0 : 17.0;
    final number = (dense ? theme.textTheme.labelSmall : theme.textTheme.titleSmall)?.copyWith(
      color: testing ? s.onSurfaceVariant : color,
      fontWeight: dense ? FontWeight.w700 : FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final unit = dense
        ? theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: s.onSurfaceVariant, letterSpacing: .3)
        : theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        if (testing)
          SizedBox.square(
            dimension: iconSize - 3,
            child: CircularProgressIndicator(strokeWidth: dense ? 1.5 : 2, color: color),
          )
        else
          Icon(dense ? Icons.arrow_upward_rounded : FluentIcons.arrow_upload_24_regular, size: iconSize, color: color),
        if (failed) ...[
          const Gap(3),
          Icon(Icons.close_rounded, size: iconSize, color: color),
        ] else if (speed > 0) ...[
          Gap(dense ? 3 : 5),
          Text(formatMbps(speed), style: number),
          Text(' Mbps', style: unit),
        ],
      ],
    );

    final chip = InkWell(
      borderRadius: BorderRadius.circular(dense ? 6 : 16),
      onTap: testing ? null : onTest,
      onLongPress: () => chooseUploadTestSize(ref),
      child: Padding(
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
            : EdgeInsets.symmetric(horizontal: speed == 0 && !testing ? 8 : 11),
        child: dense ? content : SizedBox(height: 32, child: content),
      ),
    );
    return Tooltip(
      message: t.pages.proxies.upload.test,
      child: dense
          ? chip
          : Material(
              color: s.onSurface.withValues(alpha: .06),
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeOut, child: chip),
            ),
    );
  }
}
