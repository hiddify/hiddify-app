//
//  Generated code. Do not modify.
//  source: google/protobuf/timestamp.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/src/protobuf/mixins/well_known.dart' as $mixin;

///  A Timestamp represents a point in time independent of any time zone or local
///  calendar, encoded as a count of seconds and fractions of seconds at
///  nanosecond resolution. The count is relative to an epoch at UTC midnight on
///  January 1, 1970, in the proleptic Gregorian calendar which extends the
///  Gregorian calendar backwards to year one.
///
///  All minutes are 60 seconds long. Leap seconds are "smeared" so that no leap
///  second table is needed for interpretation, using a [24-hour linear
///  smear](https://developers.google.com/time/smear).
///
///  The range is from 0001-01-01T00:00:00Z to 9999-12-31T23:59:59.999999999Z. By
///  restricting to that range, we ensure that we can convert to and from [RFC
///  3339](https://www.ietf.org/rfc/rfc3339.txt) date strings.
///
///  # Examples
///
///  Example 1: Compute Timestamp from POSIX `time()`.
///
///      Timestamp timestamp;
///      timestamp.set_seconds(time(NULL));
///      timestamp.set_nanos(0);
///
///  Example 2: Compute Timestamp from POSIX `gettimeofday()`.
///
///      struct timeval tv;
///      gettimeofday(&tv, NULL);
///
///      Timestamp timestamp;
///      timestamp.set_seconds(tv.tv_sec);
///      timestamp.set_nanos(tv.tv_usec * 1000);
///
///  Example 3: Compute Timestamp from Win32 `GetSystemTimeAsFileTime()`.
///
///      FILETIME ft;
///      GetSystemTimeAsFileTime(&ft);
///      UINT64 ticks = (((UINT64)ft.dwHighDateTime) << 32) | ft.dwLowDateTime;
///
///      // A Windows tick is 100 nanoseconds. Windows epoch 1601-01-01T00:00:00Z
///      // is 11644473600 seconds before Unix epoch 1970-01-01T00:00:00Z.
///      Timestamp timestamp;
///      timestamp.set_seconds((INT64) ((ticks / 10000000) - 11644473600LL));
///      timestamp.set_nanos((INT32) ((ticks % 10000000) * 100));
///
///  Example 4: Compute Timestamp from Java `System.currentTimeMillis()`.
///
///      long millis = System.currentTimeMillis();
///
///      Timestamp timestamp = Timestamp.newBuilder().setSeconds(millis / 1000)
///          .setNanos((int) ((millis % 1000) * 1000000)).build();
///
///  Example 5: Compute Timestamp from Java `Instant.now()`.
///
///      Instant now = Instant.now();
///
///      Timestamp timestamp =
///          Timestamp.newBuilder().setSeconds(now.getEpochSecond())
///              .setNanos(now.getNano()).build();
///
///  Example 6: Compute Timestamp from current time in Python.
///
///      timestamp = Timestamp()
///      timestamp.GetCurrentTime()
///
///  # JSON Mapping
///
///  In JSON format, the Timestamp type is encoded as a string in the
///  [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) format. That is, the
///  format is "{year}-{month}-{day}T{hour}:{min}:{sec}[.{frac_sec}]Z"
///  where {year} is always expressed using four digits while {month}, {day},
///  {hour}, {min}, and {sec} are zero-padded to two digits each. The fractional
///  seconds, which can go up to 9 digits (i.e. up to 1 nanosecond resolution),
///  are optional. The "Z" suffix indicates the timezone ("UTC"); the timezone
///  is required. A proto3 JSON serializer should always use UTC (as indicated by
///  "Z") when printing the Timestamp type and a proto3 JSON parser should be
///  able to accept both UTC and other timezones (as indicated by an offset).
///
///  For example, "2017-01-15T01:30:15.01Z" encodes 15.01 seconds past
///  01:30 UTC on January 15, 2017.
///
///  In JavaScript, one can convert a Date object to this format using the
///  standard
///  [toISOString()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/toISOString)
///  method. In Python, a standard `datetime.datetime` object can be converted
///  to this format using
///  [`strftime`](https://docs.python.org/2/library/time.html#time.strftime) with
///  the time format spec '%Y-%m-%dT%H:%M:%S.%fZ'. Likewise, in Java, one can use
///  the Joda Time's [`ISODateTimeFormat.dateTime()`](
///  http://joda-time.sourceforge.net/apidocs/org/joda/time/format/ISODateTimeFormat.html#dateTime()
///  ) to obtain a formatter capable of generating timestamps in this format.
class Timestamp extends $pb.GeneratedMessage with $mixin.TimestampMixin {
  factory Timestamp({
    $fixnum.Int64? seconds,
    $core.int? nanos,
  }) {
    final $result = create();
    if (seconds != null) {
      $result.seconds = seconds;
    }
    if (nanos != null) {
      $result.nanos = nanos;
    }
    return $result;
  }
  Timestamp._() : super();
  factory Timestamp.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Timestamp.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Timestamp', package: const $pb.PackageName(_omitMessageNames ? '' : 'google.protobuf'), createEmptyInstance: create, toProto3Json: $mixin.TimestampMixin.toProto3JsonHelper, fromProto3Json: $mixin.TimestampMixin.fromProto3JsonHelper)
    ..aInt64(1, _omitFieldNames ? '' : 'seconds')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'nanos', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Timestamp clone() => Timestamp()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Timestamp copyWith(void Function(Timestamp) updates) => super.copyWith((message) => updates(message as Timestamp)) as Timestamp;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Timestamp create() => Timestamp._();
  Timestamp createEmptyInstance() => create();
  static $pb.PbList<Timestamp> createRepeated() => $pb.PbList<Timestamp>();
  @$core.pragma('dart2js:noInline')
  static Timestamp getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Timestamp>(create);
  static Timestamp? _defaultInstance;

  /// Represents seconds of UTC time since Unix epoch
  /// 1970-01-01T00:00:00Z. Must be from 0001-01-01T00:00:00Z to
  /// 9999-12-31T23:59:59Z inclusive.
  @$pb.TagNumber(1)
  $fixnum.Int64 get seconds => $_getI64(0);
  @$pb.TagNumber(1)
  set seconds($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSeconds() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeconds() => clearField(1);

  /// Non-negative fractions of a second at nanosecond resolution. Negative
  /// second values with fractions must still have non-negative nanos values
  /// that count forward in time. Must be from 0 to 999,999,999
  /// inclusive.
  @$pb.TagNumber(2)
  $core.int get nanos => $_getIZ(1);
  @$pb.TagNumber(2)
  set nanos($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNanos() => $_has(1);
  @$pb.TagNumber(2)
  void clearNanos() => clearField(2);
  /// Creates a new instance from [dateTime].
  ///
  /// Time zone information will not be preserved.
  static Timestamp fromDateTime($core.DateTime dateTime) {
    final result = create();
    $mixin.TimestampMixin.setFromDateTime(result, dateTime);
    return result;
  }
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
