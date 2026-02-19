import 'dart:convert';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/profile/details/json_editor.dart';
import 'package:hiddify/features/profile/details/profile_details_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfileDetailsPage extends HookConsumerWidget with PresLogger {
  const ProfileDetailsPage({super.key, required this.id});

  final String id;

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
    final provider = profileDetailsNotifierProvider(id);

    return ref
        .watch(ProfileDetailsNotifierProvider(id))
        .when(
          data: (data) {
            final isLoading = data.loadingState is AsyncLoading;
            final userOverride = data.profile.userOverride ?? const UserOverride();
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
            return Scaffold(
              appBar: AppBar(
                title: Text(t.pages.profileDetails.title),
                actions: [
                  TextButton.icon(
                    onPressed: isLoading || !data.isDetailsChanged
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              await ref.read(provider.notifier).save().then((success) {
                                ref
                                    .read(inAppNotificationControllerProvider)
                                    .showSuccessToast(t.pages.profiles.msg.save.success);
                                if (success && context.mounted) context.pop();
                              });
                            }
                          },
                    icon: const Icon(Icons.check),
                    label: Text(t.common.save),
                  ),
                  const Gap(8),
                ],
              ),
              body: ListView(
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: CustomTextFormField(
                            maxLines: 1,
                            initialValue: userOverride.name ?? data.profile.name,
                            validator: (value) =>
                                (value?.isEmpty ?? true) ? t.pages.profileDetails.form.emptyName : null,
                            onChanged: (value) => ref
                                .read(ProfileDetailsNotifierProvider(id).notifier)
                                .setUserOverride(userOverride.copyWith(name: value)),
                            label: t.common.name,
                            hint: t.pages.profileDetails.form.nameHint,
                          ),
                        ),
                        if (data.profile case RemoteProfileEntity(:final url))
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.common.url,
                                  style: theme.textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Gap(4),
                                SelectableText(
                                  url,
                                  style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        const Divider(indent: 16, endIndent: 16),
                        if (data.profile case RemoteProfileEntity(:final options)) ...[
                          SwitchListTile.adaptive(
                            title: Text(
                              t.pages.profileDetails.form.disableAutoUpdate,
                              style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.onSurface),
                            ),
                            value: userOverride.isAutoUpdateDisable,
                            onChanged: (value) => ref
                                .read(ProfileDetailsNotifierProvider(id).notifier)
                                .setUserOverride(userOverride.copyWith(isAutoUpdateDisable: value)),
                          ),
                          AnimatedSize(
                            alignment: Alignment.topCenter,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: !userOverride.isAutoUpdateDisable
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
                                                style: theme.textTheme.titleSmall!.copyWith(
                                                  color: theme.colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _genSliderText(t, userOverride.updateInterval ?? 0),
                                              style: theme.textTheme.labelSmall!.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Gap(4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Slider(
                                          focusNode: sliderFocusNode,
                                          value:
                                              userOverride.updateInterval?.toDouble() ??
                                              options?.updateInterval.inHours.toDouble() ??
                                              0.0,
                                          max: 96,
                                          divisions: 96,
                                          label: (userOverride.updateInterval ?? 0).toString(),
                                          onChanged: (double value) => ref
                                              .read(ProfileDetailsNotifierProvider(id).notifier)
                                              .setUserOverride(userOverride.copyWith(updateInterval: value.toInt())),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const Divider(indent: 16, endIndent: 16),
                        ],
                        ListTile(
                          title: Text(t.pages.profileDetails.lastUpdate),
                          leading: const Icon(FluentIcons.history_24_regular),
                          subtitle: Text(data.profile.lastUpdate.format()),
                          dense: true,
                        ),
                        if (data.profile case RemoteProfileEntity(:final subInfo?)) ...[
                          const Divider(indent: 16, endIndent: 16),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    style: Theme.of(context).textTheme.bodySmall,
                                    TextSpan(
                                      children: [
                                        _buildSubProp(
                                          FluentIcons.arrow_upload_16_regular,
                                          subInfo.upload.size(),
                                          t.components.subscriptionInfo.upload,
                                        ),
                                        const TextSpan(text: "     "),
                                        _buildSubProp(
                                          FluentIcons.arrow_download_16_regular,
                                          subInfo.download.size(),
                                          t.components.subscriptionInfo.download,
                                        ),
                                        const TextSpan(text: "     "),
                                        _buildSubProp(
                                          FluentIcons.arrow_bidirectional_up_down_16_regular,
                                          subInfo.total.size(),
                                          t.components.subscriptionInfo.total,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Gap(12),
                                  Text.rich(
                                    style: Theme.of(context).textTheme.bodySmall,
                                    TextSpan(
                                      children: [
                                        _buildSubProp(
                                          FluentIcons.clock_dismiss_20_regular,
                                          subInfo.expire.format(),
                                          t.components.subscriptionInfo.expireDate,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const Divider(),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: isJson(data.configContent)
                        ? JsonEditor(
                            expandedObjects: const ["outbounds", "endpoints"],
                            onChanged: (value) {
                              if (value == null) return;
                              try {
                                const encoder = JsonEncoder.withIndent('  ');
                                ref.read(provider.notifier).setContent(encoder.convert(value));
                              } catch (e) {
                                ref.read(provider.notifier).setContent("$value");
                              }
                            },
                            enableHorizontalScroll: true,
                            json: data.configContent,
                          )
                        : TextFormField(
                            onChanged: (value) {
                              ref.read(provider.notifier).setContent(value);
                            },
                            maxLines: null,
                            minLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(left: 5, top: 8, bottom: 8),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
          error: (error, stackTrace) => Scaffold(
            appBar: AppBar(title: Text(t.pages.profileDetails.title)),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FluentIcons.error_circle_12_filled),
                  Text(t.presentShortError(error)),
                  Text(error.toString()),
                ],
              ),
            ),
          ),
          loading: () => Scaffold(
            appBar: AppBar(title: Text(t.pages.profileDetails.title)),
            body: const Center(child: CircularProgressIndicator()),
          ),
        );
  }

  InlineSpan _buildSubProp(IconData icon, String text, String semanticLabel) {
    return TextSpan(
      children: [
        WidgetSpan(child: Icon(icon, size: 16, semanticLabel: semanticLabel)),
        const TextSpan(text: " "),
        TextSpan(text: text),
      ],
    );
  }
}

bool isJson(String value) {
  try {
    jsonDecode(value);
    return true;
  } catch (_) {
    return false;
  }
}
