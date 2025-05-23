//
//  Generated code. Do not modify.
//  source: puro.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class CommandErrorModel extends $pb.GeneratedMessage {
  factory CommandErrorModel({
    $core.String? exception,
    $core.String? exceptionType,
    $core.String? stackTrace,
  }) {
    final $result = create();
    if (exception != null) {
      $result.exception = exception;
    }
    if (exceptionType != null) {
      $result.exceptionType = exceptionType;
    }
    if (stackTrace != null) {
      $result.stackTrace = stackTrace;
    }
    return $result;
  }
  CommandErrorModel._() : super();
  factory CommandErrorModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommandErrorModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CommandErrorModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'exception')
    ..aOS(2, _omitFieldNames ? '' : 'exceptionType', protoName: 'exceptionType')
    ..aOS(3, _omitFieldNames ? '' : 'stackTrace', protoName: 'stackTrace')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommandErrorModel clone() => CommandErrorModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommandErrorModel copyWith(void Function(CommandErrorModel) updates) =>
      super.copyWith((message) => updates(message as CommandErrorModel))
          as CommandErrorModel;

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
  void clearException() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get exceptionType => $_getSZ(1);
  @$pb.TagNumber(2)
  set exceptionType($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasExceptionType() => $_has(1);
  @$pb.TagNumber(2)
  void clearExceptionType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get stackTrace => $_getSZ(2);
  @$pb.TagNumber(3)
  set stackTrace($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStackTrace() => $_has(2);
  @$pb.TagNumber(3)
  void clearStackTrace() => $_clearField(3);
}

class LogEntryModel extends $pb.GeneratedMessage {
  factory LogEntryModel({
    $core.String? timestamp,
    $core.int? level,
    $core.String? message,
  }) {
    final $result = create();
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    if (level != null) {
      $result.level = level;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  LogEntryModel._() : super();
  factory LogEntryModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory LogEntryModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogEntryModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'timestamp')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'level', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  LogEntryModel clone() => LogEntryModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  LogEntryModel copyWith(void Function(LogEntryModel) updates) =>
      super.copyWith((message) => updates(message as LogEntryModel))
          as LogEntryModel;

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
  void clearTimestamp() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get level => $_getIZ(1);
  @$pb.TagNumber(2)
  set level($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLevel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLevel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

class FlutterVersionModel extends $pb.GeneratedMessage {
  factory FlutterVersionModel({
    $core.String? commit,
    $core.String? version,
    $core.String? branch,
    $core.String? tag,
  }) {
    final $result = create();
    if (commit != null) {
      $result.commit = commit;
    }
    if (version != null) {
      $result.version = version;
    }
    if (branch != null) {
      $result.branch = branch;
    }
    if (tag != null) {
      $result.tag = tag;
    }
    return $result;
  }
  FlutterVersionModel._() : super();
  factory FlutterVersionModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FlutterVersionModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FlutterVersionModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'commit')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'branch')
    ..aOS(4, _omitFieldNames ? '' : 'tag')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FlutterVersionModel clone() => FlutterVersionModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FlutterVersionModel copyWith(void Function(FlutterVersionModel) updates) =>
      super.copyWith((message) => updates(message as FlutterVersionModel))
          as FlutterVersionModel;

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
  void clearCommit() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get branch => $_getSZ(2);
  @$pb.TagNumber(3)
  set branch($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBranch() => $_has(2);
  @$pb.TagNumber(3)
  void clearBranch() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get tag => $_getSZ(3);
  @$pb.TagNumber(4)
  set tag($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasTag() => $_has(3);
  @$pb.TagNumber(4)
  void clearTag() => $_clearField(4);
}

class EnvironmentInfoModel extends $pb.GeneratedMessage {
  factory EnvironmentInfoModel({
    $core.String? name,
    $core.String? path,
    FlutterVersionModel? version,
    $core.Iterable<$core.String>? projects,
    $core.String? dartVersion,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (path != null) {
      $result.path = path;
    }
    if (version != null) {
      $result.version = version;
    }
    if (projects != null) {
      $result.projects.addAll(projects);
    }
    if (dartVersion != null) {
      $result.dartVersion = dartVersion;
    }
    return $result;
  }
  EnvironmentInfoModel._() : super();
  factory EnvironmentInfoModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnvironmentInfoModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnvironmentInfoModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOM<FlutterVersionModel>(3, _omitFieldNames ? '' : 'version',
        subBuilder: FlutterVersionModel.create)
    ..pPS(4, _omitFieldNames ? '' : 'projects')
    ..aOS(5, _omitFieldNames ? '' : 'dartVersion', protoName: 'dartVersion')
    ..hasRequiredFields = false;

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
          as EnvironmentInfoModel;

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
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  FlutterVersionModel get version => $_getN(2);
  @$pb.TagNumber(3)
  set version(FlutterVersionModel v) {
    $_setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);
  @$pb.TagNumber(3)
  FlutterVersionModel ensureVersion() => $_ensure(2);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get projects => $_getList(3);

  @$pb.TagNumber(5)
  $core.String get dartVersion => $_getSZ(4);
  @$pb.TagNumber(5)
  set dartVersion($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasDartVersion() => $_has(4);
  @$pb.TagNumber(5)
  void clearDartVersion() => $_clearField(5);
}

class EnvironmentListModel extends $pb.GeneratedMessage {
  factory EnvironmentListModel({
    $core.Iterable<EnvironmentInfoModel>? environments,
    $core.String? projectEnvironment,
    $core.String? globalEnvironment,
  }) {
    final $result = create();
    if (environments != null) {
      $result.environments.addAll(environments);
    }
    if (projectEnvironment != null) {
      $result.projectEnvironment = projectEnvironment;
    }
    if (globalEnvironment != null) {
      $result.globalEnvironment = globalEnvironment;
    }
    return $result;
  }
  EnvironmentListModel._() : super();
  factory EnvironmentListModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnvironmentListModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnvironmentListModel',
      createEmptyInstance: create)
    ..pc<EnvironmentInfoModel>(
        1, _omitFieldNames ? '' : 'environments', $pb.PbFieldType.PM,
        subBuilder: EnvironmentInfoModel.create)
    ..aOS(2, _omitFieldNames ? '' : 'projectEnvironment',
        protoName: 'projectEnvironment')
    ..aOS(3, _omitFieldNames ? '' : 'globalEnvironment',
        protoName: 'globalEnvironment')
    ..hasRequiredFields = false;

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
          as EnvironmentListModel;

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
  $pb.PbList<EnvironmentInfoModel> get environments => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get projectEnvironment => $_getSZ(1);
  @$pb.TagNumber(2)
  set projectEnvironment($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasProjectEnvironment() => $_has(1);
  @$pb.TagNumber(2)
  void clearProjectEnvironment() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get globalEnvironment => $_getSZ(2);
  @$pb.TagNumber(3)
  set globalEnvironment($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasGlobalEnvironment() => $_has(2);
  @$pb.TagNumber(3)
  void clearGlobalEnvironment() => $_clearField(3);
}

class EnvironmentUpgradeModel extends $pb.GeneratedMessage {
  factory EnvironmentUpgradeModel({
    $core.String? name,
    FlutterVersionModel? from,
    FlutterVersionModel? to,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (from != null) {
      $result.from = from;
    }
    if (to != null) {
      $result.to = to;
    }
    return $result;
  }
  EnvironmentUpgradeModel._() : super();
  factory EnvironmentUpgradeModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnvironmentUpgradeModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnvironmentUpgradeModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOM<FlutterVersionModel>(2, _omitFieldNames ? '' : 'from',
        subBuilder: FlutterVersionModel.create)
    ..aOM<FlutterVersionModel>(3, _omitFieldNames ? '' : 'to',
        subBuilder: FlutterVersionModel.create)
    ..hasRequiredFields = false;

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
          as EnvironmentUpgradeModel;

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
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  FlutterVersionModel get from => $_getN(1);
  @$pb.TagNumber(2)
  set from(FlutterVersionModel v) {
    $_setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasFrom() => $_has(1);
  @$pb.TagNumber(2)
  void clearFrom() => $_clearField(2);
  @$pb.TagNumber(2)
  FlutterVersionModel ensureFrom() => $_ensure(1);

  @$pb.TagNumber(3)
  FlutterVersionModel get to => $_getN(2);
  @$pb.TagNumber(3)
  set to(FlutterVersionModel v) {
    $_setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTo() => $_has(2);
  @$pb.TagNumber(3)
  void clearTo() => $_clearField(3);
  @$pb.TagNumber(3)
  FlutterVersionModel ensureTo() => $_ensure(2);
}

class CommandMessageModel extends $pb.GeneratedMessage {
  factory CommandMessageModel({
    $core.String? type,
    $core.String? message,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  CommandMessageModel._() : super();
  factory CommandMessageModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommandMessageModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CommandMessageModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommandMessageModel clone() => CommandMessageModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommandMessageModel copyWith(void Function(CommandMessageModel) updates) =>
      super.copyWith((message) => updates(message as CommandMessageModel))
          as CommandMessageModel;

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
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class CommandResultModel extends $pb.GeneratedMessage {
  factory CommandResultModel({
    $core.bool? success,
    $core.Iterable<CommandMessageModel>? messages,
    $core.String? usage,
    CommandErrorModel? error,
    $core.Iterable<LogEntryModel>? logs,
    EnvironmentListModel? environmentList,
    EnvironmentUpgradeModel? environmentUpgrade,
  }) {
    final $result = create();
    if (success != null) {
      $result.success = success;
    }
    if (messages != null) {
      $result.messages.addAll(messages);
    }
    if (usage != null) {
      $result.usage = usage;
    }
    if (error != null) {
      $result.error = error;
    }
    if (logs != null) {
      $result.logs.addAll(logs);
    }
    if (environmentList != null) {
      $result.environmentList = environmentList;
    }
    if (environmentUpgrade != null) {
      $result.environmentUpgrade = environmentUpgrade;
    }
    return $result;
  }
  CommandResultModel._() : super();
  factory CommandResultModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommandResultModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CommandResultModel',
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..pc<CommandMessageModel>(
        2, _omitFieldNames ? '' : 'messages', $pb.PbFieldType.PM,
        subBuilder: CommandMessageModel.create)
    ..aOS(3, _omitFieldNames ? '' : 'usage')
    ..aOM<CommandErrorModel>(4, _omitFieldNames ? '' : 'error',
        subBuilder: CommandErrorModel.create)
    ..pc<LogEntryModel>(5, _omitFieldNames ? '' : 'logs', $pb.PbFieldType.PM,
        subBuilder: LogEntryModel.create)
    ..aOM<EnvironmentListModel>(6, _omitFieldNames ? '' : 'environmentList',
        protoName: 'environmentList', subBuilder: EnvironmentListModel.create)
    ..aOM<EnvironmentUpgradeModel>(
        7, _omitFieldNames ? '' : 'environmentUpgrade',
        protoName: 'environmentUpgrade',
        subBuilder: EnvironmentUpgradeModel.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommandResultModel clone() => CommandResultModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommandResultModel copyWith(void Function(CommandResultModel) updates) =>
      super.copyWith((message) => updates(message as CommandResultModel))
          as CommandResultModel;

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
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<CommandMessageModel> get messages => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get usage => $_getSZ(2);
  @$pb.TagNumber(3)
  set usage($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasUsage() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsage() => $_clearField(3);

  @$pb.TagNumber(4)
  CommandErrorModel get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(CommandErrorModel v) {
    $_setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  CommandErrorModel ensureError() => $_ensure(3);

  @$pb.TagNumber(5)
  $pb.PbList<LogEntryModel> get logs => $_getList(4);

  @$pb.TagNumber(6)
  EnvironmentListModel get environmentList => $_getN(5);
  @$pb.TagNumber(6)
  set environmentList(EnvironmentListModel v) {
    $_setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasEnvironmentList() => $_has(5);
  @$pb.TagNumber(6)
  void clearEnvironmentList() => $_clearField(6);
  @$pb.TagNumber(6)
  EnvironmentListModel ensureEnvironmentList() => $_ensure(5);

  @$pb.TagNumber(7)
  EnvironmentUpgradeModel get environmentUpgrade => $_getN(6);
  @$pb.TagNumber(7)
  set environmentUpgrade(EnvironmentUpgradeModel v) {
    $_setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasEnvironmentUpgrade() => $_has(6);
  @$pb.TagNumber(7)
  void clearEnvironmentUpgrade() => $_clearField(7);
  @$pb.TagNumber(7)
  EnvironmentUpgradeModel ensureEnvironmentUpgrade() => $_ensure(6);
}

class PuroGlobalPrefsModel extends $pb.GeneratedMessage {
  factory PuroGlobalPrefsModel({
    $core.String? defaultEnvironment,
    $core.String? lastUpdateCheck,
    $core.String? lastUpdateNotification,
    $core.bool? enableUpdateCheck,
    $core.bool? enableProfileUpdate,
    $core.String? profileOverride,
    $core.Iterable<$core.String>? projectDotfiles,
    $core.String? lastUpdateNotificationCommand,
    $core.String? pubCacheDir,
    $core.String? flutterGitUrl,
    $core.String? engineGitUrl,
    $core.String? dartSdkGitUrl,
    $core.String? releasesJsonUrl,
    $core.String? flutterStorageBaseUrl,
    $core.String? puroBuildsUrl,
    $core.String? puroBuildTarget,
    $core.bool? shouldInstall,
    $core.bool? legacyPubCache,
  }) {
    final $result = create();
    if (defaultEnvironment != null) {
      $result.defaultEnvironment = defaultEnvironment;
    }
    if (lastUpdateCheck != null) {
      $result.lastUpdateCheck = lastUpdateCheck;
    }
    if (lastUpdateNotification != null) {
      $result.lastUpdateNotification = lastUpdateNotification;
    }
    if (enableUpdateCheck != null) {
      $result.enableUpdateCheck = enableUpdateCheck;
    }
    if (enableProfileUpdate != null) {
      $result.enableProfileUpdate = enableProfileUpdate;
    }
    if (profileOverride != null) {
      $result.profileOverride = profileOverride;
    }
    if (projectDotfiles != null) {
      $result.projectDotfiles.addAll(projectDotfiles);
    }
    if (lastUpdateNotificationCommand != null) {
      $result.lastUpdateNotificationCommand = lastUpdateNotificationCommand;
    }
    if (pubCacheDir != null) {
      $result.pubCacheDir = pubCacheDir;
    }
    if (flutterGitUrl != null) {
      $result.flutterGitUrl = flutterGitUrl;
    }
    if (engineGitUrl != null) {
      $result.engineGitUrl = engineGitUrl;
    }
    if (dartSdkGitUrl != null) {
      $result.dartSdkGitUrl = dartSdkGitUrl;
    }
    if (releasesJsonUrl != null) {
      $result.releasesJsonUrl = releasesJsonUrl;
    }
    if (flutterStorageBaseUrl != null) {
      $result.flutterStorageBaseUrl = flutterStorageBaseUrl;
    }
    if (puroBuildsUrl != null) {
      $result.puroBuildsUrl = puroBuildsUrl;
    }
    if (puroBuildTarget != null) {
      $result.puroBuildTarget = puroBuildTarget;
    }
    if (shouldInstall != null) {
      $result.shouldInstall = shouldInstall;
    }
    if (legacyPubCache != null) {
      $result.legacyPubCache = legacyPubCache;
    }
    return $result;
  }
  PuroGlobalPrefsModel._() : super();
  factory PuroGlobalPrefsModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PuroGlobalPrefsModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PuroGlobalPrefsModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'defaultEnvironment',
        protoName: 'defaultEnvironment')
    ..aOS(2, _omitFieldNames ? '' : 'lastUpdateCheck',
        protoName: 'lastUpdateCheck')
    ..aOS(3, _omitFieldNames ? '' : 'lastUpdateNotification',
        protoName: 'lastUpdateNotification')
    ..aOB(4, _omitFieldNames ? '' : 'enableUpdateCheck',
        protoName: 'enableUpdateCheck')
    ..aOB(5, _omitFieldNames ? '' : 'enableProfileUpdate',
        protoName: 'enableProfileUpdate')
    ..aOS(6, _omitFieldNames ? '' : 'profileOverride',
        protoName: 'profileOverride')
    ..pPS(7, _omitFieldNames ? '' : 'projectDotfiles',
        protoName: 'projectDotfiles')
    ..aOS(8, _omitFieldNames ? '' : 'lastUpdateNotificationCommand',
        protoName: 'lastUpdateNotificationCommand')
    ..aOS(9, _omitFieldNames ? '' : 'pubCacheDir', protoName: 'pubCacheDir')
    ..aOS(10, _omitFieldNames ? '' : 'flutterGitUrl',
        protoName: 'flutterGitUrl')
    ..aOS(11, _omitFieldNames ? '' : 'engineGitUrl', protoName: 'engineGitUrl')
    ..aOS(12, _omitFieldNames ? '' : 'dartSdkGitUrl',
        protoName: 'dartSdkGitUrl')
    ..aOS(13, _omitFieldNames ? '' : 'releasesJsonUrl',
        protoName: 'releasesJsonUrl')
    ..aOS(14, _omitFieldNames ? '' : 'flutterStorageBaseUrl',
        protoName: 'flutterStorageBaseUrl')
    ..aOS(15, _omitFieldNames ? '' : 'puroBuildsUrl',
        protoName: 'puroBuildsUrl')
    ..aOS(16, _omitFieldNames ? '' : 'puroBuildTarget',
        protoName: 'puroBuildTarget')
    ..aOB(18, _omitFieldNames ? '' : 'shouldInstall',
        protoName: 'shouldInstall')
    ..aOB(19, _omitFieldNames ? '' : 'legacyPubCache',
        protoName: 'legacyPubCache')
    ..hasRequiredFields = false;

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
          as PuroGlobalPrefsModel;

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
  void clearDefaultEnvironment() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get lastUpdateCheck => $_getSZ(1);
  @$pb.TagNumber(2)
  set lastUpdateCheck($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLastUpdateCheck() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastUpdateCheck() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get lastUpdateNotification => $_getSZ(2);
  @$pb.TagNumber(3)
  set lastUpdateNotification($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasLastUpdateNotification() => $_has(2);
  @$pb.TagNumber(3)
  void clearLastUpdateNotification() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get enableUpdateCheck => $_getBF(3);
  @$pb.TagNumber(4)
  set enableUpdateCheck($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasEnableUpdateCheck() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnableUpdateCheck() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get enableProfileUpdate => $_getBF(4);
  @$pb.TagNumber(5)
  set enableProfileUpdate($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasEnableProfileUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearEnableProfileUpdate() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get profileOverride => $_getSZ(5);
  @$pb.TagNumber(6)
  set profileOverride($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasProfileOverride() => $_has(5);
  @$pb.TagNumber(6)
  void clearProfileOverride() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get projectDotfiles => $_getList(6);

  @$pb.TagNumber(8)
  $core.String get lastUpdateNotificationCommand => $_getSZ(7);
  @$pb.TagNumber(8)
  set lastUpdateNotificationCommand($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasLastUpdateNotificationCommand() => $_has(7);
  @$pb.TagNumber(8)
  void clearLastUpdateNotificationCommand() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get pubCacheDir => $_getSZ(8);
  @$pb.TagNumber(9)
  set pubCacheDir($core.String v) {
    $_setString(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasPubCacheDir() => $_has(8);
  @$pb.TagNumber(9)
  void clearPubCacheDir() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get flutterGitUrl => $_getSZ(9);
  @$pb.TagNumber(10)
  set flutterGitUrl($core.String v) {
    $_setString(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasFlutterGitUrl() => $_has(9);
  @$pb.TagNumber(10)
  void clearFlutterGitUrl() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get engineGitUrl => $_getSZ(10);
  @$pb.TagNumber(11)
  set engineGitUrl($core.String v) {
    $_setString(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasEngineGitUrl() => $_has(10);
  @$pb.TagNumber(11)
  void clearEngineGitUrl() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get dartSdkGitUrl => $_getSZ(11);
  @$pb.TagNumber(12)
  set dartSdkGitUrl($core.String v) {
    $_setString(11, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasDartSdkGitUrl() => $_has(11);
  @$pb.TagNumber(12)
  void clearDartSdkGitUrl() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get releasesJsonUrl => $_getSZ(12);
  @$pb.TagNumber(13)
  set releasesJsonUrl($core.String v) {
    $_setString(12, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasReleasesJsonUrl() => $_has(12);
  @$pb.TagNumber(13)
  void clearReleasesJsonUrl() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get flutterStorageBaseUrl => $_getSZ(13);
  @$pb.TagNumber(14)
  set flutterStorageBaseUrl($core.String v) {
    $_setString(13, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasFlutterStorageBaseUrl() => $_has(13);
  @$pb.TagNumber(14)
  void clearFlutterStorageBaseUrl() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get puroBuildsUrl => $_getSZ(14);
  @$pb.TagNumber(15)
  set puroBuildsUrl($core.String v) {
    $_setString(14, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasPuroBuildsUrl() => $_has(14);
  @$pb.TagNumber(15)
  void clearPuroBuildsUrl() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get puroBuildTarget => $_getSZ(15);
  @$pb.TagNumber(16)
  set puroBuildTarget($core.String v) {
    $_setString(15, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasPuroBuildTarget() => $_has(15);
  @$pb.TagNumber(16)
  void clearPuroBuildTarget() => $_clearField(16);

  @$pb.TagNumber(18)
  $core.bool get shouldInstall => $_getBF(16);
  @$pb.TagNumber(18)
  set shouldInstall($core.bool v) {
    $_setBool(16, v);
  }

  @$pb.TagNumber(18)
  $core.bool hasShouldInstall() => $_has(16);
  @$pb.TagNumber(18)
  void clearShouldInstall() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.bool get legacyPubCache => $_getBF(17);
  @$pb.TagNumber(19)
  set legacyPubCache($core.bool v) {
    $_setBool(17, v);
  }

  @$pb.TagNumber(19)
  $core.bool hasLegacyPubCache() => $_has(17);
  @$pb.TagNumber(19)
  void clearLegacyPubCache() => $_clearField(19);
}

class PuroEnvPrefsModel extends $pb.GeneratedMessage {
  factory PuroEnvPrefsModel({
    FlutterVersionModel? desiredVersion,
    $core.String? forkRemoteUrl,
    $core.String? engineForkRemoteUrl,
    $core.bool? precompileTool,
    $core.bool? patched,
  }) {
    final $result = create();
    if (desiredVersion != null) {
      $result.desiredVersion = desiredVersion;
    }
    if (forkRemoteUrl != null) {
      $result.forkRemoteUrl = forkRemoteUrl;
    }
    if (engineForkRemoteUrl != null) {
      $result.engineForkRemoteUrl = engineForkRemoteUrl;
    }
    if (precompileTool != null) {
      $result.precompileTool = precompileTool;
    }
    if (patched != null) {
      $result.patched = patched;
    }
    return $result;
  }
  PuroEnvPrefsModel._() : super();
  factory PuroEnvPrefsModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PuroEnvPrefsModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PuroEnvPrefsModel',
      createEmptyInstance: create)
    ..aOM<FlutterVersionModel>(1, _omitFieldNames ? '' : 'desiredVersion',
        protoName: 'desiredVersion', subBuilder: FlutterVersionModel.create)
    ..aOS(2, _omitFieldNames ? '' : 'forkRemoteUrl', protoName: 'forkRemoteUrl')
    ..aOS(3, _omitFieldNames ? '' : 'engineForkRemoteUrl',
        protoName: 'engineForkRemoteUrl')
    ..aOB(4, _omitFieldNames ? '' : 'precompileTool',
        protoName: 'precompileTool')
    ..aOB(5, _omitFieldNames ? '' : 'patched')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PuroEnvPrefsModel clone() => PuroEnvPrefsModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PuroEnvPrefsModel copyWith(void Function(PuroEnvPrefsModel) updates) =>
      super.copyWith((message) => updates(message as PuroEnvPrefsModel))
          as PuroEnvPrefsModel;

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
    $_setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasDesiredVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearDesiredVersion() => $_clearField(1);
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
  void clearForkRemoteUrl() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get engineForkRemoteUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set engineForkRemoteUrl($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasEngineForkRemoteUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearEngineForkRemoteUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get precompileTool => $_getBF(3);
  @$pb.TagNumber(4)
  set precompileTool($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPrecompileTool() => $_has(3);
  @$pb.TagNumber(4)
  void clearPrecompileTool() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get patched => $_getBF(4);
  @$pb.TagNumber(5)
  set patched($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPatched() => $_has(4);
  @$pb.TagNumber(5)
  void clearPatched() => $_clearField(5);
}

class PuroDotfileModel extends $pb.GeneratedMessage {
  factory PuroDotfileModel({
    $core.String? env,
    $core.String? previousDartSdk,
    $core.String? previousFlutterSdk,
  }) {
    final $result = create();
    if (env != null) {
      $result.env = env;
    }
    if (previousDartSdk != null) {
      $result.previousDartSdk = previousDartSdk;
    }
    if (previousFlutterSdk != null) {
      $result.previousFlutterSdk = previousFlutterSdk;
    }
    return $result;
  }
  PuroDotfileModel._() : super();
  factory PuroDotfileModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PuroDotfileModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PuroDotfileModel',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'env')
    ..aOS(2, _omitFieldNames ? '' : 'previousDartSdk',
        protoName: 'previousDartSdk')
    ..aOS(3, _omitFieldNames ? '' : 'previousFlutterSdk',
        protoName: 'previousFlutterSdk')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PuroDotfileModel clone() => PuroDotfileModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PuroDotfileModel copyWith(void Function(PuroDotfileModel) updates) =>
      super.copyWith((message) => updates(message as PuroDotfileModel))
          as PuroDotfileModel;

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
  void clearEnv() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get previousDartSdk => $_getSZ(1);
  @$pb.TagNumber(2)
  set previousDartSdk($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPreviousDartSdk() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreviousDartSdk() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get previousFlutterSdk => $_getSZ(2);
  @$pb.TagNumber(3)
  set previousFlutterSdk($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPreviousFlutterSdk() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreviousFlutterSdk() => $_clearField(3);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
