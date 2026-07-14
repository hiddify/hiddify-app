import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/proxy/model/auto_mode_selection.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

void main() {
  OutboundInfo server(String tag, int delay, {bool visible = true}) => OutboundInfo(
        tag: tag,
        tagDisplay: tag,
        type: 'vless',
        urlTestDelay: delay,
        isVisible: visible,
      );

  group('AutoModeSelector', () {
    test('prefers the lowest valid measured latency', () {
      final result = AutoModeSelector.select([
        server('beta', 120),
        server('alpha', 40),
        server('unknown', 0),
      ]);

      expect(result.outboundTag, 'alpha');
      expect(result.reason, AutoModeSelectionReason.lowestLatency);
      expect(result.latency, const Duration(milliseconds: 40));
    });

    test('uses a stable tag fallback when every latency is unknown', () {
      final result = AutoModeSelector.select([
        server('Zurich', 0),
        server('amsterdam', 0),
      ]);

      expect(result.outboundTag, 'amsterdam');
      expect(result.reason, AutoModeSelectionReason.deterministicFallback);
    });

    test('uses deterministic fallback when all measured checks time out', () {
      final result = AutoModeSelector.select([
        server('beta', 65535),
        server('alpha', 65535),
      ]);

      expect(result.outboundTag, 'alpha');
      expect(result.reason, AutoModeSelectionReason.latencyUnavailable);
    });

    test('excludes hidden, group, and incomplete entries', () {
      final result = AutoModeSelector.select([
        server('hidden', 1, visible: false),
        OutboundInfo(tag: 'nested', type: 'selector', isGroup: true, urlTestDelay: 1, isVisible: true),
        OutboundInfo(tag: 'incomplete', urlTestDelay: 1, isVisible: true),
        server('eligible', 50),
      ]);

      expect(result.outboundTag, 'eligible');
    });

    test('reports no candidate when no authorized complete server exists', () {
      final result = AutoModeSelector.select([server('hidden', 1, visible: false)]);

      expect(result.outboundTag, isNull);
      expect(result.reason, AutoModeSelectionReason.noAuthorizedServers);
    });
  });
}
