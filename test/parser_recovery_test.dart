import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';

void main() {
  test('Parser recupera de erro e continua parseando declarações seguintes', () {
    final src = '''
int a = 1
int b = 2;
 a = a + 1;
''';

    final lexer = Lexer(src);
    final tokens = lexer.analisar();
    expect(lexer.listaErrosEstruturados, isEmpty);

    final parser = Parser(TokenStream(tokens), src);
    final program = parser.parseProgram();

    // Deve ter pelo menos um erro (falta de ';')
    expect(parser.errors, isNotEmpty);

    // Mesmo com erro, o parser deve ter continuado e reconhecido a declaração de 'b'
    // e a atribuição subsequente — portanto, mais de uma declaração/comando.
    expect(program.statements.length, greaterThanOrEqualTo(2));
  });
}
