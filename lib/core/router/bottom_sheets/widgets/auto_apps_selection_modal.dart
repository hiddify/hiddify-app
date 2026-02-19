import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/per_app_proxy/model/per_app_proxy_mode.dart';
import 'package:hiddify/features/per_app_proxy/overview/per_app_proxy_loading_notifier.dart';
import 'package:hiddify/features/per_app_proxy/overview/per_app_proxy_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AutoAppsSelectionModal extends HookConsumerWidget {
  const AutoAppsSelectionModal({super.key, required this.mode});

  final AppProxyMode mode;

  String _genSliderText(Translations t, int sliderValue) {
    final day = t.common.interval.day(n: sliderValue);
    return day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final loading = ref.watch(appProxyLoadingProvider);
    final isAutoEnabled = ref.watch(Preferences.autoAppsSelectionRegion) != null;
    final updateInterval = ref.watch(Preferences.autoAppsSelectionUpdateInterval);
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
    useEffect(() {
      if (!isAutoEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await ref
              .read(appProxyLoadingProvider.notifier)
              .doAsync(ref.read(PerAppProxyProvider(mode).notifier).applyAutoSelection);
        });
      }
      return null;
    }, []);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: Text(t.pages.settings.routing.perAppProxy.autoSelection.title),
              trailing: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: loading
                    ? const Padding(
                        padding: EdgeInsetsDirectional.only(end: 10),
                        child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator()),
                      )
                    : Switch.adaptive(
                        value: isAutoEnabled,
                        onChanged: (value) async {
                          final notifier = ref.read(appProxyLoadingProvider.notifier);
                          if (value) {
                            await notifier.doAsync(ref.read(PerAppProxyProvider(mode).notifier).applyAutoSelection);
                          } else {
                            await notifier.doAsync(ref.read(PerAppProxyProvider(mode).notifier).clearAutoSelected);
                            if (context.mounted) context.pop();
                          }
                        },
                      ),
              ),
            ),
            AnimatedSize(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isAutoEnabled
                  ? Column(
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.pages.settings.routing.perAppProxy.autoSelection.autoUpdateInterval,
                                  style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.onSurface),
                                ),
                              ),
                              Text(
                                _genSliderText(t, updateInterval.round()),
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
                            value: updateInterval,
                            min: 1,
                            max: 7,
                            divisions: 7,
                            label: updateInterval.round().toString(),
                            onChanged: (double value) {
                              ref.read(Preferences.autoAppsSelectionUpdateInterval.notifier).update(value);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: loading
                                      ? null
                                      : () async {
                                          await ref
                                              .read(appProxyLoadingProvider.notifier)
                                              .doAsync(ref.read(PerAppProxyProvider(mode).notifier).applyAutoSelection);
                                        },
                                  child: Text(t.pages.settings.routing.perAppProxy.autoSelection.performNow),
                                ),
                              ),
                              const Gap(8),
                              FilledButton.tonal(
                                onPressed: loading
                                    ? null
                                    : () async {
                                        await ref
                                            .read(appProxyLoadingProvider.notifier)
                                            .doAsync(
                                              ref.read(PerAppProxyProvider(mode).notifier).revertForceDeselection,
                                            );
                                      },
                                child: Text(t.pages.settings.routing.perAppProxy.autoSelection.resetToDefault),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
