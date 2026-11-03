import 'package:flutter/widgets.dart';

/// [AnimatedSwitcher.layoutBuilder] without its duplicate key crash. The switcher keys each child's
/// transition by the child's own key, so a child that comes back while its earlier self still fades
/// out (A, then B, then A again within the duration) sits twice in the stack under one key, and the
/// tree breaks. Here the earlier one goes at once instead.
AnimatedSwitcherLayoutBuilder uniqueKeysLayout([AlignmentGeometry alignment = Alignment.center]) =>
    (current, previous) {
      final keys = <Key?>{current?.key};
      final kept = [
        for (final child in previous.reversed)
          if (child.key == null || keys.add(child.key)) child,
      ];
      return Stack(alignment: alignment, children: [...kept.reversed, ?current]);
    };
