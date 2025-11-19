import 'dart:convert';

import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';

void main() {
  test('Múltiplos erros em um arquivo e serialização toJson()', () {
    final src = '''
int ;
 x = 1
 y = (1 + ;
''';

    final lexer = Lexer(src);
    final tokens = lexer.analisar();
    expect(lexer.listaErrosEstruturados, isEmpty);

    final parser = Parser(TokenStream(tokens), src);
    parser.parseProgram();

    // Esperamos pelo menos 2 erros (identificador faltando e ';' faltando)
    expect(parser.errors.length, greaterThanOrEqualTo(2));

    // Verifica consistência entre campos e toJson()
    for (final e in parser.errors) {
      final json = e.toJson();
      expect(json['mensagem'], e.mensagem);
      expect(json['linha'], e.linha);
      expect(json['coluna'], e.coluna);
      expect(json['contexto'], e.contexto);
      expect(json.containsKey('esperado'), isTrue);
      expect(json.containsKey('recebido'), isTrue);

      if (e.esperado != null) expect(json['esperado'], e.esperado);
      if (e.recebido != null) expect(json['recebido'], e.recebido);

      // serialização JSON simples deve conter a chave mensagem
      final s = jsonEncode(json);
      expect(s, contains('mensagem'));
    }

    // Garantir que pelo menos um erro pediu por ponto-e-vírgula
    final hasSemi = parser.errors.any(
      (e) => (e.esperado?.contains(';') ?? false),
    );
    expect(hasSemi, isTrue);
  });
}
