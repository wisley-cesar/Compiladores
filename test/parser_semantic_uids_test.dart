import 'package:test/test.dart';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Parser + Semantic - uids inference', () {
    test('inferencia int para 10', () {
      final lexer = Lexer('uids x = 10;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);

      final sym = table.lookup('x');
      expect(sym, isNotNull);
      expect(sym?.type, equals('int'));
    });

    test('inferencia double para 3.14', () {
      final lexer = Lexer('uids y = 3.14;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);

      final sym = table.lookup('y');
      expect(sym, isNotNull);
      expect(sym?.type, equals('double'));
    });

    test('inferencia string e dynamic', () {
      final lexer = Lexer('uids s = "oi"; uids z;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);

      final s = table.lookup('s');
      final z = table.lookup('z');
      expect(s?.type, equals('string'));
      expect(z?.type, equals('dynamic'));
    });
  });
}
