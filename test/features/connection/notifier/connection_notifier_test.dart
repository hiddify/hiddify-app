import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/connection/data/connection_data_providers.dart';
import 'package:hiddify/features/connection/data/connection_repository.dart';
import 'package:hiddify/features/connection/model/connection_failure.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("mayConnect completes only after the repository connection completes", () async {
    SharedPreferences.setMockInitialValues(const {});
    final preferences = await SharedPreferences.getInstance();
    final profile = ProfileEntity.local(
      id: "profile-id",
      active: true,
      name: "test profile",
      lastUpdate: DateTime(2026),
    );
    final repository = _BlockingConnectionRepository();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => preferences),
        connectionRepositoryProvider.overrideWithValue(repository),
        activeProfileProvider.overrideWith(() => _FakeActiveProfile(profile)),
      ],
    );
    addTearDown(() {
      repository.completeAllConnections();
      container.dispose();
    });

    await container.read(sharedPreferencesProvider.future);
    expect(await container.read(connectionNotifierProvider.future), const ConnectionStatus.disconnected());

    var completed = false;
    final connection = container.read(connectionNotifierProvider.notifier).mayConnect().whenComplete(() {
      completed = true;
    });
    await Future<void>.delayed(Duration.zero);

    expect(repository.connectCalls, 1);
    expect(completed, isFalse);

    repository.completeConnection();
    await connection;
    expect(completed, isTrue);
  });

  test("concurrent mayConnect calls are ignored while a later call can run", () async {
    SharedPreferences.setMockInitialValues(const {});
    final preferences = await SharedPreferences.getInstance();
    final profile = ProfileEntity.local(
      id: "profile-id",
      active: true,
      name: "test profile",
      lastUpdate: DateTime(2026),
    );
    final repository = _BlockingConnectionRepository();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWith((ref) => preferences),
        connectionRepositoryProvider.overrideWithValue(repository),
        activeProfileProvider.overrideWith(() => _FakeActiveProfile(profile)),
      ],
    );
    addTearDown(() {
      repository.completeAllConnections();
      container.dispose();
    });

    await container.read(sharedPreferencesProvider.future);
    expect(await container.read(connectionNotifierProvider.future), const ConnectionStatus.disconnected());

    final first = container.read(connectionNotifierProvider.notifier).mayConnect();
    final concurrent = container.read(connectionNotifierProvider.notifier).mayConnect();
    await Future<void>.delayed(Duration.zero);
    expect(repository.connectCalls, 1);

    await concurrent;
    expect(repository.connectCalls, 1);

    repository.completeConnection();
    await first;

    final later = container.read(connectionNotifierProvider.notifier).mayConnect();
    await Future<void>.delayed(Duration.zero);
    expect(repository.connectCalls, 2);

    repository.completeConnection();
    await later;
  });
}

class _FakeActiveProfile extends ActiveProfile {
  _FakeActiveProfile(this.profile);

  final ProfileEntity profile;

  @override
  Stream<ProfileEntity?> build() => Stream.value(profile);
}

class _BlockingConnectionRepository implements ConnectionRepository {
  final _connections = <Completer<void>>[];

  int connectCalls = 0;

  void completeConnection() {
    final connection = _connections.firstWhere((connection) => !connection.isCompleted);
    connection.complete();
  }

  void completeAllConnections() {
    for (final connection in _connections) {
      if (!connection.isCompleted) connection.complete();
    }
  }

  @override
  SingboxConfigOption? get configOptionsSnapshot => null;

  @override
  TaskEither<ConnectionFailure, Unit> setup() => TaskEither.of(unit);

  @override
  Stream<ConnectionStatus> watchConnectionStatus() => Stream.value(const ConnectionStatus.disconnected());

  @override
  TaskEither<ConnectionFailure, Unit> connect(ProfileEntity activeProfile, bool disableMemoryLimit) {
    return TaskEither(() async {
      connectCalls++;
      final connection = Completer<void>();
      _connections.add(connection);
      await connection.future;
      return right(unit);
    });
  }

  @override
  TaskEither<ConnectionFailure, Unit> disconnect() => TaskEither.of(unit);

  @override
  TaskEither<ConnectionFailure, Unit> reconnect(ProfileEntity activeProfile, bool disableMemoryLimit) {
    return TaskEither.of(unit);
  }
}
