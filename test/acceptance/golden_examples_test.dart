import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Acceptance tests - programas válidos', () {
    final valids = {
      'decls_and_assign': '''
int x = 1;
float y = 2.0;
bool b = true;
x = x + 1;
''',

      'if_else_while': '''
int a = 0;
if (a < 10) {
  a = a + 1;
} else {
  a = a - 1;
}
while (a > 0) {
  a = a - 1;
}
''',

      'block_only': '''
{
  int z = 3;
  z = z * 2;
}
''',

      'uids_and_expr': '''
uids c = (1 + 2) * 3;
c = c + 1;
''',
    };

    valids.forEach((name, src) {
      test('accepts: $name', () {
        final lexer = Lexer(src);
        final tokens = lexer.analisar();
        expect(
          lexer.listaErrosEstruturados,
          isEmpty,
          reason: 'Sem erros léxicos',
        );

        final parser = Parser(TokenStream(tokens), src);
        final program = parser.parseProgram();
        expect(
          parser.errors,
          isEmpty,
          reason: 'Parser deve aceitar programa válido: $name',
        );

        final analyzer = SemanticAnalyzer(null, src);
        analyzer.analyze(program);
        final fatal = analyzer.errors
            .where((e) => e.isWarning != true)
            .toList();
        expect(
          fatal,
          isEmpty,
          reason: 'Sem erros semânticos fatais para: $name',
        );
      });
    });
  });
}
