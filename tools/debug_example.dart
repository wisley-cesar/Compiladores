import 'dart:io';
import 'dart:convert';

import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/ast/ast.dart';

void main(List<String> args) {
  final path = 'examples/example_if_else.src';
  final src = File(path).readAsStringSync();
  print('Source:\n$src');

  final lexer = Lexer(src);
  final tokens = lexer.analisar();
  final stream = TokenStream(tokens);
  final parser = Parser(stream, src);
  final program = parser.parseProgram();

  if (parser.errors.isNotEmpty) {
    print('\nParser errors:');
    for (var e in parser.errors) print(e.toString());
  } else {
    print('\nNo parser errors.');
  }

  final encoder = JsonEncoder.withIndent('  ');
  final astJson = astToJson(program);
  print('\nAST JSON:\n');
  print(encoder.convert(astJson));
}
