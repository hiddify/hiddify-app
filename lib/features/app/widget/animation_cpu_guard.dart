import 'dart:async';
import 'dart:io';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/utils/process_cpu_time.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// How long the app's CPU use is measured once a connection is up.
const _window = Duration(seconds: 10);

/// The share of the whole machine's CPU (as the system's task manager shows it) above which the
/// animations cost too much: a computer without a graphics card draws them on the CPU.
const _limit = .10;

final _logger = appLogger('AnimationCpuGuard');

/// Desktop: measures the app's own CPU use for [_window] after each connect, and when it is above
/// [_limit] turns on the reduce animations setting, as the user would in the settings. The core
/// runs in a process of its own, so this is what drawing the app costs.
void useAnimationCpuGuard(WidgetRef ref) {
  final timer = useRef<Timer?>(null);
  useEffect(() => () => timer.value?.cancel(), const []);
  if (!PlatformUtils.isDesktop) return;

  ref.listen(connectionNotifierProvider, (previous, next) {
    final running = next.valueOrNull?.isRunning ?? false;
    if (!running) {
      timer.value?.cancel();
      timer.value = null;
      return;
    }
    if (previous?.valueOrNull?.isRunning ?? false) return;
    if (timer.value != null || ref.read(Preferences.reduceAnimations)) return;
    final start = processCpuTime();
    if (start == null) return;
    final clock = Stopwatch()..start();
    timer.value = Timer(_window, () {
      timer.value = null;
      final end = processCpuTime();
      if (end == null || ref.read(Preferences.reduceAnimations)) return;
      final share = (end - start).inMicroseconds / (clock.elapsedMicroseconds * Platform.numberOfProcessors);
      _logger.debug('app CPU after connecting: ${(share * 100).toStringAsFixed(1)}%');
      if (share <= _limit) return;
      _logger.info('the app used ${(share * 100).toStringAsFixed(1)}% CPU after connecting; reducing animations');
      unawaited(ref.read(Preferences.reduceAnimations.notifier).update(true));
    });
  });
}
