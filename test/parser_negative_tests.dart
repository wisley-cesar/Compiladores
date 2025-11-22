import 'package:test/test.dart';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Parser - testes negativos', () {
    test('uso de variável antes da declaração (erro semântico)', () {
      // A inicialização de 'x' usa 'y' que ainda não foi declarada -> erro
      final src = 'uids x = y;\nuids y = 2;\n';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer(null, src);
      analyzer.analyze(program);

      // O analisador semântico atual registra uso antes da declaração
      expect(analyzer.errors, isNotEmpty);
    });

    test('if com condição não-booleano (pendente)', () {
      // Pendente: o analisador semântico ainda não valida o tipo da condição
      // Marcamos como skip até implementarmos a checagem de tipo em condições
      final src = 'uids a = 0;\nif (1) a = 1;\n';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      analyzer.analyze(program);

      expect(analyzer.errors, isNotEmpty);
    });

    test('while com condição não-booleano (pendente)', () {
      final src = 'uids i = 0;\nwhile ("x") { i = i + 1; }\n';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      analyzer.analyze(program);

      expect(analyzer.errors, isNotEmpty);
    });
  });
}
