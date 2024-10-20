//
//  Generated code. Do not modify.
//  source: extension/extension.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ExtensionResponseType extends $pb.ProtobufEnum {
  static const ExtensionResponseType NOTHING = ExtensionResponseType._(0, _omitEnumNames ? '' : 'NOTHING');
  static const ExtensionResponseType UPDATE_UI = ExtensionResponseType._(1, _omitEnumNames ? '' : 'UPDATE_UI');
  static const ExtensionResponseType SHOW_DIALOG = ExtensionResponseType._(2, _omitEnumNames ? '' : 'SHOW_DIALOG');
  static const ExtensionResponseType END = ExtensionResponseType._(3, _omitEnumNames ? '' : 'END');

  static const $core.List<ExtensionResponseType> values = <ExtensionResponseType> [
    NOTHING,
    UPDATE_UI,
    SHOW_DIALOG,
    END,
  ];

  static final $core.Map<$core.int, ExtensionResponseType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ExtensionResponseType? valueOf($core.int value) => _byValue[value];

  const ExtensionResponseType._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
