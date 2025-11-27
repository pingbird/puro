// This is a work in progress

import 'dart:convert';

import 'package:file/file.dart';
import 'package:petitparser/petitparser.dart';

import '../ast/binary.dart';
import '../ast/grammar.dart';
import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../env/create.dart';
import '../env/dart.dart';
import '../git.dart';
import '../process.dart';
import '../terminal.dart';

class GenerateASTParserCommand extends PuroCommand {
  @override
  String get name => '_generate-ast-parser';

  @override
  Future<CommandResult> run() async {
    final config = PuroConfig.of(scope);
    final git = GitClient.of(scope);
    final sharedRepository = config.sharedDartSdkDir;
    final workingDir = config.fileSystem.directory('temp_ast_gen');
    if (!sharedRepository.existsSync()) {
      await fetchOrCloneShared(
        scope: scope,
        repository: sharedRepository,
        remoteUrl: config.dartSdkGitUrl,
      );
    }
    final binaryMdResult = await git.raw([
      'log',
      '--format=%H',
      '8dbe716085d4942ce87bd34e933cfccf2d0f70ae..main',
      '--',
      'pkg/kernel/binary.md',
    ], directory: sharedRepository);
    final commits = (binaryMdResult.stdout as String)
        .trim()
        .split('\n')
        .reversed
        .toList();

    commits.add(
      await git.getCurrentCommitHash(
        repository: sharedRepository,
        branch: 'main',
      ),
    );

    final binaryMdDir = workingDir.childDirectory('binary-md');
    if (!binaryMdDir.existsSync()) {
      binaryMdDir.createSync(recursive: true);
      for (final line in (binaryMdResult.stdout as String).trim().split('\n')) {
        final versionContents = await git.cat(
          repository: sharedRepository,
          path: 'tools/VERSION',
          ref: line,
        );
        final major = RegExp(
          r'MAJOR (\d+)',
        ).firstMatch(utf8.decode(versionContents))![1]!;
        if (major == '1') continue;
        final contents = await git.cat(
          repository: sharedRepository,
          path: 'pkg/kernel/binary.md',
          ref: line,
        );
        final lines = <String>[];
        var inCodeBlock = false;
        for (final line in utf8.decode(contents).split('\n')) {
          if (line.startsWith('```')) {
            inCodeBlock = !inCodeBlock;
          } else if (inCodeBlock) {
            lines.add(line);
          }
        }
        binaryMdDir.childFile('$line.md').writeAsStringSync(lines.join('\n'));
      }
    }

    final binaryMdCommits = <String, String>{};
    for (final childFile in binaryMdDir.listSync()) {
      if (childFile is! File || !childFile.basename.endsWith('.md')) continue;
      final contents = childFile.readAsStringSync();
      final commit = childFile.basename.substring(
        0,
        childFile.basename.length - 3,
      );
      binaryMdCommits[commit] = contents;
    }

    commits.removeWhere((e) => !binaryMdCommits.containsKey(e));

    final verCommit = <int, String>{};
    final verSchema = <int, dynamic>{};

    final astsJsonDir = workingDir.childDirectory('asts-json');
    if (!astsJsonDir.existsSync()) {
      astsJsonDir.createSync(recursive: true);
    }

    for (final commit in commits) {
      // Uncomment enums
      var source = binaryMdCommits[commit]!;
      source = source.replaceAllMapped(
        RegExp('/\\*(\nenum[\\s\\S]+?)\\*/', multiLine: true),
        (match) => match.group(1)!,
      );

      source.replaceAll(
        'enum LogicalOperator { &&, || }',
        'enum LogicalOperator { logicalAnd, logicalOr }',
      );

      final result = BinaryMdGrammar().build().parse(source);
      if (result is Failure) {
        // print(result.message);
        return BasicMessageResult(
          'Failed to parse AST parser:\n$result',
          type: CompletionType.failure,
        );
      }

      final componentFile = (result.value as List).singleWhere((e) {
        return e['type'] != null && e['type'][1] == 'ComponentFile';
      });
      final version = int.parse(
        (componentFile['type'][3] as List).singleWhere(
              (e) => e['field'] != null && e['field'][1] == 'formatVersion',
            )['field'][2]
            as String,
      );

      verCommit[version] = commit;
      verSchema[version] = result.value;

      astsJsonDir
          .childFile('v$version.json')
          .writeAsStringSync(prettyJsonEncoder.convert(result.value));
    }

    commits.removeWhere((e) => !verCommit.values.contains(e));

    // print('first: ${commits.first}');
    // print('last: ${commits.last}');

    // Generate separate ASTs for every version (for debugging)
    final astsDir = workingDir.childDirectory('asts');
    if (astsDir.existsSync()) astsDir.deleteSync(recursive: true);
    astsDir.createSync(recursive: true);
    for (final entry in verSchema.entries) {
      final ast = generateAstForSchemas({
        entry.key: entry.value,
      }, comment: 'For schema ${verCommit[entry.key]}');
      astsDir.childFile('v${entry.key}.dart').writeAsStringSync(ast);
    }

    // Generate diffs (for debugging)
    final diffsDir = workingDir.childDirectory('diffs');
    if (diffsDir.existsSync()) diffsDir.deleteSync(recursive: true);
    diffsDir.createSync(recursive: true);
    for (final entry in verSchema.entries.skip(1)) {
      final diff = await runProcess(scope, 'diff', [
        '--context',
        '-F',
        '^class',
        '--label',
        'v${entry.key}',
        '--label',
        'v${entry.key - 1}',
        astsDir.childFile('v${entry.key - 1}.dart').path,
        astsDir.childFile('v${entry.key}.dart').path,
      ], debugLogging: false);
      if (diff.exitCode > 1) {
        return BasicMessageResult(
          'Failed to generate diff:\n${diff.stderr}',
          type: CompletionType.failure,
        );
      }
      diffsDir
          .childFile('v${entry.key}.diff')
          .writeAsStringSync(diff.stdout as String);
    }

    // Download Dart
    final releases = await getDartReleases(scope: scope);

    final allReleases = releases.releases.entries
        .expand(
          (r) => r.value.map(
            (v) => DartRelease(DartOS.current, DartArch.current, r.key, v),
          ),
        )
        .toList();

    // allReleases.removeWhere((e) => e.version.major < 2);

    // This release has no artifacts for some reason
    allReleases.removeWhere(
      (e) => '${e.version}' == '1.24.0' && e.channel == DartChannel.dev,
    );

    // print('releases: ${allReleases.length}');
    // print('releases: ${allReleases.map((e) => e.name).join(',')}');

    for (final release in allReleases) {
      // final i = allReleases.indexOf(release);
      // print('progress: ${(100 * i / allReleases.length).toStringAsFixed(2)}%');
      await downloadSharedDartRelease(
        scope: scope,
        release: release,
        check: false,
      );
    }

    // Generate binary formats for each version
    final formats = <int, BinFormat>{};
    for (final entry in verSchema.entries) {
      formats[entry.key] = BinFormat.fromSchema(entry.value);
    }

    // String toHex(List<int> bytes) =>
    //     bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');

    // Read snapshots
    for (final release in allReleases) {
      if (release.version.major < 2) continue;
      final snapshotFile = config
          .getDartRelease(release)
          .binDir
          .childDirectory('snapshots')
          .childFile('kernel-service.dart.snapshot');
      if (!snapshotFile.existsSync()) {
        // print('no snapshot: ${release.name}');
        continue;
      }
      final bytes = snapshotFile.readAsBytesSync();
      if (bytes.buffer.asByteData().getUint32(0) != 0x90ABCDEF) {
        // print('invalid header: ${release.name}');
        continue;
      }
      // print('release: ${release.name}');
      // print('header: ${toHex(bytes.sublist(0, 32))}');
      final reader = BinReader(formats, bytes);
      reader.read();
    }

    // final versionSizes = <Version, int>{};
    // final versionDates = <Version, String>{};
    //
    // for (final release in allReleases) {
    //   final i = allReleases.indexOf(release);
    //   print('progress: ${(100 * i / allReleases.length).toStringAsFixed(2)}%');
    //   // if (release.version < Version.parse('2.1.0')) continue;
    //   final sdk = config.getDartRelease(release);
    //   var size = 0;
    //   void visit(FileSystemEntity file) {
    //     if (file is File) {
    //       size += file.lengthSync();
    //     } else if (file is Directory) {
    //       file.listSync().forEach(visit);
    //     }
    //   }
    //
    //   visit(sdk.sdkDir);
    //
    //   // for (final file in sdk.binDir.childDirectory('snapshots').listSync()) {
    //   //   if (file is File) {
    //   //     size += file.lengthSync();
    //   //   }
    //   // }
    //   // final file = sdk.binDir
    //   //     .childDirectory('snapshots')
    //   //     .childFile('kernel-service.dart.snapshot');
    //   // final file = sdk.binDir.childFile('dart.exe');
    //   // if (!file.existsSync()) continue;
    //   // size += file.lengthSync();
    //   if (versionSizes.containsKey(release.version)) {
    //     assert(versionSizes[release.version] == size);
    //   }
    //   versionSizes[release.version] = size;
    //   final date =
    //       jsonDecode(sdk.versionJsonFile.readAsStringSync())['date'] as String;
    //   versionDates[release.version] = date;
    // }
    //
    // final allVersions = versionSizes.keys.toSet().toList()..sort();
    //
    // final sizesCsv = StringBuffer();
    // sizesCsv.writeln('version,size');
    // var lastVersion = allVersions.first;
    // for (final version in allVersions) {
    //   sizesCsv.writeln(
    //       '${versionDates[version]},$version,${versionSizes[version]}');
    //   // if (version.isPreRelease || version.patch != 0) {
    //   //   sizesCsv.writeln('$lastVersion,${versionSizes[version]}');
    //   // } else {
    //   //   sizesCsv.writeln('$version,${versionSizes[version]}');
    //   //   lastVersion = version;
    //   // }
    // }
    // workingDir.childFile('sizes.csv').writeAsStringSync('$sizesCsv');

    return BasicMessageResult('Generated AST parser');
  }
}

