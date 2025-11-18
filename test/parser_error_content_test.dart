import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';

void main() {
  test('Erro "identificador" ao declarar sem id', () {
    final src = 'int ;';
    final lexer = Lexer(src);
    final tokens = lexer.analisar();
    expect(lexer.listaErrosEstruturados, isEmpty);

    final parser = Parser(TokenStream(tokens), src);
    parser.parseProgram();

    expect(parser.errors, isNotEmpty);
    final err = parser.errors.firstWhere(
      (e) => e.esperado == 'identificador',
      orElse: () => parser.errors.first,
    );

    expect(err.esperado, 'identificador');
    expect(err.recebido, contains('Símbolo'));
    expect(err.linha, isNotNull);
    expect(err.contexto, isNotNull);
    expect(err.contexto!.trim(), isNotEmpty);
  });

  test('Erro de falta de ponto-e-virgula no fim do arquivo', () {
    final src = 'x = 1';
    final lexer = Lexer(src);
    final tokens = lexer.analisar();
    expect(lexer.listaErrosEstruturados, isEmpty);

    final parser = Parser(TokenStream(tokens), src);
    parser.parseProgram();

    final err = parser.errors.firstWhere(
      (e) => e.esperado == '\";\"',
      orElse: () => parser.errors.first,
    );

    expect(err.esperado, '\";\"');
    expect(err.recebido, contains('Fim de arquivo'));
    expect(err.linha, isNotNull);
  });

  test('Erro de parêntese faltando fornece mensagem, linha e contexto', () {
    final src = 'x = (1 + 2;';
    final lexer = Lexer(src);
    final tokens = lexer.analisar();
    expect(lexer.listaErrosEstruturados, isEmpty);

    final parser = Parser(TokenStream(tokens), src);
    parser.parseProgram();

    final err = parser.errors.firstWhere(
      (e) => e.mensagem.contains('Parêntese'),
      orElse: () => parser.errors.first,
    );

    expect(err.mensagem, contains('Parêntese'));
    expect(err.linha, isNotNull);
    expect(err.contexto, isNotNull);
    expect(err.contexto!.trim(), isNotEmpty);
  });
}
