import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import '../config.dart';
import '../env/engine.dart';
import '../logger.dart';
import '../provider.dart';
import 'packages.dart';
import 'parse.dart';

const _coreLibraryNames = {
  'async',
  'collection',
  'convert',
  'math',
  'typed_data',
  'ffi',
  'io',
  'isolate',
  'mirrors',
};

@immutable
class EvalCode {
  const EvalCode(
    this.contents, {
    this.hasReturn = false,
  });

  final String contents;
  final bool hasReturn;

  @override
  bool operator ==(Object other) =>
      other is EvalCode &&
      contents == other.contents &&
      hasReturn == other.hasReturn;

  @override
  int get hashCode => Object.hash(contents, hasReturn);
}

final _identifierRegex = RegExp(r'[a-zA-Z_$][a-zA-Z_$0-9]*');
final _identifierOrUriRegex = RegExp(r'[a-zA-Z_$:/\\.][a-zA-Z_$0-9:/\\.]*');

@immutable
class EvalImport {
  const EvalImport(
    this.uri, {
    this.as,
    this.show = const {},
    this.hide = const {},
  });

  final Uri uri;
  final String? as;
  final Set<String> show;
  final Set<String> hide;

  factory EvalImport.parse(String import) {
    final uriMatch = _identifierOrUriRegex.matchAsPrefix(import);
    if (uriMatch == null) {
      throw ArgumentError.value(import, 'import', 'name or uri expected');
    }

    var e = uriMatch.group(0)!;
    if (!e.contains(':')) e = 'package:$e';
    var uri = Uri.parse(e);
    if (uri.scheme == 'package') {
      if (uri.pathSegments.length == 1) {
        uri = Uri.parse('$e/${uri.pathSegments.first}.dart');
      } else if (!uri.pathSegments.last.contains('.')) {
        uri = Uri.parse('$e.dart');
      }
    }

    String? as;
    final show = <String>{};
    final hide = <String>{};
    import = import.substring(uriMatch.end);
    String? lastModifier;
    while (import.isNotEmpty) {
      var modifier = import.substring(0, 1);
      if (modifier == ',') {
        if (lastModifier == null) break;
        modifier = lastModifier;
      }
      if (modifier == '=') {
        final identifierMatch = _identifierRegex.matchAsPrefix(import, 1);
        as = identifierMatch?.group(0) ?? uri.pathSegments.first;
        import = import.substring(identifierMatch?.end ?? 1);
      } else if (modifier == '+') {
        final identifierMatch = _identifierRegex.matchAsPrefix(import, 1);
        if (identifierMatch == null) {
          throw ArgumentError.value(
            import,
            'import',
            'name expected after `+`',
          );
        }
        show.add(identifierMatch.group(0)!);
        import = import.substring(identifierMatch.end);
      } else if (modifier == '-') {
        final identifierMatch = _identifierRegex.matchAsPrefix(import, 1);
        if (identifierMatch == null) {
          throw ArgumentError.value(
            import,
            'import',
            'name expected after `-`',
          );
        }
        hide.add(identifierMatch.group(0)!);
        import = import.substring(identifierMatch.end);
      } else {
        break;
      }
      lastModifier = modifier;
    }

    if (import.isNotEmpty) {
      throw ArgumentError.value(
        import,
        'import',
        'unexpected character `${import.substring(0, 1)}`',
      );
    }

    return EvalImport(uri, as: as, show: show, hide: hide);
  }

  @override
  String toString() {
    return "import ${[
      "'$uri'",
      if (as != null) 'as $as',
      if (show.isNotEmpty) 'show ${show.join(', ')}',
      if (hide.isNotEmpty) 'hide ${hide.join(', ')}',
    ].join(' ')};";
  }

  @override
  bool operator ==(Object other) {
    return other is EvalImport &&
        other.uri == uri &&
        other.as == as &&
        other.show.length == show.length &&
        other.show.containsAll(show) &&
        other.hide.length == hide.length &&
        other.hide.containsAll(hide);
  }

  @override
  int get hashCode => Object.hash(
        uri,
        as,
        Object.hashAllUnordered(show),
        Object.hashAllUnordered(hide),
      );
}

MapEntry<String, VersionConstraint?> parseEvalPackage(String package) {
  final packageNameMatch = _identifierRegex.matchAsPrefix(package);
  if (packageNameMatch == null) {
    throw ArgumentError.value(package, 'package', 'package name expected');
  }

  final packageName = packageNameMatch.group(0)!;
  package = package.substring(packageNameMatch.end);

  if (package.isEmpty) {
    return MapEntry(packageName, null);
  } else if (package.startsWith('=')) {
    package = package.substring(1);
  }

  if (package.isEmpty || package == 'none') {
    return MapEntry(packageName, VersionConstraint.empty);
  } else {
    return MapEntry(packageName, VersionConstraint.parse(package));
  }
}

