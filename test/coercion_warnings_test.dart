import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Semantic - avisos de coerção implícita', () {
    test('inicializador int -> double gera aviso', () {
      final src = 'float x = 1;\n';

      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer(null, src);
      analyzer.analyze(program);

      // deve existir pelo menos um aviso de coerção
      final hasWarning = analyzer.errors.any(
        (e) => e.isWarning && e.mensagem.contains('Coerção implícita'),
      );
      expect(hasWarning, isTrue);
    });

    test('atribuição int -> double gera aviso', () {
      final src = 'float y;\nuids a = 1;\ny = a;\n';

      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer(null, src);
      analyzer.analyze(program);

      final hasWarning = analyzer.errors.any(
        (e) => e.isWarning && e.mensagem.contains('Coerção implícita'),
      );
      expect(hasWarning, isTrue);
    });
  });
}
