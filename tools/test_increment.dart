import 'dart:io';
import 'dart:convert';

import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/bytecode_generator.dart';

void main(List<String> args) {
  print('=== TESTE DE OPERADORES INCREMENTAIS (++ e --) ===\n');

  // Teste 1: Prefixo ++i
  print('1. TESTE: Prefixo ++i\n');
  testCase('''
int i = 5;
++i;
''', 'Prefixo ++i');

  // Teste 2: Postfix i++
  print('\n2. TESTE: Postfix i++\n');
  testCase('''
int i = 5;
i++;
''', 'Postfix i++');

  // Teste 3: Prefixo --i
  print('\n3. TESTE: Prefixo --i\n');
  testCase('''
int i = 10;
--i;
''', 'Prefixo --i');

  // Teste 4: Postfix i--
  print('\n4. TESTE: Postfix i--\n');
  testCase('''
int i = 10;
i--;
''', 'Postfix i--');

  // Teste 5: i++ em for loop
  print('\n5. TESTE: i++ em for loop\n');
  testCase('''
for (int i = 0; i < 5; i++) {
  int x = i;
}
''', 'i++ em for loop');

  // Teste 6: ++i em atribuição
  print('\n6. TESTE: ++i em atribuição\n');
  testCase('''
int i = 5;
int j = ++i;
''', '++i em atribuição');

  // Teste 7: i++ em atribuição
  print('\n7. TESTE: i++ em atribuição\n');
  testCase('''
int i = 5;
int j = i++;
''', 'i++ em atribuição');

  // Teste 8: Erro - variável não declarada
  print('\n8. TESTE: Erro - variável não declarada\n');
  testCaseError('''
++x;
''', 'Erro: variável não declarada');

  // Teste 9: Erro - tipo não numérico
  print('\n9. TESTE: Erro - tipo não numérico\n');
  testCaseError('''
string s = "hello";
++s;
''', 'Erro: tipo não numérico');
}

void testCase(String src, String name) {
  print('Código:');
  print(src);
  print('---');
  
  try {
    final lexer = Lexer(src);
    final tokens = lexer.analisar();
    
    if (lexer.listaErrosEstruturados.isNotEmpty) {
      print('ERROS LÉXICOS:');
      for (final e in lexer.listaErrosEstruturados) {
        print('  - $e');
      }
      return;
    }
    
    final stream = TokenStream(tokens);
    final parser = Parser(stream, src);
    final program = parser.parseProgram();
    
    if (parser.errors.isNotEmpty) {
      print('ERROS DE PARSE:');
      for (final e in parser.errors) {
        print('  - $e');
      }
      return;
    }
    
    final analyzer = SemanticAnalyzer(null, src);
    final symbolTable = analyzer.analyze(program);
    
    final semanticErrors = analyzer.errors.where((e) => !e.isWarning).toList();
    if (semanticErrors.isNotEmpty) {
      print('ERROS SEMÂNTICOS:');
      for (final e in semanticErrors) {
        print('  - $e');
      }
    }
    
    final generator = BytecodeGenerator(symbolTable);
    final bytecode = generator.generate(program);
    
    if (generator.errors.isNotEmpty) {
      print('ERROS DE GERAÇÃO DE BYTECODE:');
      for (final e in generator.errors) {
        print('  - $e');
      }
      return;
    }
    
    print('BYTECODE GERADO:');
    print(bytecode.toString());
    
    print('\nJSON:');
    print(JsonEncoder.withIndent('  ').convert(bytecode.toJson()));
    
    print('\n✓ SUCESSO\n');
  } catch (e, stackTrace) {
    print('ERRO: $e');
    print('Stack trace: $stackTrace');
  }
}

void testCaseError(String src, String name) {
  print('Código:');
  print(src);
  print('---');
  
  try {
    final lexer = Lexer(src);
    final tokens = lexer.analisar();
    
    final stream = TokenStream(tokens);
    final parser = Parser(stream, src);
    final program = parser.parseProgram();
    
    final analyzer = SemanticAnalyzer(null, src);
    final symbolTable = analyzer.analyze(program);
    
    final generator = BytecodeGenerator(symbolTable);
    final bytecode = generator.generate(program);
    
    if (generator.errors.isNotEmpty) {
      print('ERROS DETECTADOS (esperado):');
      for (final e in generator.errors) {
        print('  - $e');
      }
      print('✓ ERRO DETECTADO CORRETAMENTE\n');
    } else {
      print('✗ ERRO: Esperava-se erro, mas nenhum foi gerado!\n');
    }
  } catch (e, stackTrace) {
    print('ERRO INESPERADO: $e');
    print('Stack trace: $stackTrace');
  }
}

