import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';

void main() {
  test(
    'Mensagens de erro sintático são padronizadas e contêm linha/coluna',
    () {
      final src = '''
int ;
''';

      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      expect(lexer.listaErrosEstruturados, isEmpty);

      final parser = Parser(TokenStream(tokens), src);
      parser.parseProgram();

      // Deve ter pelo menos um erro: falta identificador após tipo
      expect(parser.errors, isNotEmpty);
      final err = parser.errors.first;
      final s = err.toString();

      expect(
        s,
        contains('ParseError:'),
        reason: 'Formato esperado inicia com "ParseError:"',
      );
      expect(
        s,
        contains('Esperado'),
        reason: 'Mensagem padronizada deve conter palavra "Esperado"',
      );
      expect(
        s,
        contains('linha:'),
        reason: 'Mensagem deve incluir informação de linha',
      );
      expect(
        s,
        contains('Contexto:'),
        reason: 'Mensagem deve incluir contexto da linha quando disponível',
      );
    },
  );
}