class EvalError implements Exception {
  EvalError({required this.message});

  final String message;

  @override
  String toString() => 'Eval error:\n$message';
}

class EvalContext {
  EvalContext({
    required this.scope,
    required this.environment,
  });

  final Scope scope;
  final EnvConfig environment;

  late final log = PuroLogger.of(scope);

  final imports = <EvalImport>{};
  var needsPackageReload = false;

  late final _sdkVersion = getDartSDKVersion(
    scope: scope,
    dartSdk: environment.flutter.cache.dartSdk,
  );

  Future<void> pullPackages({
    Map<String, VersionConstraint?> packages = const {},
    bool reset = false,
  }) async {
    if (packages.isEmpty) return;
    log.d(() => 'pullPackages: $packages');

    // This takes about 1 second on the first run with a good internet
    // connection, subsequent runs won't update packages unless necessary.
    final didUpdate = await updateBootstrapPackages(
      scope: scope,
      environment: environment,
      sdkVersion: '${await _sdkVersion}',
      packages: packages,
      reset: reset,
    );

    if (didUpdate) {
      needsPackageReload = true;
    }
  }

  SimpleParseResult<AstNode> parse(String code) {
    final unitParseResult = parseDartCompilationUnit(code);
    final unitNode = unitParseResult.node;

    log.d('unitNode: ${unitNode.runtimeType}');
    log.d(() => 'unitNode.directives: ${unitNode?.directives}');
    log.d(() => 'unitNode.declarations: '
        '${unitNode?.declarations.map((e) => e.runtimeType).join(', ')}');

    // Always use unit if it contains top-level declarations, contains imports,
    // or contains a main function.
    if (unitNode != null &&
        (unitNode.directives.isNotEmpty ||
            unitNode.declarations.any((e) =>
                e is ClassDeclaration ||
                e is MixinDeclaration ||
                e is ExtensionDeclaration ||
                e is EnumDeclaration ||
                e is TypeAlias ||
                (e is FunctionDeclaration && e.name.lexeme == 'main')))) {
      return unitParseResult;
    }

    final expressionParseResult = parseDartExpression(code, async: true);

    final expressionNode = expressionParseResult.node;
    log.d('expressionNode: ${expressionNode.runtimeType}');
    log.d('expressionParseResult.parseErrors: '
        '${expressionParseResult.parseErrors}');
    log.d('expressionParseResult.scanErrors: '
        '${expressionParseResult.scanErrors}');
    log.d('expressionParseResult.parseException: '
        '${expressionParseResult.parseException}');
    log.d('expressionParseResult.scanException: '
        '${expressionParseResult.scanException}');
    log.d('expressionParseResult.exhaustive: '
        '${expressionParseResult.exhaustive}');

    if (!expressionParseResult.hasError && expressionParseResult.exhaustive) {
      return expressionParseResult;
    }

    return parseDartBlock('{$code}');
  }

  void importCore() {
    imports.addAll(
      _coreLibraryNames.map((e) => EvalImport(Uri.parse('dart:$e'))),
    );
  }

  EvalCode transformCode(String code) {
    final importStr = imports.map((e) => '$e\n').join();
    final parseResult = parse(code);
    final node = parseResult.node;
    if (node is Expression) {
      return EvalCode(
        '${importStr}Future<dynamic> main() async =>\n$code\n;',
        hasReturn: true,
      );
    } else if (node is CompilationUnit) {
      var hasReturn = true;
      for (final decl in node.declarations) {
        if (decl is FunctionDeclaration && decl.name.lexeme == 'main') {
          final returnType = decl.returnType?.toSource();
          log.d('main return type: $returnType');
          if (returnType == 'void' || returnType == 'Future<void>') {
            hasReturn = false;
          }
        }
      }
      return EvalCode('$importStr$code', hasReturn: hasReturn);
    } else {
      if (node != null && ReturnCheckVisitor.check(node)) {
        return EvalCode(
          '${importStr}Future<dynamic> main() async {\n$code\n}',
          hasReturn: true,
        );
      } else {
        return EvalCode('${importStr}Future<void> main() async {\n$code\n}');
      }
    }
  }
}

class ReturnCheckVisitor extends GeneralizingAstVisitor<void> {
  var hasReturn = false;

  @override
  void visitExpression(Expression node) {}

  @override
  void visitFunctionBody(FunctionBody node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    hasReturn = true;
    return;
  }

  static bool check(AstNode node) {
    final visitor = ReturnCheckVisitor();
    node.accept(visitor);
    return visitor.hasReturn;
  }
}
