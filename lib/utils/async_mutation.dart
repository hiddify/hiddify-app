// ignore_for_file: unreachable_switch_case

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'async_mutation.freezed.dart';

// TODO: test and improve

@freezed
class AsyncMutation with _$AsyncMutation {
  const AsyncMutation._();

  const factory AsyncMutation.idle() = Idle;
  const factory AsyncMutation.inProgress() = InProgress;
  const factory AsyncMutation.fail(Object error, StackTrace stackTrace) = Fail;
  const factory AsyncMutation.success() = Success;

  bool get isInProgress => this is InProgress;
}

/// temporary(and hacky) way to manage async mutations
({AsyncMutation state, ValueChanged<Future<T>> setFuture, ValueChanged<void Function(Object error)> setOnFailure})
useMutation<T>({void Function(Object error)? initialOnFailure, void Function()? initialOnSuccess}) {
  final mutationUpdate = useState<Future<T>?>(null);
  final mutationState = useFuture(mutationUpdate.value);
  final failureCallBack = useValueNotifier<void Function(Object error)?>(initialOnFailure);
  final successCallBack = useValueNotifier<void Function()?>(initialOnSuccess);

  final mapped = useMemoized(() {
    return switch (mutationState.connectionState) {
      ConnectionState.none => const Idle(),
      ConnectionState.waiting => const InProgress(),
      _ => mutationState.hasError ? Fail(mutationState.error!, mutationState.stackTrace!) : const Success(),
    };
  }, [mutationState]);

  // one-of callback in failure
  useMemoized(() {
    if (mapped case Fail(:final error)) {
      // if callback tries to build widget(show snackbar for example) this will prevent exceptions
      WidgetsBinding.instance.addPostFrameCallback((_) => failureCallBack.value?.call(error));
    }
    if (mapped case Success()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => successCallBack.value?.call());
    }
  }, [mapped, failureCallBack.value, successCallBack.value]);

  return (
    state: mapped,
    setFuture: (future) => mutationUpdate.value = future,
    setOnFailure: (onFailure) => failureCallBack.value = onFailure,
  );
}
