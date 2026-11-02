import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Inside a [RadioGroup], makes the arrow keys move the focus instead of the selection.
///
/// A [RadioGroup] selects the next or previous radio on an arrow key. In a picker that closes on
/// a selection, the first press of a TV remote's down key picked the next item and closed the
/// dialog, so nothing further down could be reached. Here the arrows walk the focus like
/// elsewhere in the app, and OK, Enter or a tap selects the focused item.
class ArrowKeysMoveFocus extends StatelessWidget {
  const ArrowKeysMoveFocus({super.key, required this.child});

  final Widget child;

  static const _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
    SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
    SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
    SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
  };

  @override
  Widget build(BuildContext context) => Shortcuts(shortcuts: _shortcuts, child: child);
}
