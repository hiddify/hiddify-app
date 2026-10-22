import 'dart:convert';
import 'dart:io';

// Test-only AST guard uses the pinned transitive analyzer; the migration freezes dependencies.
// ignore: depend_on_referenced_packages
import 'package:analyzer/dart/analysis/utilities.dart';
// ignore: depend_on_referenced_packages
import 'package:analyzer/dart/ast/ast.dart';
// ignore: depend_on_referenced_packages
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _baseline = '0830294eff5b8cd86324545ed00689648c70bd23';
const _connectionButtonPath = 'lib/features/home/widget/connection_button.dart';
const _homePagePath = 'lib/features/home/widget/home_page.dart';
const _activeProxyCardPath = 'lib/features/proxy/active/active_proxy_card.dart';
// Existing presentation surfaces explicitly enumerated in the migration plan.
const _files = <String>[
  'lib/core/theme/app_theme.dart',
  'lib/core/theme/theme_extensions.dart',
  'lib/core/router/adaptive_layout/my_adaptive_layout.dart',
  'lib/features/home/widget/home_page.dart',
  'lib/features/home/widget/connection_button.dart',
  'lib/features/profile/widget/profile_tile.dart',
  'lib/features/proxy/widget/proxy_tile.dart',
  'lib/features/proxy/active/active_proxy_card.dart',
  'lib/features/proxy/active/active_proxy_delay_indicator.dart',
  'lib/features/proxy/overview/proxies_overview_page.dart',
  'lib/features/common/qr_code_scanner_screen.dart',
  'lib/features/common/qr_code_dialog.dart',
  'lib/features/settings/widget/preference_tile.dart',
  'lib/features/common/general_pref_tiles.dart',
  'lib/features/profile/add/add_profile_modal.dart',
  'lib/features/profile/overview/profiles_modal.dart',
  'lib/core/router/bottom_sheets/widgets/quick_settings_modal.dart',
  'lib/features/profile/details/profile_details_page.dart',
  'lib/features/profile/details/json_editor.dart',
  'lib/features/log/overview/logs_page.dart',
  'lib/features/about/widget/about_page.dart',
  'lib/features/intro/widget/intro_page.dart',
];
const _directories = <String>['lib/core/router/dialog/widgets/', 'lib/features/settings/overview/'];
const _callbacks = <String>{
  'onTap',
  'onPressed',
  'onLongPress',
  'onChanged',
  'onSelected',
  'onSelectionChanged',
  'onReset',
  'validator',
  'validateInput',
  'inputToValue',
  'initialOnSuccess',
  'initialOnFailure',
};

String _tokens(AstNode node) {
  final result = <String>[];
  var token = node.beginToken;
  while (true) {
    result.add(token.lexeme);
    if (identical(token, node.endToken)) break;
    token = token.next!;
  }
  return jsonEncode(result);
}

String _providerBindingKey(String accessor, String provider) =>
    'state:${jsonEncode(['ref', '.', accessor, '(', provider, ')'])}';

class _ApprovedStateAddition {
  const _ApprovedStateAddition({
    required this.path,
    required this.className,
    required this.methodName,
    required this.provider,
  });

  final String path;
  final String className;
  final String methodName;
  final String provider;

  String get expression => 'ref.watch($provider)';
  String get bindingKey => _providerBindingKey('watch', provider);
  String get siteKey => '$className::$methodName::$bindingKey';
}

const _approvedStateAdditions = <_ApprovedStateAddition>[
  _ApprovedStateAddition(
    path: 'lib/features/proxy/active/active_proxy_delay_indicator.dart',
    className: 'ActiveProxyDelayIndicator',
    methodName: 'build',
    provider: 'iosActiveProxyMeasurementEnabledProvider',
  ),
  _ApprovedStateAddition(
    path: 'lib/features/proxy/active/active_proxy_card.dart',
    className: 'ActiveProxyFooter',
    methodName: 'build',
    provider: 'iosActiveProxyMeasurementEnabledProvider',
  ),
  _ApprovedStateAddition(
    path: 'lib/features/proxy/active/active_proxy_card.dart',
    className: 'ActiveProxyFooter',
    methodName: 'build',
    provider: 'iosActiveProxyMeasurementStateProvider',
  ),
];

class _Bindings extends GeneralizingAstVisitor<void> {
  _Bindings(this.path);

