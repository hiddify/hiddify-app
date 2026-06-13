// This is a generated file - do not edit.
//
// Generated from v2/profile/profile_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import '../hcommon/common.pb.dart' as $2;
import 'profile.pb.dart' as $1;
import 'profile_service.pb.dart' as $0;

export 'profile_service.pb.dart';

/// *
///  ProfileService defines the RPC methods available for managing profiles.
@$pb.GrpcServiceName('profile.ProfileService')
class ProfileServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ProfileServiceClient(super.channel, {super.options, super.interceptors});

  /// *
  ///  GetProfile fetches a profile by ID, name, or URL.
  $grpc.ResponseFuture<$0.ProfileResponse> getProfile(
    $0.ProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getProfile, request, options: options);
  }

  /// *
  ///  UpdateProfile updates an existing profile.
  $grpc.ResponseFuture<$0.ProfileResponse> updateProfile(
    $1.ProfileEntity request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateProfile, request, options: options);
  }

  /// *
  ///  GetAllProfiles fetches all profiles.
  $grpc.ResponseFuture<$0.MultiProfilesResponse> getAllProfiles(
    $2.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAllProfiles, request, options: options);
  }

  /// *
  ///  GetActiveProfile retrieves the currently active profile.
  $grpc.ResponseFuture<$0.ProfileResponse> getActiveProfile(
    $2.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getActiveProfile, request, options: options);
  }

  /// *
  ///  SetActiveProfile sets a profile as active, identified by ID, name, or URL.
  $grpc.ResponseFuture<$2.Response> setActiveProfile(
    $0.ProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setActiveProfile, request, options: options);
  }

  /// *
  ///  AddProfile adds a new profile using either a URL or the raw profile content.
  $grpc.ResponseFuture<$0.ProfileResponse> addProfile(
    $0.AddProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addProfile, request, options: options);
  }

  /// *
  ///  DeleteProfile deletes a profile identified by ID, name, or URL.
  $grpc.ResponseFuture<$2.Response> deleteProfile(
    $0.ProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteProfile, request, options: options);
  }

  // method descriptors

  static final _$getProfile =
      $grpc.ClientMethod<$0.ProfileRequest, $0.ProfileResponse>(
          '/profile.ProfileService/GetProfile',
          ($0.ProfileRequest value) => value.writeToBuffer(),
          $0.ProfileResponse.fromBuffer);
  static final _$updateProfile =
      $grpc.ClientMethod<$1.ProfileEntity, $0.ProfileResponse>(
          '/profile.ProfileService/UpdateProfile',
          ($1.ProfileEntity value) => value.writeToBuffer(),
          $0.ProfileResponse.fromBuffer);
  static final _$getAllProfiles =
      $grpc.ClientMethod<$2.Empty, $0.MultiProfilesResponse>(
          '/profile.ProfileService/GetAllProfiles',
          ($2.Empty value) => value.writeToBuffer(),
          $0.MultiProfilesResponse.fromBuffer);
  static final _$getActiveProfile =
      $grpc.ClientMethod<$2.Empty, $0.ProfileResponse>(
          '/profile.ProfileService/GetActiveProfile',
          ($2.Empty value) => value.writeToBuffer(),
          $0.ProfileResponse.fromBuffer);
  static final _$setActiveProfile =
      $grpc.ClientMethod<$0.ProfileRequest, $2.Response>(
          '/profile.ProfileService/SetActiveProfile',
          ($0.ProfileRequest value) => value.writeToBuffer(),
          $2.Response.fromBuffer);
  static final _$addProfile =
      $grpc.ClientMethod<$0.AddProfileRequest, $0.ProfileResponse>(
          '/profile.ProfileService/AddProfile',
          ($0.AddProfileRequest value) => value.writeToBuffer(),
          $0.ProfileResponse.fromBuffer);
  static final _$deleteProfile =
      $grpc.ClientMethod<$0.ProfileRequest, $2.Response>(
          '/profile.ProfileService/DeleteProfile',
          ($0.ProfileRequest value) => value.writeToBuffer(),
          $2.Response.fromBuffer);
}

@$pb.GrpcServiceName('profile.ProfileService')
abstract class ProfileServiceBase extends $grpc.Service {
  $core.String get $name => 'profile.ProfileService';

  ProfileServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ProfileRequest, $0.ProfileResponse>(
        'GetProfile',
        getProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ProfileRequest.fromBuffer(value),
        ($0.ProfileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.ProfileEntity, $0.ProfileResponse>(
        'UpdateProfile',
        updateProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.ProfileEntity.fromBuffer(value),
        ($0.ProfileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $0.MultiProfilesResponse>(
        'GetAllProfiles',
        getAllProfiles_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($0.MultiProfilesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.Empty, $0.ProfileResponse>(
        'GetActiveProfile',
        getActiveProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.Empty.fromBuffer(value),
        ($0.ProfileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProfileRequest, $2.Response>(
        'SetActiveProfile',
        setActiveProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ProfileRequest.fromBuffer(value),
        ($2.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddProfileRequest, $0.ProfileResponse>(
        'AddProfile',
        addProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AddProfileRequest.fromBuffer(value),
        ($0.ProfileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProfileRequest, $2.Response>(
        'DeleteProfile',
        deleteProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ProfileRequest.fromBuffer(value),
        ($2.Response value) => value.writeToBuffer()));
  }

  $async.Future<$0.ProfileResponse> getProfile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ProfileRequest> $request) async {
    return getProfile($call, await $request);
  }

  $async.Future<$0.ProfileResponse> getProfile(
      $grpc.ServiceCall call, $0.ProfileRequest request);

  $async.Future<$0.ProfileResponse> updateProfile_Pre(
      $grpc.ServiceCall $call, $async.Future<$1.ProfileEntity> $request) async {
    return updateProfile($call, await $request);
  }

  $async.Future<$0.ProfileResponse> updateProfile(
      $grpc.ServiceCall call, $1.ProfileEntity request);

  $async.Future<$0.MultiProfilesResponse> getAllProfiles_Pre(
      $grpc.ServiceCall $call, $async.Future<$2.Empty> $request) async {
    return getAllProfiles($call, await $request);
  }

  $async.Future<$0.MultiProfilesResponse> getAllProfiles(
      $grpc.ServiceCall call, $2.Empty request);

  $async.Future<$0.ProfileResponse> getActiveProfile_Pre(
      $grpc.ServiceCall $call, $async.Future<$2.Empty> $request) async {
    return getActiveProfile($call, await $request);
  }

  $async.Future<$0.ProfileResponse> getActiveProfile(
      $grpc.ServiceCall call, $2.Empty request);

  $async.Future<$2.Response> setActiveProfile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ProfileRequest> $request) async {
    return setActiveProfile($call, await $request);
  }

  $async.Future<$2.Response> setActiveProfile(
      $grpc.ServiceCall call, $0.ProfileRequest request);

  $async.Future<$0.ProfileResponse> addProfile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AddProfileRequest> $request) async {
    return addProfile($call, await $request);
  }

  $async.Future<$0.ProfileResponse> addProfile(
      $grpc.ServiceCall call, $0.AddProfileRequest request);

  $async.Future<$2.Response> deleteProfile_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ProfileRequest> $request) async {
    return deleteProfile($call, await $request);
  }

  $async.Future<$2.Response> deleteProfile(
      $grpc.ServiceCall call, $0.ProfileRequest request);
}
