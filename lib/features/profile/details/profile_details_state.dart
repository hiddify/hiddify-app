import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'profile_details_state.freezed.dart';

@freezed
class ProfileDetailsState with _$ProfileDetailsState {
  const ProfileDetailsState._();

  const factory ProfileDetailsState({
    required AsyncValue<void> loadingState,
    required ProfileEntity profile,
    required String configContent,
    required bool isDetailsChanged,
  }) = _ProfileDetailsState;

  bool get isLoading => loadingState is AsyncLoading;
}
