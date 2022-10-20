///
//  Generated code. Do not modify.
//  source: flutter_releases.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class FlutterReleaseModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FlutterReleaseModel',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'hash')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'channel')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'version')
    ..aOS(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'dartSdkVersion')
    ..aOS(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'dartSdkArch')
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'releaseDate')
    ..aOS(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'archive')
    ..aOS(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sha256')
    ..hasRequiredFields = false;

  FlutterReleaseModel._() : super();
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
    final _result = create();
    if (hash != null) {
      _result.hash = hash;
    }
    if (channel != null) {
      _result.channel = channel;
    }
    if (version != null) {
      _result.version = version;
    }
    if (dartSdkVersion != null) {
      _result.dartSdkVersion = dartSdkVersion;
    }
    if (dartSdkArch != null) {
      _result.dartSdkArch = dartSdkArch;
    }
    if (releaseDate != null) {
      _result.releaseDate = releaseDate;
    }
    if (archive != null) {
      _result.archive = archive;
    }
    if (sha256 != null) {
      _result.sha256 = sha256;
    }
    return _result;
  }
  factory FlutterReleaseModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FlutterReleaseModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FlutterReleaseModel clone() => FlutterReleaseModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FlutterReleaseModel copyWith(void Function(FlutterReleaseModel) updates) =>
      super.copyWith((message) => updates(message as FlutterReleaseModel))
          as FlutterReleaseModel; // ignore: deprecated_member_use
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
  void clearHash() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get channel => $_getSZ(1);
  @$pb.TagNumber(2)
  set channel($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasChannel() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannel() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get dartSdkVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set dartSdkVersion($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasDartSdkVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearDartSdkVersion() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get dartSdkArch => $_getSZ(4);
  @$pb.TagNumber(5)
  set dartSdkArch($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasDartSdkArch() => $_has(4);
  @$pb.TagNumber(5)
  void clearDartSdkArch() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get releaseDate => $_getSZ(5);
  @$pb.TagNumber(6)
  set releaseDate($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasReleaseDate() => $_has(5);
  @$pb.TagNumber(6)
  void clearReleaseDate() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get archive => $_getSZ(6);
  @$pb.TagNumber(7)
  set archive($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasArchive() => $_has(6);
  @$pb.TagNumber(7)
  void clearArchive() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get sha256 => $_getSZ(7);
  @$pb.TagNumber(8)
  set sha256($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasSha256() => $_has(7);
  @$pb.TagNumber(8)
  void clearSha256() => clearField(8);
}

class FlutterReleasesModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FlutterReleasesModel',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'baseUrl')
    ..m<$core.String, $core.String>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'currentRelease',
        entryClassName: 'FlutterReleasesModel.CurrentReleaseEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS)
    ..pc<FlutterReleaseModel>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'releases',
        $pb.PbFieldType.PM,
        subBuilder: FlutterReleaseModel.create)
    ..hasRequiredFields = false;

  FlutterReleasesModel._() : super();
  factory FlutterReleasesModel({
    $core.String? baseUrl,
    $core.Map<$core.String, $core.String>? currentRelease,
    $core.Iterable<FlutterReleaseModel>? releases,
  }) {
    final _result = create();
    if (baseUrl != null) {
      _result.baseUrl = baseUrl;
    }
    if (currentRelease != null) {
      _result.currentRelease.addAll(currentRelease);
    }
    if (releases != null) {
      _result.releases.addAll(releases);
    }
    return _result;
  }
  factory FlutterReleasesModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FlutterReleasesModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
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
          as FlutterReleasesModel; // ignore: deprecated_member_use
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
  void clearBaseUrl() => clearField(1);

  @$pb.TagNumber(2)
  $core.Map<$core.String, $core.String> get currentRelease => $_getMap(1);

  @$pb.TagNumber(3)
  $core.List<FlutterReleaseModel> get releases => $_getList(2);
}
