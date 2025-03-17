import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

class AddManualProfileModal extends HookConsumerWidget {
  const AddManualProfileModal({super.key});

  String genSliderText(Translations t, int sliderValue) {
    if (sliderValue == 0) {
      return t.general.state.disable;
    } else if (sliderValue < 24) {
      return t.profile.interval.hour(n: sliderValue);
    }
    final day = t.profile.interval.day(n: sliderValue ~/ 24);
    final hour = t.profile.interval.hour(n: sliderValue % 24);
    return '$day $hour';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameTextController = useTextEditingController();
    final urlTextController = useTextEditingController();
    final updateInterval = useState(.0);
    final loading = useState(false);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: loading.value
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 92),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.profile.add.addingProfileMsg,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Gap(20),
                      const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                      ),
                    ],
                  ),
                )
              : Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Gap(16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CustomTextFormField(
                          maxLines: 1,
                          controller: nameTextController,
                          validator: (value) => (value?.isEmpty ?? true) ? t.profile.detailsForm.emptyNameMsg : null,
                          label: t.profile.detailsForm.nameLabel,
                          hint: t.profile.detailsForm.nameHint,
                        ),
                      ),
                      const Gap(16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CustomTextFormField(
                          maxLines: 1,
                          controller: urlTextController,
                          validator: (value) => (value != null && !isUrl(value)) ? t.profile.detailsForm.invalidUrlMsg : null,
                          label: t.profile.detailsForm.urlLabel,
                          hint: t.profile.detailsForm.urlHint,
                        ),
                      ),
                      const Gap(16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.profile.detailsForm.updateInterval,
                                style: theme.textTheme.titleSmall!.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              genSliderText(t, updateInterval.value.round()),
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
                          value: updateInterval.value,
                          max: 96,
                          divisions: 96,
                          label: updateInterval.value.round().toString(),
                          onChanged: (double value) {
                            updateInterval.value = value;
                          },
                        ),
                      ),
                      const Gap(8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FilledButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              loading.value = true;
                              final profile = RemoteProfileEntity(
                                id: const Uuid().v4(),
                                active: true,
                                name: nameTextController.text.trim(),
                                url: urlTextController.text.trim(),
                                options: updateInterval.value.toInt() == 0 ? null : ProfileOptions(updateInterval: Duration(hours: updateInterval.value.toInt())),
                                lastUpdate: DateTime.now(),
                              );
                              final profileRepo = await ref.read(profileRepositoryProvider.future);
                              final failureOrSuccess = await profileRepo.add(profile).run();
                              failureOrSuccess.fold((l) {
                                CustomAlertDialog.fromErr(t.presentError(l, action: t.profile.add.failureMsg)).show(context);
                                loading.value = false;
                              }, (r) {
                                CustomToast.success(t.profile.save.successMsg).show(context);
                                if (context.mounted) context.pop();
                              });
                            }
                          },
                          child: Text(t.general.add),
                        ),
                      ),
                      const Gap(16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
