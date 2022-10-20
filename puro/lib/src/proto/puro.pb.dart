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

class EnvironmentSummaryModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EnvironmentSummaryModel',
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
    ..hasRequiredFields = false;

  EnvironmentSummaryModel._() : super();
  factory EnvironmentSummaryModel({
    $core.String? name,
    $core.String? path,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (path != null) {
      _result.path = path;
    }
    return _result;
  }
  factory EnvironmentSummaryModel.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory EnvironmentSummaryModel.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  EnvironmentSummaryModel clone() =>
      EnvironmentSummaryModel()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  EnvironmentSummaryModel copyWith(
          void Function(EnvironmentSummaryModel) updates) =>
      super.copyWith((message) => updates(message as EnvironmentSummaryModel))
          as EnvironmentSummaryModel; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static EnvironmentSummaryModel create() => EnvironmentSummaryModel._();
  EnvironmentSummaryModel createEmptyInstance() => create();
  static $pb.PbList<EnvironmentSummaryModel> createRepeated() =>
      $pb.PbList<EnvironmentSummaryModel>();
  @$core.pragma('dart2js:noInline')
  static EnvironmentSummaryModel getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnvironmentSummaryModel>(create);
  static EnvironmentSummaryModel? _defaultInstance;

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
}

class EnvironmentListModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'EnvironmentListModel',
      createEmptyInstance: create)
    ..pc<EnvironmentSummaryModel>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'environments',
        $pb.PbFieldType.PM,
        subBuilder: EnvironmentSummaryModel.create)
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'selectedEnvironment',
        protoName: 'selectedEnvironment')
    ..hasRequiredFields = false;

  EnvironmentListModel._() : super();
  factory EnvironmentListModel({
    $core.Iterable<EnvironmentSummaryModel>? environments,
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
  $core.List<EnvironmentSummaryModel> get environments => $_getList(0);

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
            : 'environment')
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'fromChannel',
        protoName: 'fromChannel')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'fromVersion',
        protoName: 'fromVersion')
    ..aOS(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'fromCommit',
        protoName: 'fromCommit')
    ..aOS(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'toChannel',
        protoName: 'toChannel')
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'toVersion',
        protoName: 'toVersion')
    ..aOS(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'toCommit',
        protoName: 'toCommit')
    ..hasRequiredFields = false;

  EnvironmentUpgradeModel._() : super();
  factory EnvironmentUpgradeModel({
    $core.String? environment,
    $core.String? fromChannel,
    $core.String? fromVersion,
    $core.String? fromCommit,
    $core.String? toChannel,
    $core.String? toVersion,
    $core.String? toCommit,
  }) {
    final _result = create();
    if (environment != null) {
      _result.environment = environment;
    }
    if (fromChannel != null) {
      _result.fromChannel = fromChannel;
    }
    if (fromVersion != null) {
      _result.fromVersion = fromVersion;
    }
    if (fromCommit != null) {
      _result.fromCommit = fromCommit;
    }
    if (toChannel != null) {
      _result.toChannel = toChannel;
    }
    if (toVersion != null) {
      _result.toVersion = toVersion;
    }
    if (toCommit != null) {
      _result.toCommit = toCommit;
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
  $core.String get environment => $_getSZ(0);
  @$pb.TagNumber(1)
  set environment($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEnvironment() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnvironment() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fromChannel => $_getSZ(1);
  @$pb.TagNumber(2)
  set fromChannel($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasFromChannel() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromChannel() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get fromVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set fromVersion($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasFromVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearFromVersion() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get fromCommit => $_getSZ(3);
  @$pb.TagNumber(4)
  set fromCommit($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasFromCommit() => $_has(3);
  @$pb.TagNumber(4)
  void clearFromCommit() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get toChannel => $_getSZ(4);
  @$pb.TagNumber(5)
  set toChannel($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasToChannel() => $_has(4);
  @$pb.TagNumber(5)
  void clearToChannel() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get toVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set toVersion($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasToVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearToVersion() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get toCommit => $_getSZ(6);
  @$pb.TagNumber(7)
  set toCommit($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasToCommit() => $_has(6);
  @$pb.TagNumber(7)
  void clearToCommit() => clearField(7);
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
    ..aOS(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'message')
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
    $core.String? message,
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
    if (message != null) {
      _result.message = message;
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
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => clearField(2);

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