  final String path;
  final exact = <String, int>{};
  final stateSites = <String, int>{};
  final predicates = <String, int>{};
  final ifStatements = <IfStatement>[];
  final switchExpressions = <SwitchExpression>[];
  final directStatements = <String, List<String>>{};
  final localInitializers = <String, List<String>>{};
  void add(Map<String, int> into, String kind, AstNode node) {
    final key = '$kind:${_tokens(node)}';
    into.update(key, (count) => count + 1, ifAbsent: () => 1);
  }

  void addStateSite(AstNode node) {
    String? className;
    String? methodName;
    for (AstNode? current = node.parent; current != null; current = current.parent) {
      if (current is FunctionExpression || current is FunctionDeclaration) return;
      if (methodName == null && current is MethodDeclaration) methodName = current.name.lexeme;
      if (current is ClassDeclaration) {
        className = current.name.lexeme;
        break;
      }
    }
    if (className == null || methodName == null) return;
    final key = '$className::$methodName::state:${_tokens(node)}';
    stateSites.update(key, (count) => count + 1, ifAbsent: () => 1);
  }

  String? directMethodSite(AstNode node) {
    final parent = node.parent;
    if (node is! Statement || parent is! Block || parent.parent is! BlockFunctionBody) return null;
    final method = parent.parent!.parent;
    if (method is! MethodDeclaration || method.parent is! ClassDeclaration) return null;
    return '${(method.parent! as ClassDeclaration).name.lexeme}::${method.name.lexeme}';
  }

  String? localVariableSite(VariableDeclaration node) {
    String? methodName;
    String? className;
    for (AstNode? current = node.parent; current != null; current = current.parent) {
      if (current is FunctionExpression || current is FunctionDeclaration) return null;
      if (methodName == null && current is MethodDeclaration) methodName = current.name.lexeme;
      if (current is ClassDeclaration) {
        className = current.name.lexeme;
        break;
      }
    }
    if (className == null || methodName == null) return null;
    return '$className::$methodName::${node.name.lexeme}';
  }

  @override
  void visitNode(AstNode node) {
    final directSite = directMethodSite(node);
    if (directSite != null) {
      directStatements.putIfAbsent(directSite, () => <String>[]).add(_tokens(node));
    }
    if (node is VariableDeclaration && node.initializer != null) {
      final variableSite = localVariableSite(node);
      if (variableSite != null) {
        localInitializers.putIfAbsent(variableSite, () => <String>[]).add(_tokens(node.initializer!));
      }
    }
    if (node is NamedExpression && _callbacks.contains(node.name.label.name)) {
      add(exact, node.name.label.name, node.expression);
    }
    if (node is MethodDeclaration && node.name.lexeme == '_onTap') {
      add(exact, '_onTap', node);
    }
    if (node is MethodInvocation) {
      final name = node.methodName.name;
      if (RegExp('^use[A-Z]').hasMatch(name) ||
          (const {'watch', 'read', 'listen', 'listenManual'}.contains(name) &&
              RegExp(r'\bref\b').hasMatch(node.target?.toSource() ?? ''))) {
        add(exact, 'state', node);
        addStateSite(node);
      }
    }
    if (node is FunctionExpressionInvocation && RegExp('^use[A-Z]').hasMatch(node.function.toSource())) {
      add(exact, 'state', node);
    }
    if (node is GuardedPattern) add(exact, 'switch-pattern', node);
    if (node is SwitchCase) add(exact, 'switch-case', node.expression);
    if (node is SwitchExpression) {
      add(exact, 'switch-value', node.expression);
      switchExpressions.add(node);
    }
    if (node is SwitchStatement) add(exact, 'switch-value', node.expression);
    if (node is IfStatement) {
      add(predicates, 'if', node.expression);
      ifStatements.add(node);
    }
    if (node is IfElement) add(predicates, 'if', node.expression);
    if (node is ConditionalExpression) add(predicates, 'conditional', node.condition);
    super.visitNode(node);
  }
}

_Bindings _inventory(String source, String path) {
  final parsed = parseString(content: source, path: path, throwIfDiagnostics: false);
  if (parsed.errors.isNotEmpty) {
    throw StateError('AST parse diagnostics in $path: ${parsed.errors}');
  }
  final inventory = _Bindings(path);
  parsed.unit.accept(inventory);
  return inventory;
}

String _secureLabelPredicate(String accessor) =>
    'if:${jsonEncode(['delay', '<=', '0', '||', 'delay', '>', '65000', '||', 'connectionStatus', '.', accessor, '!=', 'const', 'Connected', '(', ')'])}';

