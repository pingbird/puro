// This is a generated file - do not edit.
//
// Generated from flutter_releases.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class FlutterReleaseModel extends $pb.GeneratedMessage {
  factory FlutterReleaseModel({
    $core.String? hash,
    $core.String? channel,
    $core.String? version,
    $core.String? dartSdkVersion,
    $core.String? dartSdkArch,
    $core.String? releaseDate,
    $core.String? archive,
    $core.String? sha256,
  }) {
    final result = create();
    if (hash != null) result.hash = hash;
    if (channel != null) result.channel = channel;
    if (version != null) result.version = version;
    if (dartSdkVersion != null) result.dartSdkVersion = dartSdkVersion;
    if (dartSdkArch != null) result.dartSdkArch = dartSdkArch;
    if (releaseDate != null) result.releaseDate = releaseDate;
    if (archive != null) result.archive = archive;
    if (sha256 != null) result.sha256 = sha256;
    return result;
  }

  FlutterReleaseModel._();

  factory FlutterReleaseModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FlutterReleaseModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FlutterReleaseModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hash')
    ..aOS(2, _omitFieldNames ? '' : 'channel')
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..aOS(4, _omitFieldNames ? '' : 'dartSdkVersion')
    ..aOS(5, _omitFieldNames ? '' : 'dartSdkArch')
    ..aOS(6, _omitFieldNames ? '' : 'releaseDate')
    ..aOS(7, _omitFieldNames ? '' : 'archive')
    ..aOS(8, _omitFieldNames ? '' : 'sha256')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlutterReleaseModel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlutterReleaseModel copyWith(void Function(FlutterReleaseModel) updates) =>
      super.copyWith((message) => updates(message as FlutterReleaseModel))
          as FlutterReleaseModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FlutterReleaseModel create() => FlutterReleaseModel._();
  @$core.override
  FlutterReleaseModel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FlutterReleaseModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FlutterReleaseModel>(create);
  static FlutterReleaseModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hash => $_getSZ(0);
  @$pb.TagNumber(1)
  set hash($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearHash() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channel => $_getSZ(1);
  @$pb.TagNumber(2)
  set channel($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannel() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get dartSdkVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set dartSdkVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDartSdkVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearDartSdkVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get dartSdkArch => $_getSZ(4);
  @$pb.TagNumber(5)
  set dartSdkArch($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDartSdkArch() => $_has(4);
  @$pb.TagNumber(5)
  void clearDartSdkArch() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get releaseDate => $_getSZ(5);
  @$pb.TagNumber(6)
  set releaseDate($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReleaseDate() => $_has(5);
  @$pb.TagNumber(6)
  void clearReleaseDate() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get archive => $_getSZ(6);
  @$pb.TagNumber(7)
  set archive($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasArchive() => $_has(6);
  @$pb.TagNumber(7)
  void clearArchive() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get sha256 => $_getSZ(7);
  @$pb.TagNumber(8)
  set sha256($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSha256() => $_has(7);
  @$pb.TagNumber(8)
  void clearSha256() => $_clearField(8);
}

class FlutterReleasesModel extends $pb.GeneratedMessage {
  factory FlutterReleasesModel({
    $core.String? baseUrl,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? currentRelease,
    $core.Iterable<FlutterReleaseModel>? releases,
  }) {
    final result = create();
    if (baseUrl != null) result.baseUrl = baseUrl;
    if (currentRelease != null)
      result.currentRelease.addEntries(currentRelease);
    if (releases != null) result.releases.addAll(releases);
    return result;
  }

  FlutterReleasesModel._();

  factory FlutterReleasesModel.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory FlutterReleasesModel.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FlutterReleasesModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'baseUrl')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'currentRelease',
        entryClassName: 'FlutterReleasesModel.CurrentReleaseEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS)
    ..pPM<FlutterReleaseModel>(3, _omitFieldNames ? '' : 'releases',
        subBuilder: FlutterReleaseModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlutterReleasesModel clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlutterReleasesModel copyWith(void Function(FlutterReleasesModel) updates) =>
      super.copyWith((message) => updates(message as FlutterReleasesModel))
          as FlutterReleasesModel;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FlutterReleasesModel create() => FlutterReleasesModel._();
  @$core.override
  FlutterReleasesModel createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static FlutterReleasesModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FlutterReleasesModel>(create);
  static FlutterReleasesModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get baseUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set baseUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBaseUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearBaseUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get currentRelease => $_getMap(1);

  @$pb.TagNumber(3)
  $pb.PbList<FlutterReleaseModel> get releases => $_getList(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
