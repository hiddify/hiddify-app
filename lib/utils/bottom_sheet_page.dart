import 'package:flutter/material.dart';

class BottomSheetPage extends Page {
  const BottomSheetPage({
    super.key,
    super.name,
    required this.builder,
    this.fixed = false,
  });

  final Widget Function(ScrollController? controller) builder;
  final bool fixed;

  @override
  Route<void> createRoute(BuildContext context) {
    return ModalBottomSheetRoute(
      settings: this,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) {
        if (!fixed) {
          return DraggableScrollableSheet(
            expand: false,
            builder: (_, scrollController) => builder(scrollController),
          );
        }
        return builder(null);
      },
    );
  }
}
