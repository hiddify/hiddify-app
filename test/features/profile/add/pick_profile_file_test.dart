import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/profile/add/widgets/fix_btns.dart';

class _RecordingPicker extends FilePicker {
  FileType? type;
  List<String>? allowedExtensions;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    this.type = type;
    this.allowedExtensions = allowedExtensions;
    return null;
  }
}

void main() {
  late _RecordingPicker picker;
  setUp(() => FilePicker.platform = picker = _RecordingPicker());

  test('Android shows every file, so conf and ovpn are not grayed out', () async {
    await pickProfileFile(platform: TargetPlatform.android);
    expect(picker.type, FileType.any);
    expect(picker.allowedExtensions, isNull);
  });

  for (final platform in [TargetPlatform.windows, TargetPlatform.iOS, TargetPlatform.macOS, TargetPlatform.linux]) {
    test('${platform.name} filters by the profile extensions', () async {
      await pickProfileFile(platform: platform);
      expect(picker.type, FileType.custom);
      expect(picker.allowedExtensions, containsAll(['conf', 'ovpn', 'zip']));
    });
  }
}
