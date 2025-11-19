import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/ast/ast.dart';

void main() {
  group('Golden examples AST', () {
    final examples = [
      'example_declarations.src',
      'example_if_else.src',
      'example_while_block.src',
      'example_coercion.src',
      'demo1.src',
      'demo2.src',
    ];

    for (final name in examples) {
      test('AST matches for $name', () {
        final srcPath = 'examples/$name';
        final src = File(srcPath).readAsStringSync();
        final lexer = Lexer(src);
        final tokens = lexer.analisar();
        final parser = Parser(TokenStream(tokens), src);
        final program = parser.parseProgram();
        final analyzer = SemanticAnalyzer(null, src);
        analyzer.analyze(program);

        // Produce AST JSON
        final actual = astToJson(program);

        // Read expected JSON
        final expectedPath = 'examples/ast/${name.replaceAll('.src', '.json')}';
        expect(
          File(expectedPath).existsSync(),
          isTrue,
          reason: 'Expected golden file $expectedPath',
        );
        final expectedStr = File(expectedPath).readAsStringSync();
        final expected = jsonDecode(expectedStr);

        // Normalize both ASTs by removing positional keys (linha/coluna)
        dynamic stripPositions(dynamic node) {
          if (node is Map) {
            final m = <String, dynamic>{};
            node.forEach((k, v) {
              if (k == 'linha' || k == 'coluna') return;
              m[k] = stripPositions(v);
            });
            return m;
          }
          if (node is List) return node.map(stripPositions).toList();
          return node;
        }

        final normActual = stripPositions(actual);
        final normExpected = stripPositions(expected);

        expect(normActual, equals(normExpected));
      });
    }
  });
}
