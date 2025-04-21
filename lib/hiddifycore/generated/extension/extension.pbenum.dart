///
//  Generated code. Do not modify.
//  source: extension/extension.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class ExtensionResponseType extends $pb.ProtobufEnum {
  static const ExtensionResponseType NOTHING = ExtensionResponseType._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NOTHING');
  static const ExtensionResponseType UPDATE_UI = ExtensionResponseType._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UPDATE_UI');
  static const ExtensionResponseType SHOW_DIALOG = ExtensionResponseType._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SHOW_DIALOG');
  static const ExtensionResponseType END = ExtensionResponseType._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'END');

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

