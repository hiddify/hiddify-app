import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/crash_report/notifier/trace_session_notifier.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/features/route_rules/notifier/rules_notifier.dart';
import 'package:hiddify/hiddifycore/generated/v2/config/route_rule.pb.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/singbox/model/singbox_config_option.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;
  late List<SingboxConfigOption> changes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(overrides: [rulesNotifierProvider.overrideWith(_NoRules.new)]);
    await container.read(sharedPreferencesProvider.future);
    changes = [];
    container.listen(ConfigOptions.singboxConfigOptions, (_, next) => changes.add(next));
  });
  tearDown(() => container.dispose());

  test('the core is told when a trace session ends, and what it goes back to', () async {
    final trace = container.read(traceSessionProvider.notifier);
    await trace.start();
    await pumpEventQueue();

    final until = container.read(traceSessionProvider)!;
    final on = container.read(ConfigOptions.singboxConfigOptions);
    expect(on.logLevel, LogLevel.trace);
    expect(on.logLevelUntil, until.toUtc());
    expect(on.logLevelAfter, LogLevel.warn);
    expect(on.toJson()['log-level-until'], endsWith('Z'));
    expect(changes, hasLength(1), reason: 'one reconnect for the start');

    await trace.stop();
    await pumpEventQueue();
    final off = container.read(ConfigOptions.singboxConfigOptions);
    expect(off.logLevel, LogLevel.warn);
    expect(off.logLevelUntil, isNull);
    expect(off.logLevelAfter, isNull);
    expect(changes, hasLength(2), reason: 'one reconnect for the end');
  });

  test('a user already on trace stays on it: the core is told no end', () async {
    await container.read(ConfigOptions.logLevel.notifier).update(LogLevel.trace);
    await container.read(traceSessionProvider.notifier).start();
    await pumpEventQueue();
    final on = container.read(ConfigOptions.singboxConfigOptions);
    expect(on.logLevel, LogLevel.trace);
    expect(on.logLevelUntil, isNull);
  });
}

class _NoRules extends RulesNotifier {
  @override
  List<Rule> build() => [];
}
