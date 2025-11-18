// ignore_for_file: unused_local_variable
import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Parser - declarações', () {
    test('declarações simples com inicializadores e sem inicializadores', () {
      final src = 'uids a = 10;\nint b;\nfloat c = 1.5;\n';

      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);

      // 'uids' infere o tipo; declarações explícitas produzem tipos declarados
      expect(table.lookup('a')?.type, equals('int'));
      expect(table.lookup('b')?.type, equals('int'));
      expect(table.lookup('c')?.type, equals('double'));
    });

    test('declaração sem ponto-e-vírgula gera erro de parse', () {
      final src = 'uids x = 5'; // falta ';'
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      // O parser deve ter registrado erros
      expect(parser.errors, isNotEmpty);
    });
  });
}