String _recoveryContext(IfStatement node) {
  final parts = [
    _tokens(node.thenStatement),
    if (node.elseStatement == null) 'no-else' else _tokens(node.elseStatement!),
  ];
  AstNode current = node;
  while (current.parent != null) {
    final parent = current.parent!;
    if (parent is ClassDeclaration) {
      parts.add('class:${parent.name.lexeme}');
      break;
    }
    if (parent is MethodDeclaration) parts.add('method:${parent.name.lexeme}');
    parts.add('${parent.runtimeType}:${parent.childEntities.toList().indexOf(current)}');
    current = parent;
  }
  return jsonEncode(parts);
}

bool _sameRecoverySite(_Bindings baseline, _Bindings live) {
  final before = baseline.ifStatements
      .where((node) => 'if:${_tokens(node.expression)}' == _secureLabelPredicate('value'))
      .toList();
  final after = live.ifStatements
      .where((node) => 'if:${_tokens(node.expression)}' == _secureLabelPredicate('valueOrNull'))
      .toList();
  return before.length == 1 && after.length == 1 && _recoveryContext(before.single) == _recoveryContext(after.single);
}

bool _isApprovedStateAddition(_Bindings baseline, _Bindings live, String key) {
  final additions = _approvedStateAdditions.where(
    (addition) => addition.path == live.path && addition.bindingKey == key,
  );
  if (additions.length != 1) return false;
  final addition = additions.single;
  return (baseline.exact[key] ?? 0) == 0 && live.exact[key] == 1 && live.stateSites[addition.siteKey] == 1;
}

String _statementTokens(String source) {
  final parsed = parseString(content: 'class Fixture { void build() { $source } }');
  final inventory = _Bindings('fixture');
  parsed.unit.accept(inventory);
  return inventory.directStatements['Fixture::build']!.single;
}

String _initializerTokens(String source) {
  final parsed = parseString(content: 'class Fixture { void build() { final value = $source; } }');
  final inventory = _Bindings('fixture');
  parsed.unit.accept(inventory);
  return inventory.localInitializers['Fixture::build::value']!.single;
}

String? _singleInitializer(_Bindings bindings, String key) {
  final values = bindings.localInitializers[key];
  return values?.length == 1 ? values!.single : null;
}

const _actionLabelInitializerSource = '''
switch (connectionStatus) {
  AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
  AsyncData(value: Connected()) => t.connection.disconnect,
  AsyncData(value: Disconnected()) || AsyncError() => t.connection.connect,
  AsyncData(value: final status) => status.present(t),
  _ => '',
}
''';

String _actionLabelFixture(String initializer, {bool duplicate = false}) =>
    '''
class ConnectionButton {
  void build() {
    final actionLabel = $initializer;
    ${duplicate ? 'final duplicateActionLabel = $initializer;' : ''}
  }
}
''';

Map<String, int> get _approvedActionLabelBindings =>
    _inventory(_actionLabelFixture(_actionLabelInitializerSource), 'approved-action-label').exact;

bool _isApprovedActionLabelAddition(_Bindings baseline, _Bindings live, String key) {
  if (baseline.path != 'baseline/$_connectionButtonPath' || live.path != _connectionButtonPath) return false;
  if (_singleInitializer(baseline, 'ConnectionButton::build::actionLabel') != null ||
      _singleInitializer(live, 'ConnectionButton::build::actionLabel') !=
          _initializerTokens(_actionLabelInitializerSource)) {
    return false;
  }
  final approvedCount = _approvedActionLabelBindings[key];
  return approvedCount != null && live.exact[key] == (baseline.exact[key] ?? 0) + approvedCount;
}

const _homeProfileSwitchSource = '''
switch (activeProfile) {
  AsyncData(value: final profile?) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 76),
    child: ProfileTile(
      profile: profile,
      isMain: true,
      color: Theme.of(context).colorScheme.surfaceContainer,
    ),
  ),
  _ => const SizedBox.shrink(),
}
''';

String _homeProfileSwitchFixture(String? expression, {bool duplicate = false}) =>
    '''
class HomePage {
  void build() {
    Widget(slivers: blizzard ? [${expression ?? ''}${duplicate ? ', $expression' : ''}] : const []);
  }
}
''';

Map<String, int> get _approvedHomeProfileBindings =>
    _inventory(_homeProfileSwitchFixture(_homeProfileSwitchSource), 'approved-home-profile').exact;

