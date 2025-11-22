import 'dart:io';
import 'dart:convert';

import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/sintatica/ast/ast.dart';
import 'package:compilador/sintatica/parse_error.dart';
import 'package:compilador/semantic_error.dart';
import 'package:compilador/vm/bytecode_generator.dart';
import 'package:compilador/vm/bytecode_vm.dart';

/// Programa principal do compilador
/// Demonstra a análise léxica de código-fonte
void main(List<String> args) {
  print('=== COMPILADOR - ANÁLISE LÉXICA ===\n');

  String src;
  // Suporta: `dart run bin/main.dart <path> [--flags]` ou apenas flags
  String? pathArg;
  if (args.isNotEmpty && !args[0].startsWith('-')) {
    pathArg = args[0];
  }

  if (pathArg != null) {
    final file = File(pathArg);
    if (!file.existsSync()) {
      print('Arquivo não encontrado: $pathArg');
      exit(1);
    }
    src = file.readAsStringSync();
    print('Lendo arquivo: $pathArg\n');
  } else {
    // Exemplo embutido quando nenhum arquivo é passado
    src = '''
uids x = (1 + 2) * 3;
uids s = "olá";
int a = 10;
''';
    print(
      'Usando código de exemplo embutido. Para analisar um arquivo: dart run bin/main.dart <caminho>\n',
    );
  }

  print('Código de entrada:\n');
  print(src);
  print('\n${'=' * 50}\n');

  // Executar lexer
  final lexer = Lexer(src);
  final tokens = lexer.analisar();

  // Imprimir tokens
  print('=== TOKENS ===');
  for (final t in tokens) {
    print(t);
  }

  // Imprimir erros léxicos (se existirem) com contexto e caret
  if (lexer.listaErrosEstruturados.isNotEmpty) {
    print('\n=== LEXICAL ERRORS ===');
    for (final e in lexer.listaErrosEstruturados) {
      print(formatErrorPretty(e, src));
    }
  }

  // Opções de linha de comando
  final dumpAstJson = args.contains('--dump-ast-json');
  final dumpTokensJson = args.contains('--dump-tokens-json');
  final dumpErrorsJson = args.contains('--dump-errors-json');
  final dumpBytecode = args.contains('--dump-bytecode');
  final dumpBytecodeJson = args.contains('--dump-bytecode-json');
  final runVm = args.contains('--run-vm');
  final vmTrace = args.contains('--vm-trace');
  // Suporta escrever tokens em arquivo: --tokens-out <file>
  String? tokensOutPath;
  final tokOutIdx = args.indexOf('--tokens-out');
  if (tokOutIdx >= 0) {
    if (tokOutIdx + 1 < args.length) {
      tokensOutPath = args[tokOutIdx + 1];
    } else {
      print(
        'Flag --tokens-out requer um caminho de arquivo: --tokens-out <file>',
      );
      exit(1);
    }
  }
  // Suporta escrever AST e ERRORS em arquivo: --ast-out <file> --errors-out <file>
  String? astOutPath;
  final astOutIdx = args.indexOf('--ast-out');
  if (astOutIdx >= 0) {
    if (astOutIdx + 1 < args.length) {
      astOutPath = args[astOutIdx + 1];
    } else {
      print('Flag --ast-out requer um caminho de arquivo: --ast-out <file>');
      exit(1);
    }
  }

  String? errorsOutPath;
  final errOutIdx = args.indexOf('--errors-out');
  if (errOutIdx >= 0) {
    if (errOutIdx + 1 < args.length) {
      errorsOutPath = args[errOutIdx + 1];
    } else {
      print(
        'Flag --errors-out requer um caminho de arquivo: --errors-out <file>',
      );
      exit(1);
    }
  }

  if (dumpTokensJson) {
    final encoder = JsonEncoder.withIndent('  ');
    final jsonTokens = tokens.map((t) => t.toJson()).toList();
    print('\n=== TOKENS (JSON) ===');
    print(encoder.convert(jsonTokens));
  }

  // Se solicitado, grava os tokens em arquivo JSON
  if (tokensOutPath != null) {
    try {
      final encoder = JsonEncoder.withIndent('  ');
      final jsonTokens = tokens.map((t) => t.toJson()).toList();
      final outFile = File(tokensOutPath);
      outFile.createSync(recursive: true);
      outFile.writeAsStringSync(encoder.convert(jsonTokens));
      print('\nTokens gravados em: $tokensOutPath');
    } catch (e) {
      print('Falha ao gravar tokens em $tokensOutPath: $e');
    }
  }

  // Tentar construir AST e executar análise semântica (se o parser existir)
  try {
    final stream = TokenStream(tokens);
    final parser = Parser(stream, src);
    final program = parser.parseProgram();

    // Se houver erros de parse, imprima de forma amigável com contexto
    if (parser.errors.isNotEmpty) {
      print('\n=== PARSE ERRORS ===');
      for (final e in parser.errors) {
        print(formatErrorPretty(e, src));
      }
    }

    if (dumpAstJson) {
      final encoder = JsonEncoder.withIndent('  ');
      final astJson = astToJson(program);
      print('\n=== AST (JSON) ===');
      print(encoder.convert(astJson));
    }

    if (astOutPath != null) {
      try {
        final encoder = JsonEncoder.withIndent('  ');
        final astJson = astToJson(program);
        final outFile = File(astOutPath);
        outFile.createSync(recursive: true);
        outFile.writeAsStringSync(encoder.convert(astJson));
        print('\nAST gravado em: $astOutPath');
      } catch (e) {
        print('Falha ao gravar AST em $astOutPath: $e');
      }
    }

    final analyzer = SemanticAnalyzer(null, src);
    final symbolTable = analyzer.analyze(program);

    print('\n=== SYMBOL TABLE (JSON) ===');
    final jsonSymbols = jsonEncode(
      symbolTable.allSymbols.map((s) => s.toJson()).toList(),
    );
    print(jsonSymbols);

    if (analyzer.errors.isNotEmpty) {
      print('\n=== SEMANTIC ERRORS ===');
      for (final e in analyzer.errors) {
        print(formatErrorPretty(e, src));
      }
    }

    // Geração de bytecode
    if (dumpBytecode || dumpBytecodeJson) {
      final generator = BytecodeGenerator(symbolTable);
      final bytecode = generator.generate(program);

      if (dumpBytecode) {
        print('\n=== BYTECODE ===');
        print(bytecode.toString());
      }

      if (dumpBytecodeJson) {
        print('\n=== BYTECODE (JSON) ===');
        final encoder = JsonEncoder.withIndent('  ');
        print(encoder.convert(bytecode.toJson()));
      }

      if (generator.errors.isNotEmpty) {
        print('\n=== BYTECODE GENERATION ERRORS ===');
        for (final e in generator.errors) {
          print(formatErrorPretty(e, src));
        }
      }

      // Executar na VM se solicitado
      if (runVm && generator.errors.isEmpty) {
        print('\n=== EXECUTANDO NA VM ===');
        try {
          final vm = VirtualMachine(bytecode);
          final result = vm.run(trace: vmTrace);

          print('\nVariáveis globais:');
          if (result.globals.isEmpty) {
            print('  (nenhuma variável global)');
          } else {
            for (final entry in result.globals.entries) {
              print('  ${entry.key} = ${entry.value}');
            }
          }

          if (result.stack.isNotEmpty) {
            print('\nPilha final:');
            for (var i = 0; i < result.stack.length; i++) {
              print('  [$i] ${result.stack[i]}');
            }
          }
        } catch (e) {
          print('Erro na execução da VM: $e');
        }
      }
    }

    if (dumpErrorsJson) {
      final encoder = JsonEncoder.withIndent('  ');
      final lexical = lexer.listaErrosEstruturados
          .map((e) => e.toJson())
          .toList();
      final semantic = analyzer.errors.map((e) => e.toJson()).toList();
      final parse = parser.errors.map((e) => e.toJson()).toList();
      final out = {'lexical': lexical, 'semantic': semantic, 'parse': parse};
      print('\n=== ERRORS (JSON) ===');
      print(encoder.convert(out));
    }

    if (errorsOutPath != null) {
      try {
        final encoder = JsonEncoder.withIndent('  ');
        final lexical = lexer.listaErrosEstruturados
            .map((e) => e.toJson())
            .toList();
        final semantic = analyzer.errors.map((e) => e.toJson()).toList();
        final parse = parser.errors.map((e) => e.toJson()).toList();
        final out = {'lexical': lexical, 'semantic': semantic, 'parse': parse};
        final outFile = File(errorsOutPath);
        outFile.createSync(recursive: true);
        outFile.writeAsStringSync(encoder.convert(out));
        print('\nErrors gravados em: $errorsOutPath');
      } catch (e) {
        print('Falha ao gravar errors em $errorsOutPath: $e');
      }
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
    print('\nParser/Semantic phase failed:');
    print(formatErrorPretty(p, src));

    if (dumpErrorsJson) {
      final encoder = JsonEncoder.withIndent('  ');
      final lexical = lexer.listaErrosEstruturados
          .map((e) => e.toJson())
          .toList();
      final out = {
        'lexical': lexical,
        'semantic': [],
        'parse': [p.toJson()],
      };
      print('\n=== ERRORS (JSON) ===');
      print(encoder.convert(out));
    }
  } catch (e) {
    print('\nParser/Semantic phase not available or failed: $e');
  }
}

/// Formata um erro (LexError, ParseError ou SemanticError) mostrando a linha
/// de código com um caret (^) apontando a coluna do erro e a mensagem abaixo.
String formatErrorPretty(Object error, String src) {
  // Tenta extrair linha/coluna de acordo com o tipo
  int? linha;
  int? coluna;
  String mensagem = error.toString();

  try {
    if (error is ParseError) {
      linha = error.linha;
      coluna = error.coluna;
      mensagem = error.mensagem;
    } else if (error is SemanticError) {
      linha = error.linha;
      coluna = error.coluna;
      mensagem = error.mensagem;
    }
  } catch (_) {
    // ignore
  }

  // Também tenta tratar LexError sem importar diretamente aqui
  if (linha == null || coluna == null) {
    // Tenta cálculos por reflexo nos campos comuns
    try {
      final map = (error as dynamic).toJson();
      if (map is Map) {
        if (map['linha'] is int) linha = map['linha'] as int;
        if (map['coluna'] is int) coluna = map['coluna'] as int;
        if (map['mensagem'] is String) mensagem = map['mensagem'] as String;
      }
    } catch (_) {}
  }

  if (linha == null || coluna == null) {
    // Sem posição — retorna a mensagem completa
    return mensagem;
  }

  // Extrai a linha (1-indexed)
  final lines = src.split('\n');
  final index = linha - 1;
  final lineText = (index >= 0 && index < lines.length) ? lines[index] : '';

  // Constrói a linha com caret. Ajusta coluna para 1..len+1
  final caretPos = coluna.clamp(1, (lineText.length + 1));
  final buffer = StringBuffer();
  buffer.writeln('Linha $linha, Coluna $coluna: $mensagem');
  buffer.writeln(lineText);
  // Espaços antes do caret: caretPos-1 (considerando colunas 1-based)
  buffer.writeln('${' ' * (caretPos - 1)}^');

  return buffer.toString();
}