String generateAstForSchemas(Map<int, dynamic> schemas, {String? comment}) {
  String fixName(String name, {bool lower = false}) {
    var out =
        const {
          'VariableDeclarationPlain': 'VariableDeclaration',
          'class': 'clazz',
          '8bitAlignment': 'byteAlignment',
          'Deprecated_ConstantExpression': 'ConstantExpression',
          'IsLoweredLateField': 'isLoweredLateField',
        }[name] ??
        name;
    if (lower) {
      out = out[0].toLowerCase() + out.substring(1);
    }
    return out;
  }

  final types = <String, DartType>{
    'Byte': RawType('int'),
    'UInt': RawType('int'),
    'UInt7': RawType('int'),
    'UInt14': RawType('int'),
    'UInt30': RawType('int'),
    'UInt32': RawType('int'),
    'Double': RawType('double'),
    'StringReference': RawType('String'),
    'ConstantReference': RawType('Constant'),
    'CanonicalNameReference': RawType('CanonicalName?'),
    'UriReference': RawType('Uri'),
    'FileOffset': RawType('int'),
    'String': RawType('String'),
  };

  DartType getType(dynamic data) {
    if (data is String) {
      return types[fixName(data)] ??
          (throw AssertionError('Unknown type $data'));
    } else if (data['list'] != null) {
      return ListType()..element = getType(data['list']);
    } else if (data['rlist'] != null) {
      return ListType()..element = getType(data['rlist']);
    } else if (data['option'] != null) {
      return OptionType()..element = getType(data['option']);
    } else if (data['ifPrivate'] != null) {
      return OptionType()..element = getType(data['ifPrivate']);
    } else if (data['pair'] != null) {
      return PairType()
        ..first = getType(data['pair'][0])
        ..second = getType(data['pair'][1]);
    } else if (data['union'] != null) {
      return UnionType()
        ..first = getType(data['union'][0])
        ..second = getType(data['union'][1]);
    } else if (data['array'] != null) {
      return ListType()..element = getType(data['array'][0]);
    } else {
      throw AssertionError('Unknown type $data');
    }
  }

  DartType resolveMerge(DartType from, DartType to) {
    final result = const {
      ('Expression', 'IntegerLiteral'): 'IntegerLiteral',
      (
        'PositiveIntLiteral | NegativeIntLiteral | SpecializedIntLiteral | BigIntLiteral',
        'IntegerLiteral',
      ): 'IntegerLiteral',
    }[(from.name, to.name)];
    if (result != null) {
      return getType(result);
    } else {
      throw AssertionError('Mismatch ${from.name} != ${to.name}');
    }
  }

  const skipTypes = {'StringTable', 'FileOffset'};

  for (final entry in schemas.entries) {
    // print('Processing ${entry.key} (${verCommit[entry.key]})');
    for (final decl in entry.value as List) {
      if (decl['type'] != null) {
        final isAbstract = decl['type'][0] as bool;
        final name = fixName(decl['type'][1] as String);
        if (skipTypes.contains(name)) continue;
        final existing = types[name];
        if (existing is RawType) continue;
        if (existing == null) {
          types[name] = ClassType()
            ..name = name
            ..abstract = isAbstract;
        } else {
          final type = existing as ClassType;
          if (type.abstract != isAbstract) {
            throw AssertionError(
              'Abstract mismatch for $name: ${type.abstract} != $isAbstract',
            );
          }
        }
      } else if (decl['enum'] != null) {
        final type = EnumType();
        type.name = fixName(decl['enum'][0] as String);
        for (final value in decl['enum'][1] as List) {
          type.values.add(fixName(value[0] as String, lower: true));
        }
        types[type.name] = type;
      } else {
        throw AssertionError('Unknown declaration $decl');
      }
    }
  }

  // Second pass, fill in fields
  for (final entry in schemas.entries) {
    // print('Processing ${entry.key} (${verCommit[entry.key]})');
    for (final decl in entry.value as List) {
      if (decl['type'] != null) {
        final name = fixName(decl['type'][1] as String);
        if (types[name] is RawType || skipTypes.contains(name)) continue;
        var parent = decl['type'][2] as String?;
        if (parent == 'TreeNode') {
          parent = null; // Not actually defined
        }
        final fields = decl['type'][3] as List;
        final dartFields = <String, DartType>{};
        for (final field in fields) {
          if (field['field'] != null) {
            final hasDefault = field['field'][2] != null;
            final fieldName = fixName(field['field'][1] as String);
            if (hasDefault ||
                fieldName == 'tag' ||
                fieldName == '_unused_' ||
                fieldName == '8bitAlignment' ||
                (name == 'ComponentFile' &&
                    (fieldName == 'constants' || fieldName == 'strings'))) {
              continue;
            }
            final type = getType(field['field'][0]);
            dartFields[fieldName] = type;
          } else if (field['bitfield'] != null) {
            final names = field['bitfield'][2] as List;
            for (final name in names) {
              if (name == '_unused_') continue;
              dartFields[fixName(name as String)] = RawType('bool');
            }
          } else {
            throw AssertionError('Unknown field $field');
          }
        }
        final existing = types[name] as ClassType;
        if (parent != null) {
          final parentType = getType(parent) as ClassType;
          final existingParentName = existing.parent?.name;
          final parentName = parentType.name;

          if (existingParentName != null && existingParentName != parentName) {
            existing.parent =
                resolveMerge(existing.parent!, parentType) as ClassType;
          } else {
            existing.parent = parentType;
          }
        }
        for (final entry in dartFields.entries) {
          final existingField = existing.fields[entry.key];
          if (existingField == null) {
            existing.fields[entry.key] = entry.value;
          } else {
            existing.fields[entry.key] = existingField.merge(entry.value);
          }
        }
      }
    }
  }

  final outAst = StringBuffer();

  if (comment != null) {
    outAst.writeln(comment.split('\n').map((e) => '// $e').join('\n') + '\n');
  }

  for (final tpe in types.values) {
    if (tpe is ClassType) {
      if (tpe.abstract) {
        outAst.write('abstract ');
      }
      outAst.write('class ${tpe.name}');
      if (tpe.parent != null) {
        outAst.write(' extends ${tpe.parent!.name}');
      }
      outAst.writeln(' {');
      if (!tpe.abstract && tpe.fields.isNotEmpty) {
        outAst.writeln('  ${tpe.name}({');
        for (final field in tpe.fields.entries) {
          outAst.write('    ');
          if (field.value is OptionType) {
            outAst.writeln('this.${field.key},');
          } else {
            outAst.writeln('required this.${field.key},');
          }
        }
        outAst.writeln('  });');
      }
      for (final field in tpe.fields.entries) {
        outAst.writeln('  final ${field.value.name} ${field.key};');
      }
      outAst.writeln('}');
    } else if (tpe is EnumType) {
      outAst.writeln('enum ${tpe.name} {');
      for (final value in tpe.values) {
        outAst.writeln('  $value,');
      }
      outAst.writeln('}');
    }
  }

  return '$outAst';
}

