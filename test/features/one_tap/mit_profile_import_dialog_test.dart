import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/one_tap/mit_profile_import_dialog.dart';
import 'package:hiddify/features/one_tap/vpn_profile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'fixtures/awg_fixture.dart';

class _Picker extends FilePicker {
  _Picker(this.data, {this.fileName = 'amnezia_config.vpn'});
  final List<int> data;
  final String fileName;
  FileType? chosenType;
  List<String>? extensions;
  bool cleaned = false;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle, String? initialDirectory, FileType type = FileType.any,
    List<String>? allowedExtensions, Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true, int compressionQuality = 30,
    bool allowMultiple = false, bool withData = false, bool withReadStream = false,
    bool lockParentWindow = false, bool readSequential = false,
  }) async {
    chosenType = type; extensions = allowedExtensions;
    return FilePickerResult([PlatformFile(name: fileName, size: data.length, readStream: Stream.value(data))]);
  }
  @override
  Future<bool?> clearTemporaryFiles() async { cleaned = true; return true; }
}

void main() {
  Future<void> open(WidgetTester tester, {required Future<String?> Function() loader, required ValueChanged<String?> result}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [mitProfileFileLoaderProvider.overrideWithValue(loader)],
      child: MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
        child: const Text('Открыть'),
        onPressed: () async => result(await showDialog<String>(context: context, builder: (_) => const MitProfileImportDialog())),
      )))),
    ));
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
  }

  testWidgets('explicit clipboard paste keeps complete conf while hiding credentials and never reads automatically', (tester) async {
    var reads = 0;
    String? imported;
    final text = awgAmneziaPlaceholderConfig();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') { reads++; return {'text': text}; }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await open(tester, loader: () async => null, result: (value) => imported = value);
    expect(find.textContaining('Диапазон keepalive'), findsOneWidget);
    expect(reads, 0);
    await tester.tap(find.byKey(const ValueKey('mit-paste-profile')));
    await tester.pumpAndSettle();
    expect(reads, 1);
    final input = tester.widget<TextField>(find.byKey(const ValueKey('mit-profile-input')));
    expect(input.obscureText, true);
    expect(input.enableIMEPersonalizedLearning, false);
    expect(input.controller!.text, text);
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText, true);
    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(imported, text);
    expect(prepareVpnProfile(imported!).protocol, MitVpnProtocol.amneziaWg);
  });

  testWidgets('file import keeps the conf intact and cancellation does not import', (tester) async {
    String? imported;
    await open(tester, loader: () async => awgTestConfig(), result: (value) => imported = value);
    await tester.tap(find.byKey(const ValueKey('mit-pick-profile')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const ValueKey('mit-profile-input'))).controller!.text, awgTestConfig());
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(imported, null);
  });

  testWidgets('file reader errors do not show paths or credentials', (tester) async {
    await open(tester, loader: () async => throw StateError('private/path/${testWgKey(1)}'), result: (_) {});
    await tester.tap(find.byKey(const ValueKey('mit-pick-profile')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не удалось прочитать профиль'), findsOneWidget);
    expect(find.textContaining('private/path'), findsNothing);
    expect(find.textContaining(testWgKey(1)), findsNothing);
  });

  test('Android picker permits octet-stream .vpn documents and validates after selection', () async {
    FilePicker? previous;
    try { previous = FilePicker.platform; } catch (_) {}
    addTearDown(() { if (previous != null) FilePicker.platform = previous!; });
    final data = utf8.encode(amneziaTestLink(amneziaStructuredContainer()));
    final picker = _Picker(data);
    FilePicker.platform = picker;
    final text = await pickVpnProfileFile();
    expect(picker.chosenType, FileType.any);
    expect(picker.extensions, isNull);
    expect(picker.cleaned, true);
    expect(prepareVpnProfile(text!).protocol, MitVpnProtocol.amneziaWg);
    final wrong = _Picker(data, fileName: 'image.png');
    FilePicker.platform = wrong;
    await expectLater(pickVpnProfileFile(), throwsFormatException);
    expect(wrong.cleaned, true);
  });

  test('bounded file reader enforces actual bytes and strict UTF8', () async {
    final config = awgTestConfig();
    expect(await readVpnProfileText(Stream.fromIterable([utf8.encode(config)])), config);
    await expectLater(readVpnProfileText(Stream.fromIterable([List.filled(maxVpnProfileBytes, 65), [66]])), throwsFormatException);
    await expectLater(readVpnProfileText(Stream.fromIterable([[0xFF]])), throwsFormatException);
  });
}
