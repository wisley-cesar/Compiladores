import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token.dart';

void main() {
  group('Lexer - Testes Adicionais', () {
    test(
      'comentário de bloco com múltiplas quebras de linha atualiza posição',
      () {
        final codigo = '''int x = 1;
/* comment
line2
line3 */
int y = 2;''';
        final lexer = Lexer(codigo);
        final tokens = lexer.analisar();

        final yToken = tokens.firstWhere((t) => t.lexema == 'y');
        // y deve estar na linha 5 (as linhas do comentário incrementam o contador)
        expect(yToken.linha, equals(5));
        // em 'int y = 2;' o identificador 'y' começa na coluna 5
        expect(yToken.coluna, equals(5));
      },
    );

    test('comentário não fechado reporta erro com contexto', () {
      final codigo = 'int x = 1; /* unclosed comment';
      final lexer = Lexer(codigo);
      lexer.analisar();
      expect(lexer.temErros, isTrue);
      final errs = lexer.listaErrosEstruturados;
      expect(
        errs.any((e) => e.mensagem.contains('Comentário de bloco não fechado')),
        isTrue,
      );
      final err = errs.firstWhere(
        (e) => e.mensagem.contains('Comentário de bloco não fechado'),
      );
      expect(err.contexto.contains('unclosed comment'), isTrue);
    });

    test('expoente inválido em número gera erro com contexto', () {
      final codigo = 'double x = 1.23e+';
      final lexer = Lexer(codigo);
      lexer.analisar();
      expect(lexer.temErros, isTrue);
      final errs = lexer.listaErrosEstruturados;
      expect(errs.any((e) => e.mensagem.contains('Expoente inválido')), isTrue);
      final err = errs.firstWhere(
        (e) => e.mensagem.contains('Expoente inválido'),
      );
      expect(err.contexto.contains('1.23e+'), isTrue);
    });

    test('reconhecer operador de três caracteres >>>', () {
      final lexer = Lexer('a >>> b');
      final tokens = lexer.analisar();

      expect(
        tokens.any((t) => t.tipo == TokenType.operador && t.lexema == '>>>'),
        isTrue,
      );
    });

    test(
      'recuperação após caractere inválido - continua reconhecendo tokens',
      () {
        final lexer = Lexer('int x = @ 42;');
        final tokens = lexer.analisar();

        expect(lexer.temErros, isTrue);
        // depois do erro, ainda deve reconhecer o número 42
        expect(
          tokens.any((t) => t.tipo == TokenType.numero && t.lexema == '42'),
          isTrue,
        );
        // e o identificador x
        expect(
          tokens.any(
            (t) => t.tipo == TokenType.identificador && t.lexema == 'x',
          ),
          isTrue,
        );

        // além disso, a mensagem de erro estruturada deve conter contexto
        final List lexErrors = lexer.listaErrosEstruturados;
        expect(lexErrors, isNotEmpty);
        final err = lexErrors.first;
        // verificar campos estruturados
        expect(
          err.mensagem.contains('Caractere inválido') ||
              err.mensagem.contains('Operador inválido'),
          isTrue,
        );
        expect(err.linha, equals(1));
        // coluna do caractere '@' em 'int x = @ 42;' é 9 (base 1)
        expect(err.coluna, equals(9));
        expect(err.contexto.contains('@'), isTrue);
        expect(err.contexto.contains('42'), isTrue);
      },
    );
  });
}
