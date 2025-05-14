//
//  Generated code. Do not modify.
//  source: flutter_releases.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

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
    final $result = create();
    if (hash != null) {
      $result.hash = hash;
    }
    if (channel != null) {
      $result.channel = channel;
    }
    if (version != null) {
      $result.version = version;
    }
    if (dartSdkVersion != null) {
      $result.dartSdkVersion = dartSdkVersion;
    }
    if (dartSdkArch != null) {
      $result.dartSdkArch = dartSdkArch;
    }
    if (releaseDate != null) {
      $result.releaseDate = releaseDate;
    }
    if (archive != null) {
      $result.archive = archive;
    }
    if (sha256 != null) {
      $result.sha256 = sha256;
    }
    return $result;
  }
  FlutterReleaseModel._() : super();
  factory FlutterReleaseModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FlutterReleaseModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

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

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FlutterReleaseModel clone() => FlutterReleaseModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FlutterReleaseModel copyWith(void Function(FlutterReleaseModel) updates) =>
      super.copyWith((message) => updates(message as FlutterReleaseModel))
          as FlutterReleaseModel;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FlutterReleaseModel create() => FlutterReleaseModel._();
  FlutterReleaseModel createEmptyInstance() => create();
  static $pb.PbList<FlutterReleaseModel> createRepeated() =>
      $pb.PbList<FlutterReleaseModel>();
  @$core.pragma('dart2js:noInline')
  static FlutterReleaseModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FlutterReleaseModel>(create);
  static FlutterReleaseModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hash => $_getSZ(0);
  @$pb.TagNumber(1)
  set hash($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearHash() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channel => $_getSZ(1);
  @$pb.TagNumber(2)
  set channel($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasChannel() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get dartSdkVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set dartSdkVersion($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasDartSdkVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearDartSdkVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get dartSdkArch => $_getSZ(4);
  @$pb.TagNumber(5)
  set dartSdkArch($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasDartSdkArch() => $_has(4);
  @$pb.TagNumber(5)
  void clearDartSdkArch() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get releaseDate => $_getSZ(5);
  @$pb.TagNumber(6)
  set releaseDate($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasReleaseDate() => $_has(5);
  @$pb.TagNumber(6)
  void clearReleaseDate() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get archive => $_getSZ(6);
  @$pb.TagNumber(7)
  set archive($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasArchive() => $_has(6);
  @$pb.TagNumber(7)
  void clearArchive() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get sha256 => $_getSZ(7);
  @$pb.TagNumber(8)
  set sha256($core.String v) {
    $_setString(7, v);
  }

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
    final $result = create();
    if (baseUrl != null) {
      $result.baseUrl = baseUrl;
    }
    if (currentRelease != null) {
      $result.currentRelease.addEntries(currentRelease);
    }
    if (releases != null) {
      $result.releases.addAll(releases);
    }
    return $result;
  }
  FlutterReleasesModel._() : super();
  factory FlutterReleasesModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FlutterReleasesModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FlutterReleasesModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'baseUrl')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'currentRelease',
        entryClassName: 'FlutterReleasesModel.CurrentReleaseEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS)
    ..pc<FlutterReleaseModel>(
        3, _omitFieldNames ? '' : 'releases', $pb.PbFieldType.PM,
        subBuilder: FlutterReleaseModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FlutterReleasesModel clone() =>
      FlutterReleasesModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FlutterReleasesModel copyWith(void Function(FlutterReleasesModel) updates) =>
      super.copyWith((message) => updates(message as FlutterReleasesModel))
          as FlutterReleasesModel;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FlutterReleasesModel create() => FlutterReleasesModel._();
  FlutterReleasesModel createEmptyInstance() => create();
  static $pb.PbList<FlutterReleasesModel> createRepeated() =>
      $pb.PbList<FlutterReleasesModel>();
  @$core.pragma('dart2js:noInline')
  static FlutterReleasesModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FlutterReleasesModel>(create);
  static FlutterReleasesModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get baseUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set baseUrl($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBaseUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearBaseUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get currentRelease => $_getMap(1);

  @$pb.TagNumber(3)
  $pb.PbList<FlutterReleaseModel> get releases => $_getList(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
