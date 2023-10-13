import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:petitparser/petitparser.dart';

import '../command.dart';
import '../command_result.dart';
import '../config.dart';
import '../env/create.dart';
import '../git.dart';
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
    final binaryMdResult = await git.raw(
      [
        'log',
        '--format=%H',
        '8dbe716085d4942ce87bd34e933cfccf2d0f70ae..main',
        '--',
        'pkg/kernel/binary.md'
      ],
      directory: sharedRepository,
    );
    final commits =
        (binaryMdResult.stdout as String).trim().split('\n').reversed.toList();

    commits.add(await git.getCurrentCommitHash(
      repository: sharedRepository,
      branch: 'main',
    ));

    final binaryMdDir = workingDir.childDirectory('binary-md');
    if (!binaryMdDir.existsSync()) {
      binaryMdDir.createSync(recursive: true);
      for (final line in (binaryMdResult.stdout as String).trim().split('\n')) {
        final versionContents = await git.cat(
          repository: sharedRepository,
          path: 'tools/VERSION',
          ref: line,
        );
        final major = RegExp(r'MAJOR (\d+)')
            .firstMatch(utf8.decode(versionContents))![1]!;
        if (major == '2') break;
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
      final commit =
          childFile.basename.substring(0, childFile.basename.length - 3);
      binaryMdCommits[commit] = contents;
    }

    commits.removeWhere((e) => !binaryMdCommits.containsKey(e));

    final verCommit = <int, String>{};
    final verSchema = <int, dynamic>{};

    for (final commit in commits) {
      final result = BinaryMdGrammar().build().parse(binaryMdCommits[commit]!);
      if (result is Failure) {
        print(result.message);
        return BasicMessageResult(
          'Failed to parse AST parser:\n$result',
          type: CompletionType.failure,
        );
      }

      final componentFile = (result.value as List).singleWhere((e) {
        return e['type'] != null && e['type'][1] == 'ComponentFile';
      });
      final version = int.parse((componentFile['type'][3] as List).singleWhere(
              (e) => e['field'] != null && e['field'][1] == 'formatVersion')[
          'field'][2] as String);

      verCommit[version] = commit;
      verSchema[version] = result.value;
    }

    commits.removeWhere((e) => !verCommit.values.contains(e));

    String fixName(String name, {bool lower = false}) {
      var out = const {
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
          'IntegerLiteral'
        ): 'IntegerLiteral',
      }[(from.name, to.name)];
      if (result != null) {
        return getType(result);
      } else {
        throw AssertionError(
          'Mismatch for $name: ${from.name} != ${to.name}',
        );
      }
    }

    const skipTypes = {
      'StringTable',
      'FileOffset',
    };

    for (final entry in verSchema.entries) {
      print('Processing ${entry.key} (${verCommit[entry.key]})');
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
    for (final entry in verSchema.entries) {
      print('Processing ${entry.key} (${verCommit[entry.key]})');
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

            if (existingParentName != null &&
                existingParentName != parentName) {
              existing.parent = resolveMerge(
                existing.parent!,
                parentType,
              ) as ClassType;
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

    workingDir.childFile('ast.dart').writeAsStringSync('$outAst');

    return BasicMessageResult('Generated AST parser');
  }
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
  String get name => '${first.name} | ${second.name}';
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

class BinaryMdGrammar extends GrammarDefinition<dynamic> {
  @override
  Parser start() => ref0(topLevelDecls).end();

  Parser topLevelDecls() =>
      ref0(topLevelDecl).star().map((e) => e.whereNotNull().toList());

  final ignoreDecls = {
    ['Byte flags (flag1, flag2, ..., flagN)'],
    ['Byte byte (10xxxxxx)'],
    ['type Byte = a byte'],
    ['abstract type UInt {}'],
    [
      'type UInt7 extends UInt {',
      '  Byte byte1(0xxxxxxx);',
      '}',
    ],
    [
      'type UInt14 extends UInt {',
      '  Byte byte1(10xxxxxx);',
      '  Byte byte2(xxxxxxxx);',
      '}',
    ],
    [
      'type UInt30 extends UInt {',
      '  Byte byte1(11xxxxxx);',
      '  Byte byte2(xxxxxxxx);',
      '  Byte byte3(xxxxxxxx);',
      '  Byte byte4(xxxxxxxx);',
      '}',
    ],
    [
      'type List<T> {',
      '  UInt length;',
      '  T[length] items;',
      '}',
    ],
    [
      'type RList<T> {',
      '  T[length] elements;',
      '  Uint32 length;', // lol
      '}',
    ],
    [
      'type RList<T> {',
      '  T[length] elements;',
      '  UInt32 length;',
      '}',
    ],
    [
      'type Pair<T0, T1> {',
      '  T0 first;',
      '  T1 second;',
      '}',
    ],
    [
      'type Option<T> {',
      '  Byte tag;',
      '}',
    ],
    [
      'type Nothing extends Option<T> {',
      '  Byte tag = 0;',
      '}',
    ],
    [
      'type Something<T> extends Option<T> {',
      '  Byte tag = 1;',
      '  T value;',
      '}',
    ],
    ['type UInt32 = big endian 32-bit unsigned integer'],
    ['type Double = Double-precision floating-point number.'],
  };

  Parser topLevelDecl() => [
        for (final ignoreDecl in ignoreDecls)
          [for (final line in ignoreDecl) string(line.trim()).trim(space())]
              .toSequenceParser()
              .map((e) => null),
        ref0(typeDecl),
        ref0(enumDecl),
        failure('Expected top-level declaration'),
      ].map((e) => e.trim(space())).toChoiceParser();

  Parser typeDecl() => (string('abstract ').optional() &
          string('type') &
          ref0(identifier).trim(space()) &
          (string('extends') & ref0(identifier).trim(space()))
              .pick(1)
              .optional() &
          string('{') &
          ref0(fieldDecl).star() &
          string('}'))
      .map((e) => {
            'type': [e[0] != null, e[2], e[3], e[5]]
          });

  Parser enumDecl() => (string('enum') &
          ref0(identifier) &
          string('{') &
          (ref0(identifier) &
                  string('=').trim(space()) &
                  digit().star().flatten().trim(space()) &
                  string(',').trim(space()).optional())
              .map((e) => [e[0], e[2]])
              .star() &
          string('}'))
      .map((e) => {
            'enum': [e[1], e[3]]
          });

  Parser tpeInner() => [
        string('Uint').map((e) => 'UInt'), // lol
        (string('List<') & ref0(tpe) & string('>'))
            .pick(1)
            .map((e) => {'list': e}),
        (string('RList<') & ref0(tpe) & string('>'))
            .pick(1)
            .map((e) => {'rlist': e}),
        (string('Option<') & ref0(tpe) & string('>'))
            .pick(1)
            .map((e) => {'option': e}),
        (string('Pair<') &
                ref0(tpe) &
                string(',').trim(space()) &
                ref0(tpe) &
                string('>'))
            .map((e) => {
                  'pair': [e[1], e[3]]
                }),
        (string('[') & ref0(tpe) & string(',') & ref0(tpe) & string(']'))
            .map((e) => {
                  'pair': [e[1], e[3]]
                }),
        identifier(),
      ].toChoiceParser().trim(space());

  Parser tpeArr() => (ref0(tpeInner) &
          (string('[') & any().starLazy(string(']')).flatten() & string(']'))
              .optional())
      .map((e) => e[1] != null
          ? {
              'array': [e[0], e[1][1]]
            }
          : e[0])
      .trim(space());

  Parser tpe() =>
      (ref0(tpeArr) & (string('|') & ref0(tpe)).pick(1).optional()).map(
        (e) => e[1] != null
            ? {
                'union': [e[0], e[1]]
              }
            : e[0],
      );

  Parser fieldDecl() => [
        (ref0(tpe) &
                (ref0(space).optional() & ref0(identifier)).pick(1) &
                ((string('=') & space() & any().plusLazy(string(';')).flatten())
                            .pick(2)
                            .optional() &
                        string(';'))
                    .pick(0))
            .map((e) => {
                  'field': [e[0], e[1], e[2]]
                }),
        (string('if name begins with \'_\' {') & ref0(fieldDecl) & string('}'))
            .pick(1)
            .map((e) => {
                  'field': [
                    {'ifPrivate': e['field'][0]},
                    e['field'][1],
                    e['field'][2],
                  ]
                }),
        (ref0(tpe) &
                ref0(identifier) &
                pattern('{(') &
                (ref0(identifier) & string(',').trim(ref0(space)).optional())
                    .pick(0)
                    .star() &
                pattern('})') &
                string(';'))
            .map((e) => {
                  'bitfield': [
                    e[0],
                    e[1],
                    e[3],
                  ]
                }),
      ].toChoiceParser(failureJoiner: selectFarthest).trim(ref0(space));

  Parser<String> lineComment() {
    return (string('//') & Token.newlineParser().neg().star()).flatten();
  }

  Parser<String> inlineComment() {
    return (string('/*') & any().starLazy(string('*/')) & string('*/'))
        .flatten();
  }

  Parser<String> space() {
    return (whitespace() | lineComment() | inlineComment()).plus().flatten();
  }

  Parser<String> notSpace() => any().plusLazy(space()).flatten();

  Parser<String> identifier() =>
      (letter() | digit() | string('_')).plus().flatten().trim(space());
}
