#!/usr/bin/env dart
/// Script simples para testar geração de bytecode
/// Uso: dart testar_bytecode.dart
import 'dart:io';
import 'dart:convert';

import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/vm/bytecode_generator.dart';

void main(List<String> args) {
  print('╔════════════════════════════════════════════════════════════╗');
  print('║      TESTE DE GERAÇÃO DE BYTECODE                         ║');
  print('╚════════════════════════════════════════════════════════════╝\n');

  // Escolha um dos exemplos abaixo ou modifique conforme necessário
  final src = '''
int x = 10;
int y = 20;
int soma = x + y;
x++;
++y;
int produto = x * y;
''';

  print('📝 Código fonte:');
  print('─' * 50);
  print(src);
  print('─' * 50);
  print('');

  try {
    // 1. Análise Léxica
    print('🔤 Passo 1: Análise Léxica...');
    final lexer = Lexer(src);
    final tokens = lexer.analisar();

    if (lexer.listaErrosEstruturados.isNotEmpty) {
      print('❌ ERROS LÉXICOS:');
      for (final e in lexer.listaErrosEstruturados) {
        print('   • $e');
      }
      return;
    }
    print('   ✓ ${tokens.length} tokens gerados\n');

    // 2. Análise Sintática
    print('🌳 Passo 2: Análise Sintática...');
    final stream = TokenStream(tokens);
    final parser = Parser(stream, src);
    final program = parser.parseProgram();

    if (parser.errors.isNotEmpty) {
      print('❌ ERROS DE PARSE:');
      for (final e in parser.errors) {
        print('   • $e');
      }
      return;
    }
    print('   ✓ ${program.statements.length} statements parseados\n');

    // 3. Análise Semântica
    print('🔍 Passo 3: Análise Semântica...');
    final analyzer = SemanticAnalyzer(null, src);
    final symbolTable = analyzer.analyze(program);

    final semanticErrors = analyzer.errors.where((e) => !e.isWarning).toList();
    if (semanticErrors.isNotEmpty) {
      print('❌ ERROS SEMÂNTICOS:');
      for (final e in semanticErrors) {
        print('   • $e');
      }
      return;
    }
    print('   ✓ Tabela de símbolos criada (${symbolTable.allSymbols.length} símbolos)\n');

    // 4. Geração de Bytecode
    print('⚙️  Passo 4: Geração de Bytecode...');
    final generator = BytecodeGenerator(symbolTable);
    final bytecode = generator.generate(program);

    if (generator.errors.isNotEmpty) {
      print('❌ ERROS DE GERAÇÃO:');
      for (final e in generator.errors) {
        print('   • $e');
      }
      return;
    }
    print('   ✓ ${bytecode.instructions.length} instruções geradas\n');

    // Exibir resultado
    print('╔════════════════════════════════════════════════════════════╗');
    print('║                    BYTECODE GERADO                         ║');
    print('╚════════════════════════════════════════════════════════════╝\n');
    print(bytecode.toString());

    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║                   BYTECODE (JSON)                          ║');
    print('╚════════════════════════════════════════════════════════════╝\n');
    print(JsonEncoder.withIndent('  ').convert(bytecode.toJson()));

    print('\n✅ SUCESSO! Bytecode gerado corretamente.\n');

  } catch (e, stackTrace) {
    print('❌ ERRO INESPERADO: $e');
    if (args.contains('--verbose')) {
      print('\nStack trace:');
      print(stackTrace);
    }
    exit(1);
  }
}