bool _isInBlizzardSliversBranch(SwitchExpression node) {
  String? className;
  String? methodName;
  var inApprovedBranch = false;
  for (AstNode? current = node.parent; current != null; current = current.parent) {
    if (current is ConditionalExpression &&
        _tokens(current.condition) == jsonEncode(['blizzard']) &&
        current.parent is NamedExpression &&
        (current.parent! as NamedExpression).name.label.name == 'slivers' &&
        node.offset >= current.thenExpression.offset &&
        node.end <= current.thenExpression.end) {
      inApprovedBranch = true;
    }
    if (methodName == null && current is MethodDeclaration) methodName = current.name.lexeme;
    if (current is ClassDeclaration) {
      className = current.name.lexeme;
      break;
    }
  }
  return className == 'HomePage' && methodName == 'build' && inApprovedBranch;
}

bool _isApprovedHomeProfileAddition(_Bindings baseline, _Bindings live, String key) {
  if (baseline.path != 'baseline/$_homePagePath' || live.path != _homePagePath) return false;
  final expectedTokens = _initializerTokens(_homeProfileSwitchSource);
  final baselineMatches = baseline.switchExpressions.where((node) => _tokens(node) == expectedTokens).length;
  final liveMatches = live.switchExpressions
      .where((node) => _tokens(node) == expectedTokens && _isInBlizzardSliversBranch(node))
      .length;
  if (baselineMatches != 0 || liveMatches != 1) return false;
  final approvedCount = _approvedHomeProfileBindings[key];
  return approvedCount != null && live.exact[key] == (baseline.exact[key] ?? 0) + approvedCount;
}

String get _serverChoiceCallbackKey =>
    'onPressed:${jsonEncode(['(', ')', '=>', 'context', '.', 'goNamed', '(', "'proxies'", ')'])}';

String get _combinedActiveProxyGuard =>
    'if:${jsonEncode(['connectionState', '!=', 'const', 'Connected', '(', ')', '||', 'activeProxy', '==', 'null'])}';

bool _isApprovedServerChoiceFallback(_Bindings baseline, _Bindings live) {
  if (baseline.path != 'baseline/$_activeProxyCardPath' || live.path != _activeProxyCardPath) return false;
  if (baseline.predicates[_combinedActiveProxyGuard] != 1 || (live.predicates[_combinedActiveProxyGuard] ?? 0) != 0) {
    return false;
  }
  if ((baseline.exact[_serverChoiceCallbackKey] ?? 0) != 0 || live.exact[_serverChoiceCallbackKey] != 1) return false;

  final statements = live.directStatements['ActiveProxyFooter::build'];
  if (statements == null) return false;
  final connectedGuard = _statementTokens('''
if (connectionState != const Connected()) {
  return const SizedBox.shrink();
}
''');
  final fallback = _statementTokens('''
if (activeProxy == null) {
  if (!ios) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.all(16),
    child: OutlinedButton.icon(
      onPressed: () => context.goNamed('proxies'),
      icon: const Icon(Icons.public),
      label: Text(t.pages.proxies.title),
    ),
  );
}
''');
  final connectedIndex = statements.indexOf(connectedGuard);
  if (connectedIndex < 0 || statements.where((statement) => statement == connectedGuard).length != 1) return false;
  if (connectedIndex + 1 >= statements.length || statements[connectedIndex + 1] != fallback) return false;
  if (statements.where((statement) => statement == fallback).length != 1) return false;

  return _singleInitializer(live, 'ActiveProxyFooter::build::legacyProxy') ==
          _initializerTokens('ref.watch(activeProxyNotifierProvider.select((value) => value.valueOrNull))') &&
      _singleInitializer(live, 'ActiveProxyFooter::build::ios') ==
          _initializerTokens(
            'Theme.of(context).platform == TargetPlatform.iOS && ref.watch(iosActiveProxyMeasurementEnabledProvider)',
          ) &&
      _singleInitializer(live, 'ActiveProxyFooter::build::activeProxy') ==
          _initializerTokens(
            'ios ? ref.watch(iosActiveProxyMeasurementStateProvider).asData?.value.proxy : legacyProxy',
          );
}

