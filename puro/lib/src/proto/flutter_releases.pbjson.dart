///
//  Generated code. Do not modify.
//  source: flutter_releases.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use flutterReleaseModelDescriptor instead')
const FlutterReleaseModel$json = const {
  '1': 'FlutterReleaseModel',
  '2': const [
    const {'1': 'hash', '3': 1, '4': 1, '5': 9, '10': 'hash'},
    const {'1': 'channel', '3': 2, '4': 1, '5': 9, '10': 'channel'},
    const {'1': 'version', '3': 3, '4': 1, '5': 9, '10': 'version'},
    const {'1': 'dart_sdk_version', '3': 4, '4': 1, '5': 9, '10': 'dartSdkVersion'},
    const {'1': 'dart_sdk_arch', '3': 5, '4': 1, '5': 9, '10': 'dartSdkArch'},
    const {'1': 'release_date', '3': 6, '4': 1, '5': 9, '10': 'releaseDate'},
    const {'1': 'archive', '3': 7, '4': 1, '5': 9, '10': 'archive'},
    const {'1': 'sha256', '3': 8, '4': 1, '5': 9, '10': 'sha256'},
  ],
};

/// Descriptor for `FlutterReleaseModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flutterReleaseModelDescriptor = $convert.base64Decode('ChNGbHV0dGVyUmVsZWFzZU1vZGVsEhIKBGhhc2gYASABKAlSBGhhc2gSGAoHY2hhbm5lbBgCIAEoCVIHY2hhbm5lbBIYCgd2ZXJzaW9uGAMgASgJUgd2ZXJzaW9uEigKEGRhcnRfc2RrX3ZlcnNpb24YBCABKAlSDmRhcnRTZGtWZXJzaW9uEiIKDWRhcnRfc2RrX2FyY2gYBSABKAlSC2RhcnRTZGtBcmNoEiEKDHJlbGVhc2VfZGF0ZRgGIAEoCVILcmVsZWFzZURhdGUSGAoHYXJjaGl2ZRgHIAEoCVIHYXJjaGl2ZRIWCgZzaGEyNTYYCCABKAlSBnNoYTI1Ng==');
@$core.Deprecated('Use flutterReleasesModelDescriptor instead')
const FlutterReleasesModel$json = const {
  '1': 'FlutterReleasesModel',
  '2': const [
    const {'1': 'base_url', '3': 1, '4': 1, '5': 9, '10': 'baseUrl'},
    const {'1': 'current_release', '3': 2, '4': 3, '5': 11, '6': '.FlutterReleasesModel.CurrentReleaseEntry', '10': 'currentRelease'},
    const {'1': 'releases', '3': 3, '4': 3, '5': 11, '6': '.FlutterReleaseModel', '10': 'releases'},
  ],
  '3': const [FlutterReleasesModel_CurrentReleaseEntry$json],
};

@$core.Deprecated('Use flutterReleasesModelDescriptor instead')
const FlutterReleasesModel_CurrentReleaseEntry$json = const {
  '1': 'CurrentReleaseEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `FlutterReleasesModel`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flutterReleasesModelDescriptor = $convert.base64Decode('ChRGbHV0dGVyUmVsZWFzZXNNb2RlbBIZCghiYXNlX3VybBgBIAEoCVIHYmFzZVVybBJSCg9jdXJyZW50X3JlbGVhc2UYAiADKAsyKS5GbHV0dGVyUmVsZWFzZXNNb2RlbC5DdXJyZW50UmVsZWFzZUVudHJ5Ug5jdXJyZW50UmVsZWFzZRIwCghyZWxlYXNlcxgDIAMoCzIULkZsdXR0ZXJSZWxlYXNlTW9kZWxSCHJlbGVhc2VzGkEKE0N1cnJlbnRSZWxlYXNlRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');
