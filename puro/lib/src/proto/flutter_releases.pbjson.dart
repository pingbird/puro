// This is a generated file - do not edit.
//
// Generated from flutter_releases.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use flutterReleaseModelDescriptor instead')
const FlutterReleaseModel$json = {
  '1': 'FlutterReleaseModel',
  '2': [
    {'1': 'hash', '3': 1, '4': 1, '5': 9, '10': 'hash'},
    {'1': 'channel', '3': 2, '4': 1, '5': 9, '10': 'channel'},
    {'1': 'version', '3': 3, '4': 1, '5': 9, '10': 'version'},
    {'1': 'dart_sdk_version', '3': 4, '4': 1, '5': 9, '10': 'dartSdkVersion'},
    {'1': 'dart_sdk_arch', '3': 5, '4': 1, '5': 9, '10': 'dartSdkArch'},
    {'1': 'release_date', '3': 6, '4': 1, '5': 9, '10': 'releaseDate'},
    {'1': 'archive', '3': 7, '4': 1, '5': 9, '10': 'archive'},
    {'1': 'sha256', '3': 8, '4': 1, '5': 9, '10': 'sha256'},
  ],
};

/// Descriptor for `FlutterReleaseModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flutterReleaseModelDescriptor = $convert.base64Decode(
    'ChNGbHV0dGVyUmVsZWFzZU1vZGVsEhIKBGhhc2gYASABKAlSBGhhc2gSGAoHY2hhbm5lbBgCIA'
    'EoCVIHY2hhbm5lbBIYCgd2ZXJzaW9uGAMgASgJUgd2ZXJzaW9uEigKEGRhcnRfc2RrX3ZlcnNp'
    'b24YBCABKAlSDmRhcnRTZGtWZXJzaW9uEiIKDWRhcnRfc2RrX2FyY2gYBSABKAlSC2RhcnRTZG'
    'tBcmNoEiEKDHJlbGVhc2VfZGF0ZRgGIAEoCVILcmVsZWFzZURhdGUSGAoHYXJjaGl2ZRgHIAEo'
    'CVIHYXJjaGl2ZRIWCgZzaGEyNTYYCCABKAlSBnNoYTI1Ng==');

@$core.Deprecated('Use flutterReleasesModelDescriptor instead')
const FlutterReleasesModel$json = {
  '1': 'FlutterReleasesModel',
  '2': [
    {'1': 'base_url', '3': 1, '4': 1, '5': 9, '10': 'baseUrl'},
    {
      '1': 'current_release',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.FlutterReleasesModel.CurrentReleaseEntry',
      '10': 'currentRelease'
    },
    {
      '1': 'releases',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.FlutterReleaseModel',
      '10': 'releases'
    },
  ],
  '3': [FlutterReleasesModel_CurrentReleaseEntry$json],
};

@$core.Deprecated('Use flutterReleasesModelDescriptor instead')
const FlutterReleasesModel_CurrentReleaseEntry$json = {
  '1': 'CurrentReleaseEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `FlutterReleasesModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flutterReleasesModelDescriptor = $convert.base64Decode(
    'ChRGbHV0dGVyUmVsZWFzZXNNb2RlbBIZCghiYXNlX3VybBgBIAEoCVIHYmFzZVVybBJSCg9jdX'
    'JyZW50X3JlbGVhc2UYAiADKAsyKS5GbHV0dGVyUmVsZWFzZXNNb2RlbC5DdXJyZW50UmVsZWFz'
    'ZUVudHJ5Ug5jdXJyZW50UmVsZWFzZRIwCghyZWxlYXNlcxgDIAMoCzIULkZsdXR0ZXJSZWxlYX'
    'NlTW9kZWxSCHJlbGVhc2VzGkEKE0N1cnJlbnRSZWxlYXNlRW50cnkSEAoDa2V5GAEgASgJUgNr'
    'ZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');
