import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';

void main() {
  final now = DateTime(2026, 11, 9);
  final lastUpdate = DateTime(2026, 11);

  RemoteProfileEntity remote(String id, {SubscriptionInfo? subInfo}) =>
      ProfileEntity.remote(
            id: id,
            active: false,
            name: id,
            url: 'https://example.com/$id',
            lastUpdate: lastUpdate,
            subInfo: subInfo,
          )
          as RemoteProfileEntity;

  SubscriptionInfo info({int used = 0, int total = 100, DateTime? expire}) =>
      SubscriptionInfo(upload: 0, download: used, total: total, expire: expire ?? DateTime(2027));

  Map<String, InactiveReason> reasons(List<ProfileEntity> profiles, [Map<String, DateTime> failing = const {}]) => {
    for (final item in findInactiveProfiles(profiles, failing, now)) item.profile.id: item.reason,
  };

  test('lists expired and used-up subscriptions', () {
    expect(
      reasons([
        remote('ok', subInfo: info()),
        remote('expired', subInfo: info(expire: DateTime(2026, 10))),
        remote('used', subInfo: info(used: 100)),
        remote('both', subInfo: info(used: 100, expire: DateTime(2026, 10))),
      ]),
      {'expired': InactiveReason.expired, 'used': InactiveReason.noTraffic, 'both': InactiveReason.expired},
    );
  });

  test('unlimited traffic and no subscription info are active', () {
    expect(
      reasons([
        remote(
          'unlimited',
          subInfo: info(used: 1 << 40, total: ProfileParser.infiniteTrafficThreshold + 1),
        ),
        remote('noInfo'),
        ProfileEntity.local(id: 'local', active: false, name: 'local', lastUpdate: lastUpdate),
      ]),
      isEmpty,
    );
  });

  test('a subscription failing to update counts only once updates gave up', () {
    expect(
      reasons(
        [remote('gaveUp'), remote('recent'), remote('recovered')],
        {
          'gaveUp': DateTime(2026, 11, 2),
          'recent': DateTime(2026, 11, 8),
          // updated again after it began to fail
          'recovered': DateTime(2026, 10),
        },
      ),
      {'gaveUp': InactiveReason.updateFailing},
    );
  });
}
