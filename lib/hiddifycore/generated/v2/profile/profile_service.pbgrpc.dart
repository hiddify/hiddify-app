///
//  Generated code. Do not modify.
//  source: v2/profile/profile_service.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'profile_service.pb.dart' as $4;
import 'profile.pb.dart' as $5;
import '../hcommon/common.pb.dart' as $1;
export 'profile_service.pb.dart';

class ProfileServiceClient extends $grpc.Client {
  static final _$getProfile =
      $grpc.ClientMethod<$4.ProfileRequest, $4.ProfileResponse>(
          '/profile.ProfileService/GetProfile',
          ($4.ProfileRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $4.ProfileResponse.fromBuffer(value));
  static final _$updateProfile =
      $grpc.ClientMethod<$5.ProfileEntity, $4.ProfileResponse>(
          '/profile.ProfileService/UpdateProfile',
          ($5.ProfileEntity value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $4.ProfileResponse.fromBuffer(value));
  static final _$getAllProfiles =
      $grpc.ClientMethod<$1.Empty, $4.MultiProfilesResponse>(
          '/profile.ProfileService/GetAllProfiles',
          ($1.Empty value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $4.MultiProfilesResponse.fromBuffer(value));
  static final _$getActiveProfile =
      $grpc.ClientMethod<$1.Empty, $4.ProfileResponse>(
          '/profile.ProfileService/GetActiveProfile',
          ($1.Empty value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $4.ProfileResponse.fromBuffer(value));
  static final _$setActiveProfile =
      $grpc.ClientMethod<$4.ProfileRequest, $1.Response>(
          '/profile.ProfileService/SetActiveProfile',
          ($4.ProfileRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Response.fromBuffer(value));
  static final _$addProfile =
      $grpc.ClientMethod<$4.AddProfileRequest, $4.ProfileResponse>(
          '/profile.ProfileService/AddProfile',
          ($4.AddProfileRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $4.ProfileResponse.fromBuffer(value));
  static final _$deleteProfile =
      $grpc.ClientMethod<$4.ProfileRequest, $1.Response>(
          '/profile.ProfileService/DeleteProfile',
          ($4.ProfileRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Response.fromBuffer(value));

  ProfileServiceClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$4.ProfileResponse> getProfile($4.ProfileRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getProfile, request, options: options);
  }

  $grpc.ResponseFuture<$4.ProfileResponse> updateProfile(
      $5.ProfileEntity request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateProfile, request, options: options);
  }

  $grpc.ResponseFuture<$4.MultiProfilesResponse> getAllProfiles(
      $1.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getAllProfiles, request, options: options);
  }

  $grpc.ResponseFuture<$4.ProfileResponse> getActiveProfile($1.Empty request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getActiveProfile, request, options: options);
  }

  $grpc.ResponseFuture<$1.Response> setActiveProfile($4.ProfileRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$setActiveProfile, request, options: options);
  }

  $grpc.ResponseFuture<$4.ProfileResponse> addProfile(
      $4.AddProfileRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$addProfile, request, options: options);
  }

  $grpc.ResponseFuture<$1.Response> deleteProfile($4.ProfileRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteProfile, request, options: options);
  }
}

abstract class ProfileServiceBase extends $grpc.Service {
  $core.String get $name => 'profile.ProfileService';

  ProfileServiceBase() {
    $addMethod($grpc.ServiceMethod<$4.ProfileRequest, $4.ProfileResponse>(
        'GetProfile',
        getProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.ProfileRequest.fromBuffer(value),
        ($4.ProfileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$5.ProfileEntity, $4.ProfileResponse>(
        'UpdateProfile',
        updateProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $5.ProfileEntity.fromBuffer(value),
        ($4.ProfileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $4.MultiProfilesResponse>(
        'GetAllProfiles',
        getAllProfiles_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($4.MultiProfilesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$1.Empty, $4.ProfileResponse>(
        'GetActiveProfile',
        getActiveProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $1.Empty.fromBuffer(value),
        ($4.ProfileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.ProfileRequest, $1.Response>(
        'SetActiveProfile',
        setActiveProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.ProfileRequest.fromBuffer(value),
        ($1.Response value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.AddProfileRequest, $4.ProfileResponse>(
        'AddProfile',
        addProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.AddProfileRequest.fromBuffer(value),
        ($4.ProfileResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$4.ProfileRequest, $1.Response>(
        'DeleteProfile',
        deleteProfile_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $4.ProfileRequest.fromBuffer(value),
        ($1.Response value) => value.writeToBuffer()));
  }

  $async.Future<$4.ProfileResponse> getProfile_Pre(
      $grpc.ServiceCall call, $async.Future<$4.ProfileRequest> request) async {
    return getProfile(call, await request);
  }

  $async.Future<$4.ProfileResponse> updateProfile_Pre(
      $grpc.ServiceCall call, $async.Future<$5.ProfileEntity> request) async {
    return updateProfile(call, await request);
  }

  $async.Future<$4.MultiProfilesResponse> getAllProfiles_Pre(
      $grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return getAllProfiles(call, await request);
  }

  $async.Future<$4.ProfileResponse> getActiveProfile_Pre(
      $grpc.ServiceCall call, $async.Future<$1.Empty> request) async {
    return getActiveProfile(call, await request);
  }

  $async.Future<$1.Response> setActiveProfile_Pre(
      $grpc.ServiceCall call, $async.Future<$4.ProfileRequest> request) async {
    return setActiveProfile(call, await request);
  }

  $async.Future<$4.ProfileResponse> addProfile_Pre($grpc.ServiceCall call,
      $async.Future<$4.AddProfileRequest> request) async {
    return addProfile(call, await request);
  }

  $async.Future<$1.Response> deleteProfile_Pre(
      $grpc.ServiceCall call, $async.Future<$4.ProfileRequest> request) async {
    return deleteProfile(call, await request);
  }

  $async.Future<$4.ProfileResponse> getProfile(
      $grpc.ServiceCall call, $4.ProfileRequest request);
  $async.Future<$4.ProfileResponse> updateProfile(
      $grpc.ServiceCall call, $5.ProfileEntity request);
  $async.Future<$4.MultiProfilesResponse> getAllProfiles(
      $grpc.ServiceCall call, $1.Empty request);
  $async.Future<$4.ProfileResponse> getActiveProfile(
      $grpc.ServiceCall call, $1.Empty request);
  $async.Future<$1.Response> setActiveProfile(
      $grpc.ServiceCall call, $4.ProfileRequest request);
  $async.Future<$4.ProfileResponse> addProfile(
      $grpc.ServiceCall call, $4.AddProfileRequest request);
  $async.Future<$1.Response> deleteProfile(
      $grpc.ServiceCall call, $4.ProfileRequest request);
}
