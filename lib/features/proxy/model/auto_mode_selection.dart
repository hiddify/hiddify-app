import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

enum AutoModeSelectionReason {
  lowestLatency,
  deterministicFallback,
  latencyUnavailable,
  noAuthorizedServers,
}

class AutoModeSelection {
  const AutoModeSelection({required this.outboundTag, required this.reason, this.latency});

  final String? outboundTag;
  final AutoModeSelectionReason reason;
  final Duration? latency;
}

/// Ranks only the outbounds exposed by the active core group. Authorization
/// remains the responsibility of the subscription and credential issuer.
abstract final class AutoModeSelector {
  static const _timeoutDelay = 65000;

  static AutoModeSelection select(Iterable<OutboundInfo> outbounds) {
    final candidates = outbounds.where(_isCompleteAuthorizedCandidate).toList()
      ..sort((a, b) {
        final byNormalizedTag = a.tag.toLowerCase().compareTo(b.tag.toLowerCase());
        return byNormalizedTag != 0 ? byNormalizedTag : a.tag.compareTo(b.tag);
      });

    if (candidates.isEmpty) {
      return const AutoModeSelection(
        outboundTag: null,
        reason: AutoModeSelectionReason.noAuthorizedServers,
      );
    }

    final measured = candidates.where((item) => item.urlTestDelay > 0 && item.urlTestDelay < _timeoutDelay).toList()
      ..sort((a, b) {
        final byLatency = a.urlTestDelay.compareTo(b.urlTestDelay);
        return byLatency != 0 ? byLatency : a.tag.compareTo(b.tag);
      });
    if (measured.isNotEmpty) {
      final selected = measured.first;
      return AutoModeSelection(
        outboundTag: selected.tag,
        reason: AutoModeSelectionReason.lowestLatency,
        latency: Duration(milliseconds: selected.urlTestDelay),
      );
    }

    final hadTimeout = candidates.any((item) => item.urlTestDelay >= _timeoutDelay);
    return AutoModeSelection(
      outboundTag: candidates.first.tag,
      reason: hadTimeout ? AutoModeSelectionReason.latencyUnavailable : AutoModeSelectionReason.deterministicFallback,
    );
  }

  static bool _isCompleteAuthorizedCandidate(OutboundInfo item) {
    return item.tag.trim().isNotEmpty &&
        item.type.trim().isNotEmpty &&
        !item.isGroup &&
        (!item.hasIsVisible() || item.isVisible);
  }
}
