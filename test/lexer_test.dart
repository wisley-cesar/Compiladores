import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token.dart';

void main() {
  group('Lexer básico', () {
    test('Reconhece palavras reservadas, identificador, número e símbolos', () {
      final src = 'uids x = 42;\nif (x > 0) x = x - 1;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();

      // verificar alguns tokens por posição
      expect(tokens.first.lexema, equals('uids'));
      expect(tokens[1].lexema, equals('x'));
      // buscar token número '42'
      final foundNumber = tokens.firstWhere(
        (t) => t.tipo == TokenType.numero && t.lexema == '42',
        orElse: () => Token(TokenType.erro, '', 0, 0),
      );
      expect(foundNumber.tipo, equals(TokenType.numero));
    });

    test('String não fechada produz erro léxico', () {
      final src = 'string s = "Olá mundo\n';
      final lexer = Lexer(src);
      lexer.analisar();
      final errs = lexer.listaErrosEstruturados;
      expect(errs, isNotEmpty);
      expect(errs.first.mensagem.toLowerCase(), contains('string não fechada'));
    });

    test('Comentário de bloco não fechado produz erro', () {
      final src = '/* comentário sem fechar\n x = 1;';
      final lexer = Lexer(src);
      lexer.analisar();
      final errs = lexer.listaErrosEstruturados;
      expect(
        errs.any(
          (e) => e.mensagem.toLowerCase().contains('comentário de bloco'),
        ),
        isTrue,
      );
    });

    test('Expoente inválido em número gera erro', () {
      final src = 'x = 1.2e+\n';
      final lexer = Lexer(src);
      lexer.analisar();
      final errs = lexer.listaErrosEstruturados;
      expect(
        errs.any((e) => e.mensagem.toLowerCase().contains('expoente inválido')),
        isTrue,
      );
    });

    test('Tokens multi-char são reconhecidos', () {
      final src = 'a == b != c <= d >= e && f || g;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final ops = tokens
          .where((t) => t.tipo == TokenType.operador)
          .map((t) => t.lexema)
          .toList();
      expect(ops, contains('=='));
      expect(ops, contains('!='));
      expect(ops, contains('<='));
      expect(ops, contains('>='));
      expect(ops, contains('&&'));
      expect(ops, contains('||'));
    });
  });
}
