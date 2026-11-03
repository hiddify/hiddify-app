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

/// A proxy's upload speed ([speed] bytes a second; 0 untested, -1 failed), and its download speed
/// ([downloadSpeed]) once tested: a spinner while one is [testing], the gauge alone before the first
/// test, the gauge with one cross when both failed. A speed from an earlier run ([cached],
/// [downloadCached]) shows faded until tested again. A tap tests the upload ([onTest]), or both when
/// both show; a long press the download ([onDownloadTest]), or without it sets how much a test
/// sends. [dense] fits it under
/// a proxy row's ping; else it is a pill.
class UploadSpeedChip extends ConsumerWidget {
  const UploadSpeedChip({
    super.key,
    required this.speed,
    required this.testing,
    this.cached = false,
    this.onTest,
    this.dense = false,
    this.downloadSpeed = 0,
    this.downloadTesting = false,
    this.downloadCached = false,
    this.onDownloadTest,
  });

  final int speed;
  final bool testing;
  final bool cached;
  final VoidCallback? onTest;
  final bool dense;
  final int downloadSpeed;
  final bool downloadTesting;
  final bool downloadCached;
  final VoidCallback? onDownloadTest;

  /// How much a speed from an earlier run fades.
  static const _cachedOpacity = .45;

  /// Below this screen width, a pill with both speeds shows them one over the other.
  static const _stackBelow = 480.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final showUp = speed != 0 || testing;
    final showDown = downloadSpeed != 0 || downloadTesting;
    final busy = testing || downloadTesting;
    // both tested, both failed: one cross says it
    final bothFailed = !busy && speed < 0 && downloadSpeed < 0;
    Color colorOf(int value, bool busy) => busy
        ? s.primary
        : value < 0
        ? s.error
        : value == 0
        ? s.onSurfaceVariant
        : uploadSpeedColor(context, value);
    final iconSize = dense ? 13.0 : 17.0;
    final number = (dense ? theme.textTheme.labelSmall : theme.textTheme.titleSmall)?.copyWith(
      fontWeight: dense ? FontWeight.w700 : FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final unit = dense
        ? theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: s.onSurfaceVariant, letterSpacing: .3)
        : theme.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant);

    // once tested, the arrows say what each number is: the gauge shows only before the first test;
    // both directions under a row's ping leave little room, so the unit gets smaller
    final both = showUp && showDown && !bothFailed;
    final gauge = !showUp && !showDown;
    Widget faded(bool old, Widget child) => old ? Opacity(opacity: _cachedOpacity, child: child) : child;

    // one direction: its arrow, then its value, a spinner, or a cross; faded when from an earlier run
    Widget part(int value, bool partBusy, IconData arrow, bool old, {required bool first}) {
      final color = colorOf(value, partBusy);
      return faded(
        old && !partBusy,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!first) Gap(dense ? 3 : 5),
            Icon(arrow, size: iconSize - 3, color: color),
            if (partBusy)
              SizedBox.square(
                dimension: iconSize - 4,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
              )
            else if (value < 0)
              Icon(Icons.close_rounded, size: iconSize - 1, color: color)
            else if (value > 0)
              Text(formatMbps(value), style: number?.copyWith(color: color)),
          ],
        ),
      );
    }

    final allOld = (!showUp || cached) && (!showDown || downloadCached) && !busy;
    // a pill on a small screen has no room for both on one line: the gauge, then a line each
    final stacked = !dense && both && MediaQuery.sizeOf(context).width < _stackBelow;
    Widget line(int value, bool lineBusy, IconData arrow, bool old) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        part(value, lineBusy, arrow, old, first: true),
        if (value > 0) faded(old, Text(' Mbps', style: unit?.copyWith(fontSize: 10))),
      ],
    );
    final Widget content = stacked
        ? Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line(speed, testing, Icons.arrow_upward_rounded, cached),
                  line(downloadSpeed, downloadTesting, Icons.arrow_downward_rounded, downloadCached),
                ],
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.ltr,
            children: bothFailed
                ? [
                    faded(
                      cached && downloadCached,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed_rounded, size: iconSize, color: s.error),
                          const Gap(2),
                          Icon(Icons.close_rounded, size: iconSize - 1, color: s.error),
                        ],
                      ),
                    ),
                  ]
                : [
                    if (gauge)
                      faded(
                        allOld && (showUp || showDown),
                        Icon(
                          Icons.speed_rounded,
                          size: iconSize,
                          color: busy ? s.primary : colorOf(showUp ? speed : downloadSpeed, false),
                        ),
                      ),
                    if (showUp) part(speed, testing, Icons.arrow_upward_rounded, cached, first: !gauge),
                    if (showDown)
                      part(
                        downloadSpeed,
                        downloadTesting,
                        Icons.arrow_downward_rounded,
                        downloadCached,
                        first: !gauge && !showUp,
                      ),
                    if (speed > 0 || downloadSpeed > 0)
                      faded(allOld, Text(' Mbps', style: dense && both ? unit?.copyWith(fontSize: 8) : unit)),
                  ],
          );

    final chip = InkWell(
      borderRadius: BorderRadius.circular(dense ? 6 : (stacked ? 14 : 16)),
      // with both speeds shown, a tap tests both again; the core tests one proxy's two in turn
      onTap: testing
          ? null
          : both && onDownloadTest != null && !downloadTesting
          ? () {
              onDownloadTest!();
              onTest?.call();
            }
          : onTest,
      onLongPress: onDownloadTest == null
          ? () => chooseUploadTestSize(ref)
          : downloadTesting
          ? null
          : onDownloadTest,
      child: Padding(
        padding: dense
            ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
            : stacked
            ? const EdgeInsetsDirectional.fromSTEB(10, 4, 12, 4)
            : EdgeInsets.symmetric(horizontal: !showUp && !showDown ? 8 : 11),
        // a row's room is fixed: big numbers shrink rather than overflow
        child: dense
            ? FittedBox(fit: BoxFit.scaleDown, child: content)
            : stacked
            ? content
            : SizedBox(height: 32, child: content),
      ),
    );
    return Tooltip(
      message: onDownloadTest == null
          ? t.pages.proxies.upload.test
          : both
          ? t.pages.proxies.upload.hintBoth
          : t.pages.proxies.upload.hint,
      child: dense
          ? chip
          : Material(
              color: s.onSurface.withValues(alpha: .06),
              // two lines tall, a rounded card rather than a pill
              shape: stacked ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)) : const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: AnimatedSize(duration: const Duration(milliseconds: 300), curve: Curves.easeOut, child: chip),
            ),
    );
  }
}
