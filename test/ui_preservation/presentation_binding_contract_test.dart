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

class _Bindings extends GeneralizingAstVisitor<void> {
  _Bindings(this.path);

  final String path;
  final exact = <String, int>{};
  final predicates = <String, int>{};
  final ifStatements = <IfStatement>[];
  void add(Map<String, int> into, String kind, AstNode node) {
    final key = '$kind:${_tokens(node)}';
    into.update(key, (count) => count + 1, ifAbsent: () => 1);
  }

  @override
  void visitNode(AstNode node) {
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
      }
    }
    if (node is FunctionExpressionInvocation && RegExp('^use[A-Z]').hasMatch(node.function.toSource())) {
      add(exact, 'state', node);
    }
    if (node is GuardedPattern) add(exact, 'switch-pattern', node);
    if (node is SwitchCase) add(exact, 'switch-case', node.expression);
    if (node is SwitchExpression) add(exact, 'switch-value', node.expression);
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

List<String> _differences(_Bindings baseline, _Bindings live) {
  final issues = <String>[];
  for (final key in {...baseline.exact.keys, ...live.exact.keys}) {
    if (baseline.exact[key] != live.exact[key]) issues.add('binding multiplicity changed: $key');
  }
  // Added appearance predicates are allowed; only the approved recovery getter may replace an existing condition.
  for (final key in baseline.predicates.keys) {
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
