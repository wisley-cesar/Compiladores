import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Rejection tests - programas inválidos (sintaxe)', () {
    final invalids = {
      'missing_semicolon': '''
int x = 1
x = 2;
''',

      'if_missing_paren': '''
if (true {
  x = 1;
}
''',

      'unclosed_block': '''
{
  int a = 1;
''',

      'assign_without_id': '''
= 1;
''',

      'bad_declaration_token': '''
int 123 = 1;
''',
    };

    invalids.forEach((name, src) {
      test('rejects: $name', () {
        final lexer = Lexer(src);
        final tokens = lexer.analisar();

        final parser = Parser(TokenStream(tokens), src);
        final program = parser.parseProgram();

        // Either parser reported syntax errors OR semantic analyzer reports fatal errors
        final parserHadErrors = parser.errors.isNotEmpty;
        final analyzer = SemanticAnalyzer(null, src);
        analyzer.analyze(program);
        final fatalSem = analyzer.errors
            .where((e) => e.isWarning != true)
            .toList();

        expect(
          parserHadErrors || fatalSem.isNotEmpty,
          isTrue,
          reason:
              'Entrada inválida deve produzir erro de parsing ou semântico: $name',
        );
      });
    });
  });
}
