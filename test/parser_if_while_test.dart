import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Parser - if / while / blocos', () {
    test('if com else e atribuições', () {
      final src = 'uids a = 0;\nif (true) a = 1; else a = 2;\n';

      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);

      expect(table.lookup('a')?.type, equals('int'));
    });

    test('while com bloco e incremento', () {
      final src = '''uids i = 0;
while (i < 3) {
  i = i + 1;
}
''';

      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);

      expect(table.lookup('i')?.type, equals('int'));
    });
  });
}
