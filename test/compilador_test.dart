// ignore_for_file: unused_local_variable
import 'package:test/test.dart';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token.dart';

/// Testes abrangentes para o analisador léxico
void main() {
  group('Lexer - Testes Básicos', () {
    test('deve reconhecer palavras reservadas', () {
      final lexer = Lexer('int if while for');
      final tokens = lexer.analisar();

      expect(
        tokens.any(
          (t) => t.tipo == TokenType.palavraReservada && t.lexema == 'int',
        ),
        isTrue,
      );
      expect(
        tokens.any(
          (t) => t.tipo == TokenType.palavraReservada && t.lexema == 'if',
        ),
        isTrue,
      );
      expect(
        tokens.any(
          (t) => t.tipo == TokenType.palavraReservada && t.lexema == 'while',
        ),
        isTrue,
      );
      expect(
        tokens.any(
          (t) => t.tipo == TokenType.palavraReservada && t.lexema == 'for',
        ),
        isTrue,
      );
    });

    test('deve reconhecer identificadores', () {
      final lexer = Lexer('variavel _variavel var123');
      final tokens = lexer.analisar();

      expect(
        tokens.any(
          (t) => t.tipo == TokenType.identificador && t.lexema == 'variavel',
        ),
        isTrue,
      );
      expect(
        tokens.any(
          (t) => t.tipo == TokenType.identificador && t.lexema == '_variavel',
        ),
        isTrue,
      );
      expect(
        tokens.any(
          (t) => t.tipo == TokenType.identificador && t.lexema == 'var123',
        ),
        isTrue,
      );
    });

    test('deve reconhecer números inteiros e decimais', () {
      final lexer = Lexer('123 45.67 1.23e5');
      final tokens = lexer.analisar();

      expect(
        tokens.any((t) => t.tipo == TokenType.numero && t.lexema == '123'),
        isTrue,
      );
      expect(
        tokens.any((t) => t.tipo == TokenType.numero && t.lexema == '45.67'),
        isTrue,
      );
      expect(
        tokens.any((t) => t.tipo == TokenType.numero && t.lexema == '1.23e5'),
        isTrue,
      );
    });

    test('deve reconhecer strings literais', () {
      final lexer = Lexer('"Hello" "World\\n" "Test\\t"');
      final tokens = lexer.analisar();

      expect(
        tokens.any(
          (t) => t.tipo == TokenType.string && t.lexema.contains('Hello'),
        ),
        isTrue,
      );
      expect(
        tokens.any(
          (t) => t.tipo == TokenType.string && t.lexema.contains('World'),
        ),
        isTrue,
      );
      expect(
        tokens.any(
          (t) => t.tipo == TokenType.string && t.lexema.contains('Test'),
        ),
        isTrue,
      );
    });

    test('deve reconhecer literais booleanos', () {
      final lexer = Lexer('true false');
      final tokens = lexer.analisar();

      expect(
        tokens.any((t) => t.tipo == TokenType.booleano && t.lexema == 'true'),
        isTrue,
      );
      expect(
        tokens.any((t) => t.tipo == TokenType.booleano && t.lexema == 'false'),
        isTrue,
      );
    });

    test('deve reconhecer operadores', () {
      final lexer = Lexer('+ - * / = == != < > <= >= && ||');
      final tokens = lexer.analisar();

      expect(
        tokens.any((t) => t.tipo == TokenType.operador && t.lexema == '+'),
        isTrue,
      );
      expect(
        tokens.any((t) => t.tipo == TokenType.operador && t.lexema == '=='),
        isTrue,
      );
      expect(
        tokens.any((t) => t.tipo == TokenType.operador && t.lexema == '&&'),
        isTrue,
      );
    });

    test('deve reconhecer símbolos especiais', () {
      final lexer = Lexer('( ) { } [ ] ; , .');
      final tokens = lexer.analisar();

      expect(
        tokens.any((t) => t.tipo == TokenType.simbolo && t.lexema == '('),
        isTrue,
      );
      expect(
        tokens.any((t) => t.tipo == TokenType.simbolo && t.lexema == ')'),
        isTrue,
      );
      expect(
        tokens.any((t) => t.tipo == TokenType.simbolo && t.lexema == '{'),
        isTrue,
      );
      expect(
        tokens.any((t) => t.tipo == TokenType.simbolo && t.lexema == '}'),
        isTrue,
      );
    });
  });

  group('Lexer - Comentários', () {
    test('deve ignorar comentários de linha', () {
      final lexer = Lexer('int x = 10; // comentário');
      final tokens = lexer.analisar();

      expect(tokens.any((t) => t.tipo == TokenType.comentario), isFalse);
      expect(tokens.any((t) => t.lexema == 'comentário'), isFalse);
    });

    test('deve ignorar comentários de bloco', () {
      final lexer = Lexer('int x = 10; /* comentário */ int y = 20;');
      final tokens = lexer.analisar();

      expect(tokens.any((t) => t.tipo == TokenType.comentario), isFalse);
      expect(tokens.any((t) => t.lexema == 'comentário'), isFalse);
    });
  });

  group('Lexer - Tratamento de Erros', () {
    test('deve detectar strings não fechadas', () {
      final lexer = Lexer('String s = "não fechada;');
      final tokens = lexer.analisar();

      expect(lexer.temErros, isTrue);
      expect(
        lexer.listaErrosEstruturados.any(
          (e) => e.mensagem.contains('String não fechada'),
        ),
        isTrue,
      );
    });

    test('deve detectar caracteres inválidos', () {
      final lexer = Lexer('int x = @;');
      final tokens = lexer.analisar();

      expect(lexer.temErros, isTrue);
      expect(
        lexer.listaErrosEstruturados.any(
          (e) => e.mensagem.contains('Caractere inválido'),
        ),
        isTrue,
      );
    });

    test('deve detectar números malformados', () {
      final lexer = Lexer('int x = 1.2.3;');
      final tokens = lexer.analisar();

      // O lexer deve processar o número como 1.2 e depois .3
      expect(
        tokens.any((t) => t.tipo == TokenType.numero && t.lexema == '1.2'),
        isTrue,
      );
    });
  });

  group('Lexer - Posição dos Tokens', () {
    test('deve manter posição correta dos tokens', () {
      final lexer = Lexer('int x = 10;');
      final tokens = lexer.analisar();

      final intToken = tokens.firstWhere((t) => t.lexema == 'int');
      expect(intToken.linha, equals(1));
      // agora coluna representa a posição inicial do token (base 1)
      expect(intToken.coluna, equals(1));

      final xToken = tokens.firstWhere((t) => t.lexema == 'x');
      expect(xToken.linha, equals(1));
      expect(xToken.coluna, equals(5));
    });

    test('deve rastrear quebras de linha corretamente', () {
      final lexer = Lexer('int x = 10;\nint y = 20;');
      final tokens = lexer.analisar();

      final yToken = tokens.firstWhere((t) => t.lexema == 'y');
      expect(yToken.linha, equals(2));
      expect(yToken.coluna, equals(5));
    });
  });

  group('Lexer - Estatísticas', () {
    test('deve gerar estatísticas corretas', () {
      final lexer = Lexer('int x = 10; float y = 3.14;');
      final tokens = lexer.analisar();
      final stats = lexer.getEstatisticas();

      expect(stats['totalTokens'], greaterThan(0));
      expect(stats['totalErros'], equals(0));
      expect(stats['linhasProcessadas'], equals(1));
    });
  });
}
