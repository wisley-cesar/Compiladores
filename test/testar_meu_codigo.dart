#!/usr/bin/env dart
/// Script para testar seu próprio código
/// Uso: dart testar_meu_codigo.dart <arquivo.src>
///   ou: dart testar_meu_codigo.dart  (usa exemplo padrão)

import 'dart:io';
import 'dart:convert';

import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/vm/bytecode_generator.dart';

void main(List<String> args) {
  String src;

  // Se arquivo fornecido, ler do arquivo
  if (args.isNotEmpty && args[0].endsWith('.src')) {
    final file = File(args[0]);
    if (!file.existsSync()) {
      print('❌ Arquivo não encontrado: ${args[0]}');
      exit(1);
    }
    src = file.readAsStringSync();
    print('📄 Lendo arquivo: ${args[0]}\n');
  } else {
    // Usar exemplo padrão
    src = '''
int i = 0;
for (int j = 0; j < 5; j++) {
  i = i + j;
}
int resultado = i * 2;
''';
    print('💡 Usando exemplo padrão. Para usar seu arquivo:');
    print('   dart testar_meu_codigo.dart seu_arquivo.src\n');
  }

  print('📝 Código:');
  print('─' * 60);
  print(src);
  print('─' * 60);
  print('');

  // Pipeline de compilação
  final lexer = Lexer(src);
  final tokens = lexer.analisar();

  if (lexer.listaErrosEstruturados.isNotEmpty) {
    print('❌ Erros léxicos:');
    lexer.listaErrosEstruturados.forEach((e) => print('   $e'));
    return;
  }

  final stream = TokenStream(tokens);
  final parser = Parser(stream, src);
  final program = parser.parseProgram();

  if (parser.errors.isNotEmpty) {
    print('❌ Erros de parse:');
    parser.errors.forEach((e) => print('   $e'));
    return;
  }

  final analyzer = SemanticAnalyzer(null, src);
  final symbolTable = analyzer.analyze(program);

  if (analyzer.errors.where((e) => !e.isWarning).isNotEmpty) {
    print('❌ Erros semânticos:');
    analyzer.errors.where((e) => !e.isWarning).forEach((e) => print('   $e'));
    return;
  }

  final generator = BytecodeGenerator(symbolTable);
  final bytecode = generator.generate(program);

  if (generator.errors.isNotEmpty) {
    print('❌ Erros na geração de bytecode:');
    generator.errors.forEach((e) => print('   $e'));
    return;
  }

  print('╔════════════════════════════════════════════════════════════╗');
  print('║                      BYTECODE                              ║');
  print('╚════════════════════════════════════════════════════════════╝\n');
  print(bytecode.toString());

  // Salvar JSON se solicitado
  if (args.contains('--save-json')) {
    final outputFile = File('bytecode_output.json');
    outputFile.writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(bytecode.toJson()),
    );
    print('\n💾 Bytecode JSON salvo em: bytecode_output.json');
  }

  print('\n✅ Concluído!\n');
}