List<String> _differences(_Bindings baseline, _Bindings live) {
  final issues = <String>[];
  final approvedServerChoiceFallback = _isApprovedServerChoiceFallback(baseline, live);
  for (final key in {...baseline.exact.keys, ...live.exact.keys}) {
    if (baseline.exact[key] != live.exact[key] &&
        !_isApprovedStateAddition(baseline, live, key) &&
        !_isApprovedActionLabelAddition(baseline, live, key) &&
        !_isApprovedHomeProfileAddition(baseline, live, key) &&
        !(approvedServerChoiceFallback && key == _serverChoiceCallbackKey)) {
      issues.add('binding multiplicity changed: $key');
    }
  }
  // Added appearance predicates are allowed; only the approved recovery getter may replace an existing condition.
  for (final key in baseline.predicates.keys) {
    if (approvedServerChoiceFallback && key == _combinedActiveProxyGuard) continue;
    if (baseline.path == 'baseline/$_connectionButtonPath' &&
        live.path == _connectionButtonPath &&
        key == _secureLabelPredicate('value')) {
      if (baseline.predicates[key] != 1 ||
          (live.predicates[key] ?? 0) != 0 ||
          live.predicates[_secureLabelPredicate('valueOrNull')] != 1 ||
          !_sameRecoverySite(baseline, live)) {
        issues.add('approved connection-button recovery predicate changed: $key');
      }
      continue;
    }
    if ((live.predicates[key] ?? 0) < baseline.predicates[key]!) {
      issues.add('existing predicate removed or changed: $key');
    }
  }
  return issues;
}

