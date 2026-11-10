import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_notifier.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_panel.dart';
import 'package:hiddify/features/profile/add/phone_import/phone_import_server.dart';
import 'package:hiddify/features/profile/add/widgets/free_btns.dart';
import 'package:hiddify/features/profile/add/widgets/widgets.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddProfileModal extends HookConsumerWidget {
  const AddProfileModal({super.key, this.url});
  // static const warpConsentGiven = "warp_consent_given";
  final String? url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(addProfileNotifierProvider).isLoading;
    final currentWidget = ref.watch(addProfilePageNotifierProvider);
    ref.listen(freeSwitchNotifierProvider, (_, _) {});
    // On Android TV the sheet serves the page a phone sends a link to, while it is open; each
    // link waits for the user to import it here.
    if (ref.watch(isAndroidTvProvider).valueOrNull ?? false) {
      ref.listen(phoneImportProvider, (previous, next) {
        final seen = previous?.valueOrNull?.entries ?? const [];
        for (final entry in next.valueOrNull?.entries ?? const <PhoneEntry>[]) {
          if (!seen.contains(entry)) _reviewPhoneEntry(context, ref, entry);
        }
      });
    }
    ref.listen(addProfileNotifierProvider, (previous, next) {
      if (next case AsyncData(value: final _?)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && context.canPop()) context.pop();
        });
      }
    });

    useMemoized(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (url != null && context.mounted) {
        if (isLoading) return;
        ref.read(addProfileNotifierProvider.notifier).addClipboard(url!);
      }
    });
    return SafeArea(
      child: isLoading
          ? const ProfileLoading()
          : switch (currentWidget) {
              AddProfilePages.options => const AddProfileOptions(),
              AddProfilePages.manual => const AddProfileManual(),
            },
    );
  }

  Future<void> _reviewPhoneEntry(BuildContext context, WidgetRef ref, PhoneEntry entry) async {
    final import = await showDialog<bool>(
      context: context,
      builder: (_) => PhoneEntryDialog(entry: entry),
    );
    if (!context.mounted) return;
    ref.read(phoneImportProvider.notifier).handled(entry);
    if (import ?? false) await ref.read(addProfileNotifierProvider.notifier).addClipboard(entry.text);
  }
}

/// The add profile sheet's sizes as fractions of [height]. [initial], [min]
/// and [fullHeight] are in pixels, [max] is already a fraction.
///
/// On a low screen (a TV in landscape) the buttons alone can be taller than
/// 85% of it, or than all of it, while DraggableScrollableSheet asserts
/// min <= initial <= max <= 1. So the sheet may grow as far as the buttons
/// need, and the other two sizes are kept inside that.
@visibleForTesting
({double initial, double min, double max}) addProfileSheetSizes({
  required double initial,
  required double min,
  required double max,
  required double fullHeight,
  required double height,
}) {
  final maxSize = math.min(1.0, math.max(max, fullHeight / height));
  final initialSize = math.min(initial / height, maxSize);
  return (initial: initialSize, min: math.min(min / height, initialSize), max: maxSize);
}

class AddProfileOptions extends HookConsumerWidget {
  const AddProfileOptions({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final isLoadingProfile = ref.watch(addProfileNotifierProvider).isLoading;
    final freeSwitch = ref.watch(freeSwitchNotifierProvider);
    final isTv = ref.watch(isAndroidTvProvider).valueOrNull ?? false;
    // a TV has no camera to scan with, so it has the desktop's three buttons
    final threeButtons = PlatformUtils.isDesktop || isTv;
    // A TV screen in landscape has room for the buttons and one panel below them: with the phone
    // panel too, the free list got no height at all. So the free list takes the phone panel's
    // place while it is on; the sheet keeps serving the phone page meanwhile.
    final showPhonePanel = isTv && !freeSwitch;
    final isDesktop = PlatformUtils.isDesktop;
    final gapCount = threeButtons ? AddProfileModalConst.fixBtnsGapCountDesktop : AddProfileModalConst.fixBtnsGapCount;
    final itemCount = threeButtons
        ? AddProfileModalConst.fixBtnsItemCountDesktop
        : AddProfileModalConst.fixBtnsItemCount;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fixBtnsHeight = (constraints.maxWidth - AddProfileModalConst.fixBtnsGap * gapCount) / itemCount;
        final phoneHeight = showPhonePanel ? PhoneImportPanel.heightOf(context) + AddProfileModalConst.fixBtnsGap : 0;
        final fullHeight = fixBtnsHeight + phoneHeight + AddProfileModalConst.navBarHeight + 32;
        final initial = !freeSwitch ? fullHeight : fullHeight + 180;
        var min = !freeSwitch ? fullHeight : fullHeight + 100;
        var max = !freeSwitch ? fullHeight / constraints.maxHeight : 0.85;
        if (isDesktop) {
          min = initial;
          max = initial / constraints.maxHeight;
        }
        final sizes = addProfileSheetSizes(
          initial: initial,
          min: min,
          max: max,
          fullHeight: fullHeight,
          height: constraints.maxHeight,
        );
        return DraggableScrollableSheet(
          initialChildSize: sizes.initial,
          minChildSize: sizes.min,
          maxChildSize: sizes.max,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const Gap(AddProfileModalConst.fixBtnsGap),
              FixBtns(height: fixBtnsHeight, canScan: !isTv),
              if (showPhonePanel) ...[const Gap(AddProfileModalConst.fixBtnsGap), const PhoneImportPanel()],
              if (freeSwitch) Expanded(child: FreeBtns(scrollController: scrollController)) else const Spacer(),
              const NavBar(),
            ],
          ),
        );
      },
    );
  }
}

