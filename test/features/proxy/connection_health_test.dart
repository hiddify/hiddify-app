import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/proxy/model/connection_health.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';

const _timeout = 65000;

OutboundInfo _proxy(String tag, int delay, {bool group = false, Status? status}) => OutboundInfo(
  tag: tag,
  urlTestDelay: delay,
  isGroup: group,
  status: status,
);

/// The main list as the core sends it: the selector with the user's pick, "lowest" with its choice.
OutboundGroupList _list({required OutboundInfo pick, int fastest = 80, OutboundInfo? hop}) => OutboundGroupList(
  items: [
    OutboundGroup(tag: 'select', items: [pick]),
    OutboundGroup(tag: 'lowest', items: [_proxy('fast', fastest)]),
  ],
  chainHop: hop,
);

void main() {
  test('a dead pick while lowest works offers the fastest', () {
    final h = ConnectionHealth.from(const Connected(), _list(pick: _proxy('mine', _timeout)), ChainStatus.off);
    expect(h.pick, HealthState.failed);
    expect(h.canSwitchToFastest, isTrue);
    expect(h.degraded, isTrue);
  });

  test('picking lowest itself is never a dead pick to switch from', () {
    final h = ConnectionHealth.from(
      const Connected(),
      _list(pick: _proxy('lowest', 80, group: true)),
      ChainStatus.off,
    );
    expect(h.pickedByHand, isFalse);
    expect(h.server?.tag, 'fast');
    expect(h.canSwitchToFastest, isFalse);
    expect(h.degraded, isFalse);
  });

  test('a pick still being tested is not dead', () {
    final h = ConnectionHealth.from(const Connected(), _list(pick: _proxy('mine', 0)), ChainStatus.off);
    expect(h.pick, HealthState.pending);
    expect(h.canSwitchToFastest, isFalse);
  });

  test('extra security connecting is pending, not a failure', () {
    final h = ConnectionHealth.from(
      const Connected(),
      _list(pick: _proxy('mine', 90), hop: _proxy('warp', 0, status: Status.CONNECTING)),
      ChainStatus.extraSecurity,
    );
    expect(h.hopState, HealthState.pending);
    expect(h.hopPending, isTrue);
    expect(h.degraded, isFalse);
  });

  test('a hop that is set up but not pinged yet counts as up', () {
    final h = ConnectionHealth.from(
      const Connected(),
      _list(pick: _proxy('mine', 90), hop: _proxy('warp', 0, status: Status.READY)),
      ChainStatus.extraSecurity,
    );
    expect(h.hopState, HealthState.ok);
    expect(h.hopPending, isFalse);
  });

  test('a failed hop is the problem when the pick works', () {
    final h = ConnectionHealth.from(
      const Connected(),
      _list(pick: _proxy('mine', 90), hop: _proxy('warp', 0, status: Status.FAILED)),
      ChainStatus.extraSecurity,
    );
    expect(h.hopState, HealthState.failed);
    expect(h.hopNoReply, isFalse);
    expect(h.degraded, isTrue);
    expect(h.canSwitchToFastest, isFalse);
  });

  test('a hop that is up but times out has no reply', () {
    final h = ConnectionHealth.from(
      const Connected(),
      _list(pick: _proxy('mine', 90), hop: _proxy('warp', _timeout, status: Status.READY)),
      ChainStatus.extraSecurity,
    );
    expect(h.hopNoReply, isTrue);
  });

  test('extra security waits on a dead pick instead of failing itself', () {
    final h = ConnectionHealth.from(
      const Connected(),
      _list(pick: _proxy('mine', _timeout), hop: _proxy('warp', _timeout, status: Status.READY)),
      ChainStatus.extraSecurity,
    );
    expect(h.hopState, HealthState.blocked);
    expect(h.canSwitchToFastest, isTrue);
  });

  test('nothing is degraded before the core is connected', () {
    final h = ConnectionHealth.from(const Waiting(), _list(pick: _proxy('mine', _timeout)), ChainStatus.off);
    expect(h.core, HealthState.pending);
    expect(h.degraded, isFalse);
    expect(h.canSwitchToFastest, isFalse);
  });
}
