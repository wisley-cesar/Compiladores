import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token.dart';

/// Testes específicos para detecção de ambiguidades sintáticas
void main() {
  group('Lexer - Detecção de Ambiguidades', () {
    test('deve detectar parênteses extras consecutivos', () {
      final lexer = Lexer('if (x > 5)) {');
      final tokens = lexer.analisar();

      expect(lexer.temErros, isTrue);
      expect(
        lexer.listaErrosEstruturados.any(
          (e) => e.mensagem.contains('Parêntese extra detectado'),
        ),
        isTrue,
      );
    });

    test('deve detectar chaves extras consecutivas', () {
      final lexer = Lexer('if (x > 5) { }}');
      final tokens = lexer.analisar();

      expect(lexer.temErros, isTrue);
      expect(
        lexer.listaErrosEstruturados.any(
          (e) => e.mensagem.contains('Chave extra detectada'),
        ),
        isTrue,
      );
    });

    test('deve processar palavras reservadas sem espaços corretamente', () {
      final lexer = Lexer('if(x > 5) {');
      final tokens = lexer.analisar();

      // Verificar se o lexer processa corretamente palavras reservadas sem espaços
      expect(
        tokens.any(
          (t) => t.tipo == TokenType.palavraReservada && t.lexema == 'if',
        ),
        isTrue,
      );
      expect(
        lexer.temErros,
        isFalse,
      ); // Não deve gerar erro por falta de espaço
    });

    test('deve detectar padrão problemático )){', () {
      final lexer = Lexer('if (x > 5)){');
      final tokens = lexer.analisar();

      expect(lexer.temErros, isTrue);
      expect(
        lexer.listaErrosEstruturados.any(
          (e) => e.mensagem.contains('Parêntese extra antes de chave'),
        ),
        isTrue,
      );
    });

    test('deve detectar operadores sem espaços adequados', () {
      final lexer = Lexer('if (x>5) {');
      final tokens = lexer.analisar();

      // Verificar se o lexer processa corretamente mesmo sem espaços
      expect(
        tokens.any((t) => t.tipo == TokenType.operador && t.lexema == '>'),
        isTrue,
      );
    });

    test('deve detectar ponto e vírgula duplo', () {
      final lexer = Lexer('int x = 10;;');
      final tokens = lexer.analisar();

      expect(lexer.temErros, isTrue);
      expect(
        lexer.listaErrosEstruturados.any(
          (e) => e.mensagem.contains('Ponto e vírgula duplo detectado'),
        ),
        isTrue,
      );
    });

    test('deve detectar múltiplas ambiguidades no mesmo código', () {
      final lexer = Lexer('''
        if(x>5)){
        }}
        ''');
      final tokens = lexer.analisar();

      // Verificar se o lexer processa o código mesmo com problemas
      expect(
        tokens.any(
          (t) => t.tipo == TokenType.palavraReservada && t.lexema == 'if',
        ),
        isTrue,
      );
      expect(
        tokens.any((t) => t.tipo == TokenType.operador && t.lexema == '>'),
        isTrue,
      );
      expect(
        tokens.any((t) => t.tipo == TokenType.simbolo && t.lexema == ')'),
        isTrue,
      );
    });

    test('não deve gerar falsos positivos em código correto', () {
      final lexer = Lexer('''
        if (x > 5) {
            x = x + 1;
        }
        ''');
      final tokens = lexer.analisar();

      expect(lexer.temErros, isFalse);
      expect(lexer.listaErros.isEmpty, isTrue);
    });
  });
}