abstract class DartType {
  String get name;
  DartType merge(DartType other);
}

class RawType extends DartType {
  RawType(this.name);
  @override
  final String name;
  @override
  DartType merge(DartType other) {
    if (other is RawType && name == other.name) {
      return this;
    } else {
      throw AssertionError('Type mismatch: $name != ${other.name}');
    }
  }
}

class ClassType extends DartType {
  ClassType? parent;
  @override
  late String name;
  final fields = <String, DartType>{};
  late bool abstract;
  @override
  DartType merge(DartType other) {
    if ((name == 'StringReference' && other.name == 'Name') ||
        (name == 'ExtensionType' && other.name == 'DartType')) {
      return other;
    }
    if (other is ClassType && name == other.name) {
      return this;
    } else {
      throw AssertionError('Type mismatch: $name != ${other.name}');
    }
  }
}

class PairType extends DartType {
  late DartType first;
  late DartType second;
  @override
  String get name => '(${first.name}, ${second.name})';
  @override
  DartType merge(DartType other) {
    if (other is PairType) {
      return PairType()
        ..first = first.merge(other.first)
        ..second = second.merge(other.second);
    } else {
      throw AssertionError('Type mismatch: $name != ${other.name}');
    }
  }
}

class ListType extends DartType {
  late DartType element;
  @override
  String get name => 'List<${element.name}>';
  @override
  DartType merge(DartType other) {
    if (other is ListType) {
      return ListType()..element = element.merge(other.element);
    } else {
      throw AssertionError('Type mismatch: $name != ${other.name}');
    }
  }
}

