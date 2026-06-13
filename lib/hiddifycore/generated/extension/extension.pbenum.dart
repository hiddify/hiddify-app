// This is a generated file - do not edit.
//
// Generated from extension/extension.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ExtensionResponseType extends $pb.ProtobufEnum {
  static const ExtensionResponseType NOTHING =
      ExtensionResponseType._(0, _omitEnumNames ? '' : 'NOTHING');
  static const ExtensionResponseType UPDATE_UI =
      ExtensionResponseType._(1, _omitEnumNames ? '' : 'UPDATE_UI');
  static const ExtensionResponseType SHOW_DIALOG =
      ExtensionResponseType._(2, _omitEnumNames ? '' : 'SHOW_DIALOG');
  static const ExtensionResponseType END =
      ExtensionResponseType._(3, _omitEnumNames ? '' : 'END');

  static const $core.List<ExtensionResponseType> values =
      <ExtensionResponseType>[
    NOTHING,
    UPDATE_UI,
    SHOW_DIALOG,
    END,
  ];

  static final $core.List<ExtensionResponseType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ExtensionResponseType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ExtensionResponseType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
