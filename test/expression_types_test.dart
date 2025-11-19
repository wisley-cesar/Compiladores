import 'package:test/test.dart';
// no dart:io required

import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Expression type inference', () {
    test('relational operators produce bool', () {
      final src = 'uids a = 1; if (a < 5) { a = 2; }';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();
      final analyzer = SemanticAnalyzer(null, src);
      analyzer.analyze(program);

      // No parse or semantic errors expected
      expect(parser.errors, isEmpty);
      expect(lexer.listaErrosEstruturados, isEmpty);
      expect(
        analyzer.errors,
        isEmpty,
        reason: 'Expected no semantic errors for relational expr',
      );
    });

    test('equality operators produce bool', () {
      final src = 'uids x = 1; if (x == 1) { x = 0; }';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();
      final analyzer = SemanticAnalyzer(null, src);
      analyzer.analyze(program);

      expect(parser.errors, isEmpty);
      expect(lexer.listaErrosEstruturados, isEmpty);
      expect(
        analyzer.errors,
        isEmpty,
        reason: 'Expected no semantic errors for equality expr',
      );
    });

    test('logical operators produce bool', () {
      // assign the logical expression to a bool variable to avoid nested paren issues
      final src =
          'uids a = 1; uids b = 2; bool cond = a < 5 && b > 0; if (cond) { a = 2; }';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();
      final analyzer = SemanticAnalyzer(null, src);
      analyzer.analyze(program);

      expect(parser.errors, isEmpty);
      expect(lexer.listaErrosEstruturados, isEmpty);
      expect(
        analyzer.errors,
        isEmpty,
        reason: 'Expected no semantic errors for logical expr',
      );
    });

    test('unary ! produces bool', () {
      // assign negated relational to bool variable
      final src = 'uids a = 1; bool cond = !(a < 5); if (cond) { a = 0; }';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();
      final analyzer = SemanticAnalyzer(null, src);
      analyzer.analyze(program);

      expect(parser.errors, isEmpty);
      expect(lexer.listaErrosEstruturados, isEmpty);
      expect(
        analyzer.errors,
        isEmpty,
        reason: 'Expected no semantic errors for unary !',
      );
    });
  });
}
