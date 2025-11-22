import 'package:test/test.dart';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token.dart';

void main() {
  group('Escape sequences em strings', () {
    test('Reconhece escape sequences válidas', () {
      final src = r'"\n\t\"\\\r\0"';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      final stringToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.string,
        orElse: () => Token(TokenType.erro, '', 0, 0),
      );
      
      expect(stringToken.tipo, equals(TokenType.string));
      expect(lexer.listaErrosEstruturados, isEmpty);
    });

    test('Detecta escape sequence inválida', () {
      final src = r'"\x"';
      final lexer = Lexer(src);
      lexer.analisar();
      
      final erros = lexer.listaErrosEstruturados;
      expect(erros, isNotEmpty);
      expect(
        erros.any((e) => e.mensagem.toLowerCase().contains('escape sequence inválida')),
        isTrue,
      );
    });

    test('String com múltiplas escape sequences válidas', () {
      final src = r'"Olá\nMundo\tTeste"';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      expect(lexer.listaErrosEstruturados, isEmpty);
      final stringToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.string,
      );
      expect(stringToken.tipo, equals(TokenType.string));
    });

    test('String com escape sequence de aspas', () {
      final src = r'"Ele disse \"Olá\""';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      expect(lexer.listaErrosEstruturados, isEmpty);
      final stringToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.string,
      );
      expect(stringToken.tipo, equals(TokenType.string));
    });

    test('String com escape sequence de barra invertida', () {
      final src = r'"Caminho: C:\\Users\\Teste"';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      expect(lexer.listaErrosEstruturados, isEmpty);
      final stringToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.string,
      );
      expect(stringToken.tipo, equals(TokenType.string));
    });

    test('Detecta múltiplas escape sequences inválidas', () {
      final src = r'"\x\y\z"';
      final lexer = Lexer(src);
      lexer.analisar();
      
      final erros = lexer.listaErrosEstruturados;
      expect(erros.length, greaterThanOrEqualTo(1));
      expect(
        erros.any((e) => e.mensagem.toLowerCase().contains('escape sequence inválida')),
        isTrue,
      );
    });
  });

  group('Números começando com ponto', () {
    test('Aceita número começando com ponto', () {
      final src = 'x = .5;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      final numeroToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.numero && t.lexema == '.5',
        orElse: () => Token(TokenType.erro, '', 0, 0),
      );
      
      expect(numeroToken.tipo, equals(TokenType.numero));
      expect(numeroToken.lexema, equals('.5'));
      expect(lexer.listaErrosEstruturados, isEmpty);
    });

    test('Aceita número decimal sem parte inteira com notação científica', () {
      final src = 'x = .5e10;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      final numeroToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.numero,
        orElse: () => Token(TokenType.erro, '', 0, 0),
      );
      
      expect(numeroToken.tipo, equals(TokenType.numero));
      expect(numeroToken.lexema, equals('.5e10'));
      expect(lexer.listaErrosEstruturados, isEmpty);
    });

    test('Aceita número decimal sem parte inteira com expoente negativo', () {
      final src = 'x = .123e-5;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      final numeroToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.numero,
        orElse: () => Token(TokenType.erro, '', 0, 0),
      );
      
      expect(numeroToken.tipo, equals(TokenType.numero));
      expect(lexer.listaErrosEstruturados, isEmpty);
    });

    test('Ponto sozinho é tratado como símbolo (não como número)', () {
      final src = 'x = .;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      // O ponto sozinho é tratado como símbolo, não como número
      // Portanto, não deve gerar erro de número malformado
      // O ponto está na lista de símbolos válidos
      final simboloToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.simbolo && t.lexema == '.',
        orElse: () => Token(TokenType.erro, '', 0, 0),
      );
      
      expect(simboloToken.tipo, equals(TokenType.simbolo));
      expect(simboloToken.lexema, equals('.'));
      // Não deve ter erros relacionados a número malformado
      expect(
        lexer.listaErrosEstruturados.any(
          (e) => e.mensagem.toLowerCase().contains('número malformado'),
        ),
        isFalse,
      );
    });

    test('Aceita número decimal normal (com parte inteira)', () {
      final src = 'x = 1.5;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      final numeroToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.numero && t.lexema == '1.5',
        orElse: () => Token(TokenType.erro, '', 0, 0),
      );
      
      expect(numeroToken.tipo, equals(TokenType.numero));
      expect(numeroToken.lexema, equals('1.5'));
      expect(lexer.listaErrosEstruturados, isEmpty);
    });

    test('Aceita número inteiro normal', () {
      final src = 'x = 42;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      final numeroToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.numero && t.lexema == '42',
        orElse: () => Token(TokenType.erro, '', 0, 0),
      );
      
      expect(numeroToken.tipo, equals(TokenType.numero));
      expect(numeroToken.lexema, equals('42'));
      expect(lexer.listaErrosEstruturados, isEmpty);
    });

    test('Aceita número começando com ponto seguido de múltiplos dígitos', () {
      final src = 'x = .123456;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      
      final numeroToken = tokens.firstWhere(
        (t) => t.tipo == TokenType.numero && t.lexema == '.123456',
        orElse: () => Token(TokenType.erro, '', 0, 0),
      );
      
      expect(numeroToken.tipo, equals(TokenType.numero));
      expect(numeroToken.lexema, equals('.123456'));
      expect(lexer.listaErrosEstruturados, isEmpty);
    });
  });
}