class OptionType extends DartType {
  late DartType element;
  @override
  String get name => '${element.name}?';
  @override
  DartType merge(DartType other) {
    if (other.name == element.name) {
      return this;
    } else if (other is OptionType) {
      return OptionType()..element = element.merge(other.element);
    } else {
      throw AssertionError('Type mismatch: $name != ${other.name}');
    }
  }
}

class UnionType extends DartType {
  late DartType first;
  late DartType second;
  @override
  String get name {
    final firstName = first is UnionType
        ? first.name
        : (first is ClassType
              ? (first as ClassType).parent!.name
              : throw AssertionError());
    final secondName = second is UnionType
        ? second.name
        : (second is ClassType
              ? (second as ClassType).parent!.name
              : throw AssertionError());
    assert(firstName == secondName);
    return firstName;
  }

  @override
  DartType merge(DartType other) {
    if (name ==
            'PositiveIntLiteral | NegativeIntLiteral | SpecializedIntLiteral | BigIntLiteral' &&
        other.name == 'IntegerLiteral') {
      return other;
    }
    if (other is UnionType) {
      return UnionType()
        ..first = first.merge(other.first)
        ..second = second.merge(other.second);
    } else {
      throw AssertionError('Type mismatch: $name != ${other.name}');
    }
  }
}

class EnumType extends DartType {
  @override
  late String name;
  final values = <String>{};
  @override
  DartType merge(DartType other) {
    if (other is EnumType && name == other.name) {
      return this;
    } else {
      throw AssertionError('Type mismatch: $name != ${other.name}');
    }
  }
}
