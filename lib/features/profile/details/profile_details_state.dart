import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'profile_details_state.freezed.dart';

@freezed
abstract class ProfileDetailsState with _$ProfileDetailsState {
  const ProfileDetailsState._();

  const factory ProfileDetailsState({
    required ProfileEntity profile,
    @Default(false) bool isEditing,
    @Default(false) bool showErrorMessages,
    AsyncValue<void>? save,
    AsyncValue<void>? update,
    AsyncValue<void>? delete,
    @Default("") String configContent,
    @Default(false) bool configContentChanged,
  }) = _ProfileDetailsState;

  bool get isBusy => save is AsyncLoading || delete is AsyncLoading || update is AsyncLoading;
}
