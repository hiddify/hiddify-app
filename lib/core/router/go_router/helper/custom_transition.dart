import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/utils/utils.dart';

enum TransitionType { slide, fade }

Page<dynamic> customTransition(TransitionType transition, LocalKey pageKey, Widget child) {
  // On iOS, use CupertinoPage so pages get the native interactive (edge-swipe)
  // back gesture. CustomTransitionPage does not support that gesture.
  if (PlatformUtils.isIOS) {
    return CupertinoPage<dynamic>(key: pageKey, child: child);
  }
  return CustomTransitionPage<dynamic>(
    key: pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 100),
    transitionsBuilder: (context, animation, _, child) => switch (transition) {
      TransitionType.slide => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(animation),
        textDirection: Directionality.of(context),
        child: child,
      ),
      TransitionType.fade => FadeTransition(opacity: animation, child: child),
    },
  );
}
