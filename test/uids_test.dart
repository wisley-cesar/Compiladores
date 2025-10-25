import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token.dart';

void main() {
  group('Lexer - uids keyword', () {
    test('reconhece palavra reservada uids e declaração básica', () {
      final lexer = Lexer('uids x = 10;');
      final tokens = lexer.analisar();

      expect(tokens.any((t) => t.tipo == TokenType.palavraReservada && t.lexema == 'uids'), isTrue);
      expect(tokens.any((t) => t.tipo == TokenType.identificador && t.lexema == 'x'), isTrue);
      expect(tokens.any((t) => t.tipo == TokenType.numero && t.lexema == '10'), isTrue);
    });

    test('reconhece uids sem inicializador (aceito no léxico, semântica decide)', () {
      final lexer = Lexer('uids y;');
      final tokens = lexer.analisar();

      expect(tokens.any((t) => t.tipo == TokenType.palavraReservada && t.lexema == 'uids'), isTrue);
      expect(tokens.any((t) => t.tipo == TokenType.identificador && t.lexema == 'y'), isTrue);
    });
  });
}