void main() {
  test('all allowed presentation files preserve shipped state/action bindings', () {
    final listed = Process.runSync('git', ['ls-tree', '-r', '--name-only', _baseline, 'lib']);
    expect(listed.exitCode, 0, reason: '${listed.stderr}');
    final paths =
        (listed.stdout as String)
            .split('\n')
            .where((path) => path.endsWith('.dart') && (_files.contains(path) || _directories.any(path.startsWith)))
            .toList()
          ..sort();
    expect(
      paths.toSet().containsAll(_files),
      isTrue,
      reason: 'Every explicitly listed file must exist in shipped source.',
    );
    var count = 0;
    final receipts = <String>[];
    for (final path in paths) {
      final original = Process.runSync('git', ['show', '$_baseline:$path']);
      expect(original.exitCode, 0, reason: path);
      expect(File(path).existsSync(), isTrue, reason: 'Missing presentation file $path');
      final baseline = _inventory(original.stdout as String, 'baseline/$path');
      final live = _inventory(File(path).readAsStringSync(), path);
      expect(_differences(baseline, live), isEmpty, reason: path);
      final bindings = baseline.exact.values.fold<int>(0, (a, b) => a + b);
      count += bindings;
      receipts.add('$path: $bindings bindings, ${baseline.predicates.values.fold<int>(0, (a, b) => a + b)} predicates');
    }
    // Future pure presentation files must not introduce provider state or hooks.
    for (final path in ['lib/core/theme/blizzard_tokens.dart', 'lib/core/theme/blizzard_theme.dart']) {
      if (!File(path).existsSync()) continue;
      final inventory = _inventory(File(path).readAsStringSync(), path);
      expect(inventory.exact.keys.where((key) => key.startsWith('state:')), isEmpty, reason: path);
    }
    for (final directory in ['lib/core/widget/blizzard']) {
      if (!Directory(directory).existsSync()) continue;
      for (final file in Directory(
        directory,
      ).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final inventory = _inventory(file.readAsStringSync(), file.path);
        expect(inventory.exact.keys.where((key) => key.startsWith('state:')), isEmpty, reason: file.path);
      }
    }
    stdout.writeln(
      'SHIPPED BINDING RECEIPT $_baseline: ${paths.length} files, $count exact bindings\n${receipts.join('\n')}',
    );
  });

  test('guard rejects a callback mutation in an actual shipped profile tile copy', () {
    const path = 'lib/features/profile/widget/profile_tile.dart';
    final original = Process.runSync('git', ['show', '$_baseline:$path']);
    expect(original.exitCode, 0);
    final source = original.stdout as String;
    final finder = _CallbackFinder();
    parseString(content: source).unit.accept(finder);
    expect(finder.expression, isNotNull);
    final callback = finder.expression!;
    final mutated = source.replaceRange(callback.offset, callback.end, 'null');
    expect(_differences(_inventory(source, path), _inventory(mutated, 'disposable/$path')), isNotEmpty);
  });

  group('approved connection-button error recovery', () {
    const path = 'lib/features/home/widget/connection_button.dart';
    const predicate = 'delay <= 0 || delay > 65000 || connectionStatus.value != const Connected()';
    late String source;

    setUp(() {
      final original = Process.runSync('git', ['show', '$_baseline:$path']);
      expect(original.exitCode, 0);
      source = original.stdout as String;
      expect(predicate.allMatches(source).length, 1);
    });

    test('guard accepts only the approved null-safe predicate', () {
      final corrected = source.replaceFirst(predicate, predicate.replaceFirst('.value ', '.valueOrNull '));
      expect(_differences(_inventory(source, 'baseline/$path'), _inventory(corrected, path)), isEmpty);
    });

    for (final mutation in <String, String>{
      'unsafe error getter': predicate,
      'changed latency boundary': predicate.replaceFirst('.value ', '.valueOrNull ').replaceFirst('65000', '64999'),
    }.entries) {
      test('guard rejects ${mutation.key} after approving recovery', () {
        final mutated = source.replaceFirst(predicate, mutation.value);
        expect(_differences(_inventory(source, 'baseline/$path'), _inventory(mutated, path)), isNotEmpty);
      });
    }

    test('guard does not allow the recovery substitution in another file', () {
      const otherPath = 'lib/features/proxy/widget/proxy_tile.dart';
      final corrected = source.replaceFirst(predicate, predicate.replaceFirst('.value ', '.valueOrNull '));
      expect(_differences(_inventory(source, 'baseline/$otherPath'), _inventory(corrected, otherPath)), isNotEmpty);
    });

    test('guard rejects a duplicated approved predicate', () {
      final correctedPredicate = predicate.replaceFirst('.value ', '.valueOrNull ');
      final duplicated = source.replaceFirst(
        predicate,
        '$correctedPredicate) { secureLabel = ""; } if ($correctedPredicate',
      );
      expect(_differences(_inventory(source, 'baseline/$path'), _inventory(duplicated, path)), isNotEmpty);
    });

    test('guard rejects relocating the approved predicate within the same file', () {
      final correctedPredicate = predicate.replaceFirst('.value ', '.valueOrNull ');
      final relocated = source
          .replaceFirst(predicate, 'true')
          .replaceFirst(
            'return _ConnectionButton(',
            'if ($correctedPredicate) { secureLabel = ""; } return _ConnectionButton(',
          );
      expect(_differences(_inventory(source, 'baseline/$path'), _inventory(relocated, path)), isNotEmpty);
    });

    test('guard rejects changing the approved recovery body', () {
      final changedBody = source
          .replaceFirst(predicate, predicate.replaceFirst('.value ', '.valueOrNull '))
          .replaceFirst('secureLabel = "";', 'secureLabel = "unexpected";');
      expect(_differences(_inventory(source, 'baseline/$path'), _inventory(changedBody, path)), isNotEmpty);
    });
  });

  group('approved connection-button action label', () {
    const baseline = 'class ConnectionButton { void build() {} }';

    test('guard accepts only the exact presentation mapping at the approved site', () {
      final live = _actionLabelFixture(_actionLabelInitializerSource);
      expect(
        _differences(_inventory(baseline, 'baseline/$_connectionButtonPath'), _inventory(live, _connectionButtonPath)),
        isEmpty,
      );
    });

    test('guard rejects changing the connected action mapping', () {
      final changed = _actionLabelInitializerSource.replaceFirst('t.connection.disconnect', 't.connection.connect');
      expect(
        _differences(
          _inventory(baseline, 'baseline/$_connectionButtonPath'),
          _inventory(_actionLabelFixture(changed), _connectionButtonPath),
        ),
        isNotEmpty,
      );
    });

    test('guard rejects duplicating the approved switch', () {
      expect(
        _differences(
          _inventory(baseline, 'baseline/$_connectionButtonPath'),
          _inventory(_actionLabelFixture(_actionLabelInitializerSource, duplicate: true), _connectionButtonPath),
        ),
        isNotEmpty,
      );
    });

    test('guard rejects the exact mapping in another file', () {
      const otherPath = 'lib/features/proxy/widget/proxy_tile.dart';
      expect(
        _differences(
          _inventory(baseline, 'baseline/$otherPath'),
          _inventory(_actionLabelFixture(_actionLabelInitializerSource), otherPath),
        ),
        isNotEmpty,
      );
    });
  });

  group('approved Blizzard home profile presentation', () {
    final baseline = _homeProfileSwitchFixture(null);

    test('guard accepts only the exact profile switch in the Blizzard slivers branch', () {
      final live = _homeProfileSwitchFixture(_homeProfileSwitchSource);
      expect(_differences(_inventory(baseline, 'baseline/$_homePagePath'), _inventory(live, _homePagePath)), isEmpty);
    });

    test('guard rejects changing the empty-profile presentation', () {
      final changed = _homeProfileSwitchSource.replaceFirst('const SizedBox.shrink()', "const Text('')");
      expect(
        _differences(
          _inventory(baseline, 'baseline/$_homePagePath'),
          _inventory(_homeProfileSwitchFixture(changed), _homePagePath),
        ),
        isNotEmpty,
      );
    });

    test('guard rejects duplicating the approved profile switch', () {
      expect(
        _differences(
          _inventory(baseline, 'baseline/$_homePagePath'),
          _inventory(_homeProfileSwitchFixture(_homeProfileSwitchSource, duplicate: true), _homePagePath),
        ),
        isNotEmpty,
      );
    });

    test('guard rejects the exact profile switch in another file', () {
      const otherPath = 'lib/features/profile/widget/profile_tile.dart';
      expect(
        _differences(
          _inventory(baseline, 'baseline/$otherPath'),
          _inventory(_homeProfileSwitchFixture(_homeProfileSwitchSource), otherPath),
        ),
        isNotEmpty,
      );
    });
  });

  group('approved iOS active-proxy provider watches', () {
    String fixture(
      _ApprovedStateAddition addition,
      List<String> expressions, {
      String? className,
      String? methodName,
    }) =>
        '''
class ${className ?? addition.className} {
  void ${methodName ?? addition.methodName}(dynamic ref) {
    ${expressions.map((expression) => '$expression;').join('\n    ')}
  }
}
''';

    test('guard accepts each exact additive watch once at its approved site', () {
      for (final addition in _approvedStateAdditions) {
        final baseline = fixture(addition, const []);
        final live = fixture(addition, [addition.expression]);
        expect(
          _differences(_inventory(baseline, 'baseline/${addition.path}'), _inventory(live, addition.path)),
          isEmpty,
          reason: addition.expression,
        );
      }
    });

    test('guard rejects a duplicate approved watch', () {
      final addition = _approvedStateAdditions.first;
      final baseline = fixture(addition, const []);
      final live = fixture(addition, [addition.expression, addition.expression]);
      expect(
        _differences(_inventory(baseline, 'baseline/${addition.path}'), _inventory(live, addition.path)),
        isNotEmpty,
      );
    });

    test('guard rejects the wrong provider', () {
      final addition = _approvedStateAdditions.first;
      final baseline = fixture(addition, const []);
      final live = fixture(addition, const ['ref.watch(unapprovedProvider)']);
      expect(
        _differences(_inventory(baseline, 'baseline/${addition.path}'), _inventory(live, addition.path)),
        isNotEmpty,
      );
    });

    test('guard rejects read instead of watch', () {
      final addition = _approvedStateAdditions.first;
      final baseline = fixture(addition, const []);
      final live = fixture(addition, ['ref.read(${addition.provider})']);
      expect(
        _differences(_inventory(baseline, 'baseline/${addition.path}'), _inventory(live, addition.path)),
        isNotEmpty,
      );
    });

    test('guard rejects the approved watch in the wrong class', () {
      final addition = _approvedStateAdditions.first;
      final baseline = fixture(addition, const []);
      final live = fixture(addition, [addition.expression], className: 'OtherPresentation');
      expect(
        _differences(_inventory(baseline, 'baseline/${addition.path}'), _inventory(live, addition.path)),
        isNotEmpty,
      );
    });

    test('guard rejects the approved watch in the wrong method', () {
      final addition = _approvedStateAdditions.first;
      final baseline = fixture(addition, const []);
      final live = fixture(addition, [addition.expression], methodName: 'other');
      expect(
        _differences(_inventory(baseline, 'baseline/${addition.path}'), _inventory(live, addition.path)),
        isNotEmpty,
      );
    });

    test('guard rejects the approved watch inside an unused closure', () {
      final addition = _approvedStateAdditions.first;
      final baseline = fixture(addition, const []);
      final live = fixture(addition, ['final unused = () { ${addition.expression}; }']);
      expect(
        _differences(_inventory(baseline, 'baseline/${addition.path}'), _inventory(live, addition.path)),
        isNotEmpty,
      );
    });

    test('guard rejects the approved watch inside an unused local function', () {
      final addition = _approvedStateAdditions.first;
      final baseline = fixture(addition, const []);
      final live = fixture(addition, ['void unused() { ${addition.expression}; }']);
      expect(
        _differences(_inventory(baseline, 'baseline/${addition.path}'), _inventory(live, addition.path)),
        isNotEmpty,
      );
    });

    test('guard rejects the approved watch in the wrong file', () {
      final addition = _approvedStateAdditions.first;
      final baseline = fixture(addition, const []);
      final live = fixture(addition, [addition.expression]);
      const wrongPath = 'lib/features/proxy/widget/proxy_tile.dart';
      expect(_differences(_inventory(baseline, 'baseline/$wrongPath'), _inventory(live, wrongPath)), isNotEmpty);
    });
  });

  group('approved iOS server-choice fallback', () {
    const path = 'lib/features/proxy/active/active_proxy_card.dart';
    late String baseline;
    late String live;

    setUp(() {
      final original = Process.runSync('git', ['show', '$_baseline:$path']);
      expect(original.exitCode, 0);
      baseline = original.stdout as String;
      live = File(path).readAsStringSync();
    });

    test('guard accepts only the exact connected iOS null-proxy fallback', () {
      expect(_differences(_inventory(baseline, 'baseline/$path'), _inventory(live, path)), isEmpty);
    });

    for (final mutation in <String, String Function(String)>{
      'wrong destination': (source) => source.replaceFirst("goNamed('proxies')", "goNamed('profiles')"),
      'missing iOS gate leaks to non-iOS': (source) => source.replaceFirst(
        'if (!ios) return const SizedBox.shrink();',
        'if (false) return const SizedBox.shrink();',
      ),
      'disconnected exposure': (source) =>
          source.replaceFirst('if (connectionState != const Connected())', 'if (false)'),
      'legacy proxy substitution': (source) => source.replaceFirst(
        'ios ? ref.watch(iosActiveProxyMeasurementStateProvider).asData?.value.proxy : legacyProxy',
        'legacyProxy',
      ),
      'real metadata route bypass': (source) =>
          source.replaceFirst('if (activeProxy == null)', 'if (activeProxy != null)'),
    }.entries) {
      test('guard rejects ${mutation.key}', () {
        final mutated = mutation.value(live);
        expect(mutated, isNot(live), reason: 'Mutation fixture must alter the production source.');
        expect(_differences(_inventory(baseline, 'baseline/$path'), _inventory(mutated, path)), isNotEmpty);
      });
    }
  });

  const sample = '''
void build(dynamic ref) {
  final controller = useTextEditingController(text: 'draft');
  ref.watch(profileProvider);
  Tile(onTap: () => ref.read(actionsProvider).select('profile-1'));
  if (mounted) save(controller.text);
}
''';
  test('guard accepts whitespace and additional visual wrappers', () {
    final decorated = sample
        .replaceFirst('Tile(onTap:', 'Padding(child: Tile(onTap:')
        .replaceFirst("select('profile-1'));", "select('profile-1')));");
    expect(
      _differences(_inventory(sample, 'sample'), _inventory(decorated.replaceAll('  ', '    '), 'decorated')),
      isEmpty,
    );
  });
  for (final mutation in <String, String>{
    'changed profile ID': sample.replaceAll('profile-1', 'profile-2'),
    'removed callback': sample.replaceAll("onTap: () => ref.read(actionsProvider).select('profile-1')", ''),
    'duplicated callback': sample.replaceFirst(
      '  if (mounted)',
      "  Tile(onTap: () => ref.read(actionsProvider).select('profile-1'));\n  if (mounted)",
    ),
    'extra provider read': sample.replaceFirst('  if (mounted)', '  ref.read(extraProvider);\n  if (mounted)'),
    'changed controller initialization': sample.replaceAll("'draft'", "'reset'"),
    'removed lifetime condition': sample.replaceAll('if (mounted)', 'if (true)'),
  }.entries) {
    test('guard rejects ${mutation.key} in disposable source', () {
      expect(_differences(_inventory(sample, 'sample'), _inventory(mutation.value, 'mutated')), isNotEmpty);
    });
  }
  test('invalid Dart is a guard failure rather than partial inventory', () {
    expect(() => _inventory('void broken( {', 'invalid'), throwsStateError);
  });
}

class _CallbackFinder extends RecursiveAstVisitor<void> {
  Expression? expression;
  @override
  void visitNamedExpression(NamedExpression node) {
    if (_callbacks.contains(node.name.label.name)) expression ??= node.expression;
    super.visitNamedExpression(node);
  }
}
