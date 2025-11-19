import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Semantic - escopos e redeclaração', () {
    test('redeclaração no mesmo escopo gera erro', () {
      final lexer = Lexer('uids x = 1; uids x = 2;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);

      expect(table.lookup('x'), isNotNull);
      expect(analyzer.errors, isNotEmpty);
      expect(
        analyzer.errors.any((e) => e.mensagem.contains('Redeclaração')),
        isTrue,
      );
    });

    test('uso antes da declaração gera erro e tipo dynamic', () {
      final lexer = Lexer('uids a = b; uids b = 3;');
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream);
      final program = parser.parseProgram();

      final analyzer = SemanticAnalyzer();
      final table = analyzer.analyze(program);

      // a foi declarada, mas sua inicialização referenciou b que ainda não existia
      final a = table.lookup('a');
      final b = table.lookup('b');

      expect(a, isNotNull);
      expect(b, isNotNull);
      // a deveria receber type dynamic devido ao uso de b indefinido no momento
      expect(a?.type, equals('dynamic'));
      expect(
        analyzer.errors.any(
          (e) => e.mensagem.contains('Uso de variável antes da declaração'),
        ),
        isTrue,
      );
    });
  });
}
