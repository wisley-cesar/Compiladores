import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Parser - declarações em locais variados', () {
    test('declaração dentro de bloco é aceita', () {
      final src = '''
int x = 0;
if (true) {
  int y = 1;
  y = y + 1;
}
x = x + 1;
''';

      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      expect(
        lexer.listaErrosEstruturados,
        isEmpty,
        reason: 'Erros léxicos não esperados',
      );

      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();
      expect(
        parser.errors,
        isEmpty,
        reason: 'Parser deve aceitar declarações dentro de blocos',
      );

      final analyzer = SemanticAnalyzer(null, src);
      analyzer.analyze(program);
      final fatalSem = analyzer.errors
          .where((e) => e.isWarning != true)
          .toList();
      expect(
        fatalSem,
        isEmpty,
        reason: 'Não devem existir erros semânticos fatais',
      );
    });

    test(
      'declaração após comando em nível topo também é aceita (permissivo)',
      () {
        final src = '''
int a = 0;
a = 1;
int b = 2;
''';

        final lexer = Lexer(src);
        final tokens = lexer.analisar();
        expect(lexer.listaErrosEstruturados, isEmpty);

        final parser = Parser(TokenStream(tokens), src);
        final program = parser.parseProgram();
        expect(parser.errors, isEmpty);

        final analyzer = SemanticAnalyzer(null, src);
        analyzer.analyze(program);
        final fatalSem = analyzer.errors
            .where((e) => e.isWarning != true)
            .toList();
        expect(fatalSem, isEmpty);
      },
    );
  });
}
