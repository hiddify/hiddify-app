import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../flutter_animate.dart';

/// Drives an [Animate] animation from a [ScrollController].
///
/// Set [direction] to [ScrollDirection.forward] or [ScrollDirection.reverse] to
/// only trigger updates when the scroll position increases or decreases respectively.
///
/// [begin] and [end] adjust the pixel range for the scroll to update the animation
/// within. Values `<0` are calculated relative to the end of the scroll.
/// They default to `minScrollExtent` and `maxScrollExtent` respectively.
///
/// For example, this starts fading/sliding in the text once the list scrolls to
/// 100px, and finishes 200px before the end of the scroll:
///
/// ```
/// ListView(
///   controller: scrollController,
///   children: items,
/// );
/// Text("Hello").animate(
///   adapter: ScrollAdapter(
///     scrollController,
///     begin: 100, // relative to start of scroll
///     end: -200,  // relative to end
///   )
/// ).fadeIn().slide();
/// ```
///
/// See [Adapter] for information on [direction] and [animated].
class ScrollAdapter extends Adapter {
  ScrollAdapter(
    this.scrollController, {
    this.begin,
    this.end,
    bool? animated,
    Direction? direction,
  }) : super(animated: animated, direction: direction);

  final ScrollController scrollController;
  final double? begin;
  final double? end;

  @override
  void attach(AnimationController controller) {
    config(
      controller,
      _getValue() ?? 0,
      notifier: scrollController,
      listener: () {
        double? value = _getValue();
        if (value != null) updateValue(value);
      },
    );
  }

  double? _getValue() {
    if (!scrollController.hasClients) return null;
    ScrollPosition pos = scrollController.position;
    if (!pos.hasContentDimensions || !pos.hasPixels) return null;
    double min = pos.minScrollExtent, max = pos.maxScrollExtent;
    double minPx = _getPx(begin, min, max, min);
    double maxPx = _getPx(end, min, max, max);
    return (pos.pixels - minPx) / (maxPx - minPx);
  }

  double _getPx(double? val, double min, double max, double def) {
    if (val == null) return def;
    return val + (val <= 0 ? max : min);
  }
}