class AddProfileManual extends HookConsumerWidget {
  const AddProfileManual({super.key});

  String _genSliderText(Translations t, int sliderValue) {
    if (sliderValue == 0) {
      return t.common.auto;
    } else if (sliderValue < 24) {
      return t.common.interval.hour(n: sliderValue);
    }
    final day = t.common.interval.day(n: sliderValue ~/ 24);
    final hour = t.common.interval.hour(n: sliderValue % 24);
    return '$day $hour';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameTextController = useTextEditingController();
    final urlTextController = useTextEditingController();
    final isAutoUpdateDisable = useState<bool>(false);
    final updateInterval = useState(.0);
    final sliderFocusNode = useFocusNode(
      onKeyEvent: (node, event) {
        if (KeyboardConst.verticalArrows.contains(event.logicalKey) && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            node.previousFocus();
          } else {
            node.nextFocus();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 12),
            child: Row(
              children: [
                Expanded(child: Text(t.common.manually, style: theme.textTheme.headlineMedium)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(addProfilePageNotifierProvider.notifier).goOptions(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomTextFormField(
              maxLines: 1,
              controller: nameTextController,
              validator: (value) => (value?.isEmpty ?? true) ? t.pages.profileDetails.form.emptyName : null,
              label: t.common.name,
              hint: t.pages.profileDetails.form.nameHint,
            ),
          ),
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomTextFormField(
              maxLines: 1,
              controller: urlTextController,
              validator: (value) => (value != null && !isUrl(value)) ? t.pages.profileDetails.form.invalidUrl : null,
              label: t.common.url,
              hint: t.pages.profileDetails.form.urlHint,
            ),
          ),
          const Gap(12),
          SwitchListTile.adaptive(
            title: Text(
              t.pages.profileDetails.form.disableAutoUpdate,
              style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.onSurface),
            ),
            value: isAutoUpdateDisable.value,
            onChanged: (value) => isAutoUpdateDisable.value = value,
          ),
          AnimatedSize(
            alignment: Alignment.topCenter,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !isAutoUpdateDisable.value
                ? Column(
                    children: [
                      const Divider(indent: 16, endIndent: 16),
                      const Gap(12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.pages.profileDetails.form.autoUpdateInterval,
                                style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.onSurface),
                              ),
                            ),
                            Text(
                              _genSliderText(t, updateInterval.value.round()),
                              style: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const Gap(4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Slider(
                          focusNode: sliderFocusNode,
                          value: updateInterval.value,
                          max: 96,
                          divisions: 96,
                          label: updateInterval.value.round().toString(),
                          onChanged: (double value) => updateInterval.value = value,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    child: Text(t.common.add),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final i = updateInterval.value.toInt();
                        final interval = i > 0 ? i : null;
                        await ref
                            .read(addProfileNotifierProvider.notifier)
                            .addManual(
                              url: urlTextController.text.trim(),
                              userOverride: UserOverride(
                                name: nameTextController.text.trim(),
                                isAutoUpdateDisable: isAutoUpdateDisable.value,
                                updateInterval: interval,
                              ),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // const Gap(16),
        ],
      ),
    );
  }
}
