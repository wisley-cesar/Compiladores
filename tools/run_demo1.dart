import 'dart:io';
import 'dart:convert';

import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/sintatica/ast/ast.dart';

void main(List<String> args) {
  final path = 'examples/demo1.src';
  if (!File(path).existsSync()) {
    print('File not found: $path');
    exit(1);
  }
  final src = File(path).readAsStringSync();
  print('--- Source ($path) ---');
  print(src);

  print('\n--- Lexer ---');
  final lexer = Lexer(src);
  final tokens = lexer.analisar();
  if (lexer.temErros) {
    print('Lexer errors:');
    for (final e in lexer.listaErrosEstruturados) {
      print('- ${e.toString()}');
    }
  } else {
    print('No lexer errors.');
  }

  print('\nTokens (first 200 chars of lexemes):');
  for (var t in tokens) {
    print(t);
  }

  print('\n--- Parser ---');
  final parser = Parser(TokenStream(tokens), src);
  final program = parser.parseProgram();
  if (parser.errors.isNotEmpty) {
    print('Parser errors (${parser.errors.length}):');
    for (var e in parser.errors) {
      print('- $e');
    }
  } else {
    print('No parser errors.');
  }

  print('\n--- AST JSON ---');
  final encoder = JsonEncoder.withIndent('  ');
  final astJson = astToJson(program);
  print(encoder.convert(astJson));

  print('\n--- Semantic Analyzer ---');
  final analyzer = SemanticAnalyzer(null, src);
  analyzer.analyze(program);
  if (analyzer.errors.isNotEmpty) {
    print('Semantic errors (${analyzer.errors.length}):');
    for (var e in analyzer.errors) {
      final w = e.isWarning == true ? ' (warning)' : '';
      print('- ${e.toString()}$w');
    }
  } else {
    print('No semantic errors.');
  }
}
