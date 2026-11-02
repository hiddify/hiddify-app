import 'dart:collection';
import '../flutter_animate.dart';

/// Simple helper class to build a list of effects via the chained api.
/// Example:
///
/// ```
/// List<Effect> myEffects = EffectList().fadeIn().scale();
/// // ...
/// Animate(effects: myEffects, child: foo);
/// ```
class EffectList extends ListBase<Effect> with AnimateManager<EffectList> {
  final List<Effect> _effects = [];

  @override
  EffectList addEffect(Effect effect) {
    _effects.add(effect);
    return this;
  }

  // concrete implementations required when extending ListBase:
  @override
  set length(int length) {
    _effects.length = length;
  }

  @override
  int get length => _effects.length;

  @override
  Effect operator [](int index) => _effects[index];

  @override
  void operator []=(int index, Effect value) {
    _effects[index] = value;
  }
}
