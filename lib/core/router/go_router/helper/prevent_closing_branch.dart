import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PreventClosingApp extends HookConsumerWidget {
  const PreventClosingApp({super.key, this.branchesPath = const <String>['/settings'], required this.child});

  final List<String> branchesPath;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(
      () {
        BackButtonInterceptor.add(
          (_, __) {
            final gState = GoRouterState.of(context);
            if (branchesPath.contains(gState.fullPath)) {
              context.goNamed('home');
              return true;
            }
            return false;
          },
          name: 'PreventClosingApp',
        );
        return () {
          BackButtonInterceptor.removeByName('PreventClosingApp');
        };
      },
      [],
    );
    return PopScope(
      canPop: false,
      child: child,
    );
  }
}
