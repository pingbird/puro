///
//  Generated code. Do not modify.
//  source: puro.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CommandErrorModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'CommandErrorModel',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'exception')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'exceptionType',
        protoName: 'exceptionType')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'stackTrace',
        protoName: 'stackTrace')
    ..hasRequiredFields = false;

  CommandErrorModel._() : super();
  factory CommandErrorModel({
    $core.String? exception,
    $core.String? exceptionType,
    $core.String? stackTrace,
  }) {
    final _result = create();
    if (exception != null) {
      _result.exception = exception;
    }
    if (exceptionType != null) {
      _result.exceptionType = exceptionType;
    }
    if (stackTrace != null) {
      _result.stackTrace = stackTrace;
    }
    return _result;
  }
  factory CommandErrorModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommandErrorModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommandErrorModel clone() => CommandErrorModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommandErrorModel copyWith(void Function(CommandErrorModel) updates) =>
      super.copyWith((message) => updates(message as CommandErrorModel))
          as CommandErrorModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CommandErrorModel create() => CommandErrorModel._();
  CommandErrorModel createEmptyInstance() => create();
  static $pb.PbList<CommandErrorModel> createRepeated() =>
      $pb.PbList<CommandErrorModel>();
  @$core.pragma('dart2js:noInline')
  static CommandErrorModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CommandErrorModel>(create);
  static CommandErrorModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get exception => $_getSZ(0);
  @$pb.TagNumber(1)
  set exception($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasException() => $_has(0);
  @$pb.TagNumber(1)
  void clearException() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get exceptionType => $_getSZ(1);
  @$pb.TagNumber(2)
  set exceptionType($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasExceptionType() => $_has(1);
  @$pb.TagNumber(2)
  void clearExceptionType() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get stackTrace => $_getSZ(2);
  @$pb.TagNumber(3)
  set stackTrace($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStackTrace() => $_has(2);
  @$pb.TagNumber(3)
  void clearStackTrace() => clearField(3);
}

class LogEntryModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'LogEntryModel',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'timestamp')
    ..a<$core.int>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'level',
        $pb.PbFieldType.O3)
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'message')
    ..hasRequiredFields = false;

  LogEntryModel._() : super();
  factory LogEntryModel({
    $core.String? timestamp,
    $core.int? level,
    $core.String? message,
  }) {
    final _result = create();
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    if (level != null) {
      _result.level = level;
    }
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory LogEntryModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LogEntryModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LogEntryModel clone() => LogEntryModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LogEntryModel copyWith(void Function(LogEntryModel) updates) =>
      super.copyWith((message) => updates(message as LogEntryModel))
          as LogEntryModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static LogEntryModel create() => LogEntryModel._();
  LogEntryModel createEmptyInstance() => create();
  static $pb.PbList<LogEntryModel> createRepeated() =>
      $pb.PbList<LogEntryModel>();
  @$core.pragma('dart2js:noInline')
  static LogEntryModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LogEntryModel>(create);
  static LogEntryModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get timestamp => $_getSZ(0);
  @$pb.TagNumber(1)
  set timestamp($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get level => $_getIZ(1);
  @$pb.TagNumber(2)
  set level($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLevel() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => clearField(3);
}

class FlutterVersionModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'FlutterVersionModel',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'commit')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'version')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'branch')
    ..aOS(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'tag')
    ..hasRequiredFields = false;

  FlutterVersionModel._() : super();
  factory FlutterVersionModel({
    $core.String? commit,
    $core.String? version,
    $core.String? branch,
    $core.String? tag,
  }) {
    final _result = create();
    if (commit != null) {
      _result.commit = commit;
    }
    if (version != null) {
      _result.version = version;
    }
    if (branch != null) {
      _result.branch = branch;
    }
    if (tag != null) {
      _result.tag = tag;
    }
    return _result;
  }
  factory FlutterVersionModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FlutterVersionModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FlutterVersionModel clone() => FlutterVersionModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FlutterVersionModel copyWith(void Function(FlutterVersionModel) updates) =>
      super.copyWith((message) => updates(message as FlutterVersionModel))
          as FlutterVersionModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FlutterVersionModel create() => FlutterVersionModel._();
  FlutterVersionModel createEmptyInstance() => create();
  static $pb.PbList<FlutterVersionModel> createRepeated() =>
      $pb.PbList<FlutterVersionModel>();
  @$core.pragma('dart2js:noInline')
  static FlutterVersionModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FlutterVersionModel>(create);
  static FlutterVersionModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get commit => $_getSZ(0);
  @$pb.TagNumber(1)
  set commit($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCommit() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommit() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get branch => $_getSZ(2);
  @$pb.TagNumber(3)
  set branch($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBranch() => $_has(2);
  @$pb.TagNumber(3)
  void clearBranch() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get tag => $_getSZ(3);
  @$pb.TagNumber(4)
  set tag($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasTag() => $_has(3);
  @$pb.TagNumber(4)
  void clearTag() => clearField(4);
}

class EnvironmentInfoModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EnvironmentInfoModel',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'path')
    ..aOM<FlutterVersionModel>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'version',
        subBuilder: FlutterVersionModel.create)
    ..hasRequiredFields = false;

  EnvironmentInfoModel._() : super();
  factory EnvironmentInfoModel({
    $core.String? name,
    $core.String? path,
    FlutterVersionModel? version,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (path != null) {
      _result.path = path;
    }
    if (version != null) {
      _result.version = version;
    }
    return _result;
  }
  factory EnvironmentInfoModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnvironmentInfoModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EnvironmentInfoModel clone() =>
      EnvironmentInfoModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EnvironmentInfoModel copyWith(void Function(EnvironmentInfoModel) updates) =>
      super.copyWith((message) => updates(message as EnvironmentInfoModel))
          as EnvironmentInfoModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EnvironmentInfoModel create() => EnvironmentInfoModel._();
  EnvironmentInfoModel createEmptyInstance() => create();
  static $pb.PbList<EnvironmentInfoModel> createRepeated() =>
      $pb.PbList<EnvironmentInfoModel>();
  @$core.pragma('dart2js:noInline')
  static EnvironmentInfoModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnvironmentInfoModel>(create);
  static EnvironmentInfoModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => clearField(2);

  @$pb.TagNumber(3)
  FlutterVersionModel get version => $_getN(2);
  @$pb.TagNumber(3)
  set version(FlutterVersionModel v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => clearField(3);
  @$pb.TagNumber(3)
  FlutterVersionModel ensureVersion() => $_ensure(2);
}

class EnvironmentListModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EnvironmentListModel',
      createEmptyInstance: create)
    ..pc<EnvironmentInfoModel>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'environments',
        $pb.PbFieldType.PM,
        subBuilder: EnvironmentInfoModel.create)
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'selectedEnvironment',
        protoName: 'selectedEnvironment')
    ..hasRequiredFields = false;

  EnvironmentListModel._() : super();
  factory EnvironmentListModel({
    $core.Iterable<EnvironmentInfoModel>? environments,
    $core.String? selectedEnvironment,
  }) {
    final _result = create();
    if (environments != null) {
      _result.environments.addAll(environments);
    }
    if (selectedEnvironment != null) {
      _result.selectedEnvironment = selectedEnvironment;
    }
    return _result;
  }
  factory EnvironmentListModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnvironmentListModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EnvironmentListModel clone() =>
      EnvironmentListModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EnvironmentListModel copyWith(void Function(EnvironmentListModel) updates) =>
      super.copyWith((message) => updates(message as EnvironmentListModel))
          as EnvironmentListModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EnvironmentListModel create() => EnvironmentListModel._();
  EnvironmentListModel createEmptyInstance() => create();
  static $pb.PbList<EnvironmentListModel> createRepeated() =>
      $pb.PbList<EnvironmentListModel>();
  @$core.pragma('dart2js:noInline')
  static EnvironmentListModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnvironmentListModel>(create);
  static EnvironmentListModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<EnvironmentInfoModel> get environments => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get selectedEnvironment => $_getSZ(1);
  @$pb.TagNumber(2)
  set selectedEnvironment($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSelectedEnvironment() => $_has(1);
  @$pb.TagNumber(2)
  void clearSelectedEnvironment() => clearField(2);
}

class EnvironmentUpgradeModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EnvironmentUpgradeModel',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'name')
    ..aOM<FlutterVersionModel>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'from',
        subBuilder: FlutterVersionModel.create)
    ..aOM<FlutterVersionModel>(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'to',
        subBuilder: FlutterVersionModel.create)
    ..hasRequiredFields = false;

  EnvironmentUpgradeModel._() : super();
  factory EnvironmentUpgradeModel({
    $core.String? name,
    FlutterVersionModel? from,
    FlutterVersionModel? to,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (from != null) {
      _result.from = from;
    }
    if (to != null) {
      _result.to = to;
    }
    return _result;
  }
  factory EnvironmentUpgradeModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnvironmentUpgradeModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EnvironmentUpgradeModel clone() =>
      EnvironmentUpgradeModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EnvironmentUpgradeModel copyWith(
          void Function(EnvironmentUpgradeModel) updates) =>
      super.copyWith((message) => updates(message as EnvironmentUpgradeModel))
          as EnvironmentUpgradeModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EnvironmentUpgradeModel create() => EnvironmentUpgradeModel._();
  EnvironmentUpgradeModel createEmptyInstance() => create();
  static $pb.PbList<EnvironmentUpgradeModel> createRepeated() =>
      $pb.PbList<EnvironmentUpgradeModel>();
  @$core.pragma('dart2js:noInline')
  static EnvironmentUpgradeModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnvironmentUpgradeModel>(create);
  static EnvironmentUpgradeModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  FlutterVersionModel get from => $_getN(1);
  @$pb.TagNumber(2)
  set from(FlutterVersionModel v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasFrom() => $_has(1);
  @$pb.TagNumber(2)
  void clearFrom() => clearField(2);
  @$pb.TagNumber(2)
  FlutterVersionModel ensureFrom() => $_ensure(1);

  @$pb.TagNumber(3)
  FlutterVersionModel get to => $_getN(2);
  @$pb.TagNumber(3)
  set to(FlutterVersionModel v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTo() => $_has(2);
  @$pb.TagNumber(3)
  void clearTo() => clearField(3);
  @$pb.TagNumber(3)
  FlutterVersionModel ensureTo() => $_ensure(2);
}

class CommandMessageModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'CommandMessageModel',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'type')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'message')
    ..hasRequiredFields = false;

  CommandMessageModel._() : super();
  factory CommandMessageModel({
    $core.String? type,
    $core.String? message,
  }) {
    final _result = create();
    if (type != null) {
      _result.type = type;
    }
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory CommandMessageModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommandMessageModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommandMessageModel clone() => CommandMessageModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommandMessageModel copyWith(void Function(CommandMessageModel) updates) =>
      super.copyWith((message) => updates(message as CommandMessageModel))
          as CommandMessageModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CommandMessageModel create() => CommandMessageModel._();
  CommandMessageModel createEmptyInstance() => create();
  static $pb.PbList<CommandMessageModel> createRepeated() =>
      $pb.PbList<CommandMessageModel>();
  @$core.pragma('dart2js:noInline')
  static CommandMessageModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CommandMessageModel>(create);
  static CommandMessageModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => clearField(2);
}

class CommandResultModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'CommandResultModel',
      createEmptyInstance: create)
    ..aOB(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'success')
    ..pc<CommandMessageModel>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'messages',
        $pb.PbFieldType.PM,
        subBuilder: CommandMessageModel.create)
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'usage')
    ..aOM<CommandErrorModel>(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'error',
        subBuilder: CommandErrorModel.create)
    ..pc<LogEntryModel>(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'logs',
        $pb.PbFieldType.PM,
        subBuilder: LogEntryModel.create)
    ..aOM<EnvironmentListModel>(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'environmentList',
        protoName: 'environmentList',
        subBuilder: EnvironmentListModel.create)
    ..aOM<EnvironmentUpgradeModel>(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'environmentUpgrade',
        protoName: 'environmentUpgrade',
        subBuilder: EnvironmentUpgradeModel.create)
    ..hasRequiredFields = false;

  CommandResultModel._() : super();
  factory CommandResultModel({
    $core.bool? success,
    $core.Iterable<CommandMessageModel>? messages,
    $core.String? usage,
    CommandErrorModel? error,
    $core.Iterable<LogEntryModel>? logs,
    EnvironmentListModel? environmentList,
    EnvironmentUpgradeModel? environmentUpgrade,
  }) {
    final _result = create();
    if (success != null) {
      _result.success = success;
    }
    if (messages != null) {
      _result.messages.addAll(messages);
    }
    if (usage != null) {
      _result.usage = usage;
    }
    if (error != null) {
      _result.error = error;
    }
    if (logs != null) {
      _result.logs.addAll(logs);
    }
    if (environmentList != null) {
      _result.environmentList = environmentList;
    }
    if (environmentUpgrade != null) {
      _result.environmentUpgrade = environmentUpgrade;
    }
    return _result;
  }
  factory CommandResultModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommandResultModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommandResultModel clone() => CommandResultModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommandResultModel copyWith(void Function(CommandResultModel) updates) =>
      super.copyWith((message) => updates(message as CommandResultModel))
          as CommandResultModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CommandResultModel create() => CommandResultModel._();
  CommandResultModel createEmptyInstance() => create();
  static $pb.PbList<CommandResultModel> createRepeated() =>
      $pb.PbList<CommandResultModel>();
  @$core.pragma('dart2js:noInline')
  static CommandResultModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CommandResultModel>(create);
  static CommandResultModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<CommandMessageModel> get messages => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get usage => $_getSZ(2);
  @$pb.TagNumber(3)
  set usage($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasUsage() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsage() => clearField(3);

  @$pb.TagNumber(4)
  CommandErrorModel get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(CommandErrorModel v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => clearField(4);
  @$pb.TagNumber(4)
  CommandErrorModel ensureError() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.List<LogEntryModel> get logs => $_getList(4);

  @$pb.TagNumber(6)
  EnvironmentListModel get environmentList => $_getN(5);
  @$pb.TagNumber(6)
  set environmentList(EnvironmentListModel v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasEnvironmentList() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnvironmentList() => clearField(6);
  @$pb.TagNumber(6)
  EnvironmentListModel ensureEnvironmentList() => $_ensure(5);

  @$pb.TagNumber(7)
  EnvironmentUpgradeModel get environmentUpgrade => $_getN(6);
  @$pb.TagNumber(7)
  set environmentUpgrade(EnvironmentUpgradeModel v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasEnvironmentUpgrade() => $_has(6);
  @$pb.TagNumber(7)
  void clearEnvironmentUpgrade() => clearField(7);
  @$pb.TagNumber(7)
  EnvironmentUpgradeModel ensureEnvironmentUpgrade() => $_ensure(6);
}

class PuroGlobalPrefsModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'PuroGlobalPrefsModel',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'defaultEnvironment',
        protoName: 'defaultEnvironment')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'lastUpdateCheck',
        protoName: 'lastUpdateCheck')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'lastUpdateNotification',
        protoName: 'lastUpdateNotification')
    ..aOB(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'enableUpdateCheck',
        protoName: 'enableUpdateCheck')
    ..aOB(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'enableProfileUpdate',
        protoName: 'enableProfileUpdate')
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'profileOverride',
        protoName: 'profileOverride')
    ..hasRequiredFields = false;

  PuroGlobalPrefsModel._() : super();
  factory PuroGlobalPrefsModel({
    $core.String? defaultEnvironment,
    $core.String? lastUpdateCheck,
    $core.String? lastUpdateNotification,
    $core.bool? enableUpdateCheck,
    $core.bool? enableProfileUpdate,
    $core.String? profileOverride,
  }) {
    final _result = create();
    if (defaultEnvironment != null) {
      _result.defaultEnvironment = defaultEnvironment;
    }
    if (lastUpdateCheck != null) {
      _result.lastUpdateCheck = lastUpdateCheck;
    }
    if (lastUpdateNotification != null) {
      _result.lastUpdateNotification = lastUpdateNotification;
    }
    if (enableUpdateCheck != null) {
      _result.enableUpdateCheck = enableUpdateCheck;
    }
    if (enableProfileUpdate != null) {
      _result.enableProfileUpdate = enableProfileUpdate;
    }
    if (profileOverride != null) {
      _result.profileOverride = profileOverride;
    }
    return _result;
  }
  factory PuroGlobalPrefsModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PuroGlobalPrefsModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PuroGlobalPrefsModel clone() =>
      PuroGlobalPrefsModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PuroGlobalPrefsModel copyWith(void Function(PuroGlobalPrefsModel) updates) =>
      super.copyWith((message) => updates(message as PuroGlobalPrefsModel))
          as PuroGlobalPrefsModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PuroGlobalPrefsModel create() => PuroGlobalPrefsModel._();
  PuroGlobalPrefsModel createEmptyInstance() => create();
  static $pb.PbList<PuroGlobalPrefsModel> createRepeated() =>
      $pb.PbList<PuroGlobalPrefsModel>();
  @$core.pragma('dart2js:noInline')
  static PuroGlobalPrefsModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PuroGlobalPrefsModel>(create);
  static PuroGlobalPrefsModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get defaultEnvironment => $_getSZ(0);
  @$pb.TagNumber(1)
  set defaultEnvironment($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasDefaultEnvironment() => $_has(0);
  @$pb.TagNumber(1)
  void clearDefaultEnvironment() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get lastUpdateCheck => $_getSZ(1);
  @$pb.TagNumber(2)
  set lastUpdateCheck($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLastUpdateCheck() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastUpdateCheck() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get lastUpdateNotification => $_getSZ(2);
  @$pb.TagNumber(3)
  set lastUpdateNotification($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasLastUpdateNotification() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastUpdateNotification() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get enableUpdateCheck => $_getBF(3);
  @$pb.TagNumber(4)
  set enableUpdateCheck($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasEnableUpdateCheck() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnableUpdateCheck() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get enableProfileUpdate => $_getBF(4);
  @$pb.TagNumber(5)
  set enableProfileUpdate($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasEnableProfileUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnableProfileUpdate() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get profileOverride => $_getSZ(5);
  @$pb.TagNumber(6)
  set profileOverride($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasProfileOverride() => $_has(5);
  @$pb.TagNumber(6)
  void clearProfileOverride() => clearField(6);
}

class PuroEnvPrefsModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'PuroEnvPrefsModel',
      createEmptyInstance: create)
    ..aOM<FlutterVersionModel>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'desiredVersion',
        protoName: 'desiredVersion',
        subBuilder: FlutterVersionModel.create)
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'forkRemoteUrl',
        protoName: 'forkRemoteUrl')
    ..hasRequiredFields = false;

  PuroEnvPrefsModel._() : super();
  factory PuroEnvPrefsModel({
    FlutterVersionModel? desiredVersion,
    $core.String? forkRemoteUrl,
  }) {
    final _result = create();
    if (desiredVersion != null) {
      _result.desiredVersion = desiredVersion;
    }
    if (forkRemoteUrl != null) {
      _result.forkRemoteUrl = forkRemoteUrl;
    }
    return _result;
  }
  factory PuroEnvPrefsModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PuroEnvPrefsModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PuroEnvPrefsModel clone() => PuroEnvPrefsModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PuroEnvPrefsModel copyWith(void Function(PuroEnvPrefsModel) updates) =>
      super.copyWith((message) => updates(message as PuroEnvPrefsModel))
          as PuroEnvPrefsModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PuroEnvPrefsModel create() => PuroEnvPrefsModel._();
  PuroEnvPrefsModel createEmptyInstance() => create();
  static $pb.PbList<PuroEnvPrefsModel> createRepeated() =>
      $pb.PbList<PuroEnvPrefsModel>();
  @$core.pragma('dart2js:noInline')
  static PuroEnvPrefsModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PuroEnvPrefsModel>(create);
  static PuroEnvPrefsModel? _defaultInstance;

  @$pb.TagNumber(1)
  FlutterVersionModel get desiredVersion => $_getN(0);
  @$pb.TagNumber(1)
  set desiredVersion(FlutterVersionModel v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasDesiredVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearDesiredVersion() => clearField(1);
  @$pb.TagNumber(1)
  FlutterVersionModel ensureDesiredVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get forkRemoteUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set forkRemoteUrl($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasForkRemoteUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearForkRemoteUrl() => clearField(2);
}

class PuroDotfileModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'PuroDotfileModel',
      createEmptyInstance: create)
    ..aOS(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'env')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'previousDartSdk',
        protoName: 'previousDartSdk')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'previousFlutterSdk',
        protoName: 'previousFlutterSdk')
    ..hasRequiredFields = false;

  PuroDotfileModel._() : super();
  factory PuroDotfileModel({
    $core.String? env,
    $core.String? previousDartSdk,
    $core.String? previousFlutterSdk,
  }) {
    final _result = create();
    if (env != null) {
      _result.env = env;
    }
    if (previousDartSdk != null) {
      _result.previousDartSdk = previousDartSdk;
    }
    if (previousFlutterSdk != null) {
      _result.previousFlutterSdk = previousFlutterSdk;
    }
    return _result;
  }
  factory PuroDotfileModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PuroDotfileModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PuroDotfileModel clone() => PuroDotfileModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PuroDotfileModel copyWith(void Function(PuroDotfileModel) updates) =>
      super.copyWith((message) => updates(message as PuroDotfileModel))
          as PuroDotfileModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static PuroDotfileModel create() => PuroDotfileModel._();
  PuroDotfileModel createEmptyInstance() => create();
  static $pb.PbList<PuroDotfileModel> createRepeated() =>
      $pb.PbList<PuroDotfileModel>();
  @$core.pragma('dart2js:noInline')
  static PuroDotfileModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PuroDotfileModel>(create);
  static PuroDotfileModel? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get env => $_getSZ(0);
  @$pb.TagNumber(1)
  set env($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEnv() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnv() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get previousDartSdk => $_getSZ(1);
  @$pb.TagNumber(2)
  set previousDartSdk($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPreviousDartSdk() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreviousDartSdk() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get previousFlutterSdk => $_getSZ(2);
  @$pb.TagNumber(3)
  set previousFlutterSdk($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPreviousFlutterSdk() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreviousFlutterSdk() => clearField(3);
}
