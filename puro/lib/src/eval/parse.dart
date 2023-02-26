// The analyzer package is silly and hides important files
// ignore_for_file: implementation_imports

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';

class ParseResult<T extends AstNode> {
  ParseResult({
    required this.code,
    this.node,
    this.token,
    this.scanErrors = const [],
    this.scanException,
    this.parseErrors = const [],
    this.parseException,
    this.exhaustive = false,
  });

  final String code;
  final T? node;
  final Token? token;
  final CaughtException? scanException;
  final CaughtException? parseException;
  final List<AnalysisError> scanErrors;
  final List<AnalysisError> parseErrors;
  final bool exhaustive;

  late final hasReturn = () {
    if (node is! CompilationUnit) return false;
    for (final decl in (node as CompilationUnit).declarations) {
      if (decl is FunctionDeclaration && decl.name.lexeme == 'main') {
        final returnType = decl.returnType?.toSource();
        if (returnType == 'void' || returnType == 'Future<void>') {
          return false;
        }
      }
    }
    return true;
  }();

  bool get hasError =>
      scanException != null ||
      parseException != null ||
      scanErrors.isNotEmpty ||
      parseErrors.isNotEmpty;

  @override
  String toString() {
    return 'SimpleParseResult<$T>('
        '  node: $node, '
        '  token: $token, '
        '  scanException: $scanException, '
        '  parseException: $parseException, '
        '  scanErrors: $scanErrors, '
        '  parseErrors: $parseErrors, '
        '  hasError: $hasError, '
        '  exhaustive: $exhaustive'
        ')';
  }
}

extension TokenExtension on Token {
  Token get last {
    if (next == this || next == null) return this;
    return next!.last;
  }
}

ParseResult<T> parseDart<T extends AstNode>(
  String code,
  T Function(Parser parser) fn,
) {
  final source = StringSource(code, '/eval.dart');
  final scanErrors = _ErrorListener();
  final reader = CharSequenceReader(code);
  final featureSet = FeatureSet.latestLanguageVersion();
  final scanner = Scanner(
    source,
    reader,
    scanErrors,
  )..configureFeatures(
      featureSetForOverriding: featureSet,
      featureSet: featureSet,
    );
  final Token token;
  try {
    token = scanner.tokenize();
  } catch (exception, stackTrace) {
    return ParseResult(
      code: code,
      scanException: CaughtException(exception, stackTrace),
    );
  }
  final parseErrors = _ErrorListener();
  late final parser = Parser(
    source,
    parseErrors,
    featureSet: featureSet,
    lineInfo: LineInfo.fromContent(code),
  )..currentToken = token;
  final node = fn(parser);
  return ParseResult(
    code: code,
    node: node,
    token: token,
    scanErrors: scanErrors.errors,
    parseErrors: parseErrors.errors,
    exhaustive: parser.currentToken.isEof,
  );
}

ParseResult<Expression> parseDartExpression(
  String code, {
  bool async = false,
}) =>
    parseDart(
      async ? '() async => $code' : code,
      (parser) {
        final expr = parser.parseExpression2();
        if (async && expr is FunctionExpression) {
          return (expr.body as ExpressionFunctionBody).expression;
        }
        return expr;
      },
    );

ParseResult<CompilationUnit> parseDartCompilationUnit(String code) => parseDart(
      code,
      (parser) => parser.parseCompilationUnit2(),
    );

ParseResult<Block> parseDartBlock(String code) => parseDart(
      code,
      (parser) => (parser.parseFunctionBody(
        false,
        ParserErrorCode.MISSING_FUNCTION_BODY,
        false,
      ) as BlockFunctionBody)
          .block,
    );

class _ErrorListener implements AnalysisErrorListener {
  final errors = <AnalysisError>[];

  @override
  void onError(AnalysisError error) {
    errors.add(error);
  }
}
