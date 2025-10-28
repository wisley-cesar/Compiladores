import 'dart:io';
import 'dart:convert';

import 'package:compilador/lexer.dart';
import 'package:compilador/token.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/ast/ast.dart';
import 'package:compilador/parse_error.dart';

/// Programa principal do compilador
/// Demonstra a análise léxica de código-fonte
void main(List<String> args) {
  print('=== COMPILADOR - ANÁLISE LÉXICA ===\n');

  String src;
  if (args.isNotEmpty) {
    final path = args[0];
    final file = File(path);
    if (!file.existsSync()) {
      print('Arquivo não encontrado: $path');
      exit(1);
    }
    src = file.readAsStringSync();
    print('Lendo arquivo: $path\n');
  } else {
    // Exemplo embutido quando nenhum arquivo é passado
    src = '''
uids x = (1 + 2) * 3;
uids s = "olá";
int a = 10;
''';
    print('Usando código de exemplo embutido. Para analisar um arquivo: dart run bin/main.dart <caminho>\n');
  }

  print('Código de entrada:\n');
  print(src);
  print('\n' + '=' * 50 + '\n');

  // Executar lexer
  final lexer = Lexer(src);
  final tokens = lexer.analisar();

  // Imprimir tokens
  print('=== TOKENS ===');
  for (final t in tokens) {
    print(t);
  }

  // Opções de linha de comando
  final dumpAstJson = args.contains('--dump-ast-json');
  final dumpTokensJson = args.contains('--dump-tokens-json');
  final dumpErrorsJson = args.contains('--dump-errors-json');

  if (dumpTokensJson) {
    final encoder = JsonEncoder.withIndent('  ');
    final jsonTokens = tokens.map((t) => t.toJson()).toList();
    print('\n=== TOKENS (JSON) ===');
    print(encoder.convert(jsonTokens));
  }

  // Tentar construir AST e executar análise semântica (se o parser existir)
  try {
    final stream = TokenStream(tokens);
    final parser = Parser(stream);
    final program = parser.parseProgram();

    if (dumpAstJson) {
      final encoder = JsonEncoder.withIndent('  ');
      final astJson = astToJson(program);
      print('\n=== AST (JSON) ===');
      print(encoder.convert(astJson));
    }

    final analyzer = SemanticAnalyzer();
    final symbolTable = analyzer.analyze(program);

    print('\n=== SYMBOL TABLE (JSON) ===');
    final jsonSymbols = jsonEncode(symbolTable.allSymbols.map((s) => s.toJson()).toList());
    print(jsonSymbols);

    if (analyzer.errors.isNotEmpty) {
      print('\n=== SEMANTIC ERRORS ===');
      for (final e in analyzer.errors) print(e);
    }

    if (dumpErrorsJson) {
      final encoder = JsonEncoder.withIndent('  ');
      final lexical = lexer.listaErrosEstruturados.map((e) => e.toJson()).toList();
      final semantic = analyzer.errors.map((e) => e.toJson()).toList();
                       final parse = parser.errors.map((e) => e.toJson()).toList();
      final out = {'lexical': lexical, 'semantic': semantic, 'parse': parse};
      print('\n=== ERRORS (JSON) ===');
      print(encoder.convert(out));
    }
  } on StateError catch (e) {
    // Converter StateError (lançado por TokenStream.expect / Parser) em ParseError
    final msg = e.message;
    // Tenta extrair linha/coluna da mensagem no formato '... na linha X, coluna Y'
    final regex = RegExp(r'linha\s*([0-9]+),\s*coluna\s*([0-9]+)');
    final match = regex.firstMatch(msg);
    int? linha;
    int? coluna;
    if (match != null) {
      linha = int.tryParse(match.group(1)!);
      coluna = int.tryParse(match.group(2)!);
    }
    final p = ParseError(msg, linha: linha, coluna: coluna);
    print('\nParser/Semantic phase failed: $p');

    if (dumpErrorsJson) {
      final encoder = JsonEncoder.withIndent('  ');
      final lexical = lexer.listaErrosEstruturados.map((e) => e.toJson()).toList();
      final out = {'lexical': lexical, 'semantic': [], 'parse': [p.toJson()]};
      print('\n=== ERRORS (JSON) ===');
      print(encoder.convert(out));
    }
  } catch (e) {
    print('\nParser/Semantic phase not available or failed: $e');
  }
}
