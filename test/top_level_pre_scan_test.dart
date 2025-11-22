// ignore_for_file: unused_local_variable
import 'package:test/test.dart';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Semantic - top-level pre-scan', () {
    test('explicit typed forward reference allowed', () {
      final lexer = Lexer('int a = b; int b = 2;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);

      expect(
        analyzer.errors,
        isEmpty,
        reason: 'Não devem haver erros semânticos',
      );
      expect(table.lookup('a')?.type, equals('int'));
      expect(table.lookup('b')?.type, equals('int'));
    });

    test('explicit typed redeclaration triggers error', () {
      final lexer = Lexer('int x; int x;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);

      expect(analyzer.errors, isNotEmpty);
      expect(
        analyzer.errors.any((e) => e.mensagem.contains('Redeclaração')),
        isTrue,
      );
    });
  });
}
