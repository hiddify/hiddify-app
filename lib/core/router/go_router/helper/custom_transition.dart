import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum TransitionType { slide, fade }

CustomTransitionPage<dynamic> customTransition(TransitionType transition, LocalKey pageKey, Widget child) =>
    CustomTransitionPage(
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
