import 'dart:io';

import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  group('Integration Lexer->Parser->Semantic', () {
    final validExamples = [
      'examples/example_declarations.src',
      'examples/example_if_else.src',
      'examples/example_while_block.src',
      'examples/example_coercion.src',
    ];

    test('valid examples produce no lexer/parse/semantic errors', () {
      for (final path in validExamples) {
        final src = File(path).readAsStringSync();
        final lexer = Lexer(src);
        final tokens = lexer.analisar();
        expect(
          lexer.listaErrosEstruturados,
          isEmpty,
          reason: 'Lexer errors in $path',
        );

        final parser = Parser(TokenStream(tokens), src);
        final program = parser.parseProgram();
        expect(parser.errors, isEmpty, reason: 'Parser errors in $path');

        final analyzer = SemanticAnalyzer(null, src);
        analyzer.analyze(program);
        // allow warnings (isWarning==true) but assert there are no fatal semantic errors
        final fatalSem = analyzer.errors
            .where((e) => e.isWarning != true)
            .toList();
        expect(fatalSem, isEmpty, reason: 'Fatal semantic errors in $path');
      }
    });

    test(
      'invalid/demo examples produce errors (lexer or parser or semantic)',
      () {
        final invalid = ['examples/demo1.src', 'examples/demo2.src'];

        for (final path in invalid) {
          final src = File(path).readAsStringSync();
          final lexer = Lexer(src);
          final tokens = lexer.analisar();

          final parser = Parser(TokenStream(tokens), src);
          final program = parser.parseProgram();

          final analyzer = SemanticAnalyzer(null, src);
          analyzer.analyze(program);

          final hasLexErrors = lexer.listaErrosEstruturados.isNotEmpty;
          final hasParseErrors = parser.errors.isNotEmpty;
          final hasSemErrors = analyzer.errors.isNotEmpty;

          expect(
            hasLexErrors || hasParseErrors || hasSemErrors,
            isTrue,
            reason: 'Expected some error for invalid example $path',
          );
        }
      },
    );
  });
}
