import 'package:hiddify/features/chain/model/chain_enum.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chain_profile_notifier.g.dart';

@Riverpod(keepAlive: true)
class ChainProfileNotifier extends _$ChainProfileNotifier {
  ProfileRepository get _profilesRepo => ref.read(profileRepositoryProvider).requireValue;
  @override
  Future<ProfileEntity?> build(ChainType type) async {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    final id = switch (type) {
      ChainType.extraSecurity => ref.watch(ConfigOptions.extraSecurityProfileId),
      ChainType.unblocker => ref.watch(ConfigOptions.unblockerProfileId),
    };

    if (id != null) {
      final profile = await _profilesRepo.getById(id).map((event) => event).run();
      return profile.fold<ProfileEntity?>((l) => throw l, (r) {
        if (r == null) {
          // Not found
          switch (type) {
            case ChainType.extraSecurity:
              ref.watch(ConfigOptions.extraSecurityProfileId.notifier).update(activeProfile?.id);
            case ChainType.unblocker:
              ref.watch(ConfigOptions.unblockerProfileId.notifier).update(activeProfile?.id);
          }
          return activeProfile;
        }
        return r;
      });
    } else {
      switch (type) {
        case ChainType.extraSecurity:
          ref.watch(ConfigOptions.extraSecurityProfileId.notifier).update(activeProfile?.id);
        case ChainType.unblocker:
          ref.watch(ConfigOptions.unblockerProfileId.notifier).update(activeProfile?.id);
      }
      return activeProfile;
    }
  }
}
