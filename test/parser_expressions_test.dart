import 'package:test/test.dart';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Parser - expressões aritméticas', () {
    test('1 + 2 -> int', () {
      final lexer = Lexer('uids a = 1 + 2;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);
      expect(table.lookup('a')?.type, equals('int'));
    });

    test('1 + 2.0 -> double', () {
      final lexer = Lexer('uids b = 1 + 2.0;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);
      expect(table.lookup('b')?.type, equals('double'));
    });

    test('(1 + 2) * 3 -> int', () {
      final lexer = Lexer('uids c = (1 + 2) * 3;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);
      expect(table.lookup('c')?.type, equals('int'));
    });

    test('1 / 2 -> double', () {
      final lexer = Lexer('uids d = 1 / 2;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);
      expect(table.lookup('d')?.type, equals('double'));
    });
  });
}
