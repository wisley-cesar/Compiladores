#!/usr/bin/env dart
/// Teste completo de todas as condições mínimas de implementação do bytecode
/// Valida: erros, expressões, aritmética, lógica, variáveis, condicionais, laços, escopo

import 'dart:io';
import 'dart:convert';

import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/vm/bytecode_generator.dart';

int totalTestes = 0;
int testesPassaram = 0;
int testesFalharam = 0;
final List<String> erros = [];

void main() {
  print('╔════════════════════════════════════════════════════════════╗');
  print('║   TESTE COMPLETO - CONDIÇÕES MÍNIMAS DE BYTECODE          ║');
  print('╚════════════════════════════════════════════════════════════╝\n');

  // ===================================================================
  // 1. TRATAMENTO DE ERRO: Checagem da existência das variáveis
  // ===================================================================
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('1️⃣  TRATAMENTO DE ERRO: Existência de Variáveis');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  testar('1.1 - Uso de variável não declarada', '''
int x = 10;
int y = z + 5;
''', deveGerarErro: true, erroEsperado: 'não declarada');

  testar('1.2 - Atribuição para variável não declarada', '''
int x = 10;
z = 20;
''', deveGerarErro: true, erroEsperado: 'não declarada');

  testar('1.3 - Variável declarada corretamente', '''
int x = 10;
int y = x + 5;
''', deveGerarErro: false);

  // ===================================================================
  // 2. EXPRESSÕES E OPERAÇÕES ARITMÉTICAS
  // ===================================================================
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('2️⃣  EXPRESSÕES E OPERAÇÕES ARITMÉTICAS');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  testar('2.1 - Soma (+)', '''
int a = 10;
int b = 5;
int soma = a + b;
''', deveGerarErro: false, deveConterBytecode: ['loadvar(a)', 'loadvar(b)', 'add']);

  testar('2.2 - Subtração (-)', '''
int a = 10;
int b = 5;
int sub = a - b;
''', deveGerarErro: false, deveConterBytecode: ['loadvar(a)', 'loadvar(b)', 'sub']);

  testar('2.3 - Multiplicação (*)', '''
int a = 10;
int b = 5;
int mult = a * b;
''', deveGerarErro: false, deveConterBytecode: ['loadvar(a)', 'loadvar(b)', 'mul']);

  testar('2.4 - Divisão (/)', '''
float a = 10.0;
float b = 5.0;
float div = a / b;
''', deveGerarErro: false, deveConterBytecode: ['loadvar(a)', 'loadvar(b)', 'div']);

  testar('2.5 - Expressão complexa', '''
int a = 10;
int b = 5;
int c = 2;
int resultado = a + b * c;
''', deveGerarErro: false, deveConterBytecode: ['add', 'mul']);

  testar('2.6 - Expressão com literais', '''
int x = 10 + 5;
int y = 20 - 3;
int z = 4 * 5;
float w = 100.0 / 4.0;
''', deveGerarErro: false, deveConterBytecode: ['pushint(10)', 'pushint(5)', 'add']);

  // ===================================================================
  // 3. OPERADORES LÓGICOS
  // ===================================================================
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('3️⃣  OPERADORES LÓGICOS');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  testar('3.1 - AND (&&)', '''
bool a = true;
bool b = false;
bool resultado = a && b;
''', deveGerarErro: false, deveConterBytecode: ['loadvar(a)', 'loadvar(b)', 'and']);

  testar('3.2 - OR (||)', '''
bool a = true;
bool b = false;
bool resultado = a || b;
''', deveGerarErro: false, deveConterBytecode: ['loadvar(a)', 'loadvar(b)', 'or']);

  testar('3.3 - NOT (!)', '''
bool a = true;
bool resultado = !a;
''', deveGerarErro: false, deveConterBytecode: ['loadvar(a)', 'not']);

  testar('3.4 - Expressão lógica complexa', '''
bool a = true;
bool b = false;
bool c = true;
bool resultado = a && b || c;
''', deveGerarErro: false, deveConterBytecode: ['and', 'or']);

  // ===================================================================
  // 4. ALOCAÇÃO DE VARIÁVEIS
  // ===================================================================
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('4️⃣  ALOCAÇÃO DE VARIÁVEIS');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  testar('4.1 - Declaração com inicializador', '''
int x = 10;
''', deveGerarErro: false, deveConterBytecode: ['pushint(10)', 'storevar(x)']);

  testar('4.2 - Declaração sem inicializador', '''
int x;
''', deveGerarErro: false, deveConterBytecode: ['storevar(x)']);

  testar('4.3 - Múltiplas variáveis', '''
int x = 10;
int y = 20;
int z = 30;
''', deveGerarErro: false, deveConterBytecode: ['storevar(x)', 'storevar(y)', 'storevar(z)']);

  testar('4.4 - Diferentes tipos', '''
int i = 10;
float f = 3.14;
bool b = true;
string s = "hello";
''', deveGerarErro: false, deveConterBytecode: ['pushint', 'pushdouble', 'pushbool', 'pushstring']);

  // ===================================================================
  // 5. CONDICIONAIS (IF/ELSE)
  // ===================================================================
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('5️⃣  CONDICIONAIS (IF/ELSE)');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  testar('5.1 - If simples', '''
int x = 10;
if (x > 5) {
  x = 20;
}
''', deveGerarErro: false, deveConterBytecode: ['jumpIfFalse', 'enterScope', 'exitScope']);

  testar('5.2 - If-else', '''
int x = 10;
if (x > 5) {
  x = 20;
} else {
  x = 0;
}
''', deveGerarErro: false, deveConterBytecode: ['jumpIfFalse', 'jump', 'else', 'endif']);

  testar('5.3 - If com expressão lógica', '''
bool a = true;
bool b = false;
if (a && b) {
  int x = 10;
}
''', deveGerarErro: false, deveConterBytecode: ['and', 'jumpIfFalse']);

  testar('5.4 - If aninhado', '''
int x = 10;
if (x > 5) {
  if (x < 15) {
    x = 12;
  }
}
''', deveGerarErro: false, deveConterBytecode: ['jumpIfFalse']);

  // ===================================================================
  // 6. LAÇOS (WHILE/FOR)
  // ===================================================================
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('6️⃣  LAÇOS (WHILE/FOR)');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  testar('6.1 - While simples', '''
int i = 0;
while (i < 10) {
  i = i + 1;
}
''', deveGerarErro: false, deveConterBytecode: ['loop_start', 'loop_end', 'jumpIfFalse', 'jump']);

  testar('6.2 - For simples', '''
for (int i = 0; i < 10; i++) {
  int x = i;
}
''', deveGerarErro: false, deveConterBytecode: ['for_start', 'for_end', 'enterScope', 'exitScope']);

  testar('6.3 - For com incremento', '''
for (int i = 0; i < 5; i++) {
  int x = i * 2;
}
''', deveGerarErro: false, deveConterBytecode: ['loadvar(i)', 'add', 'storevar(i)']);

  testar('6.4 - While com condição complexa', '''
int i = 0;
int j = 10;
while (i < j && i < 5) {
  i = i + 1;
}
''', deveGerarErro: false, deveConterBytecode: ['and', 'jumpIfFalse']);

  // ===================================================================
  // 7. ESCOPO DE VARIÁVEIS
  // ===================================================================
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('7️⃣  ESCOPO DE VARIÁVEIS');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  testar('7.1 - Bloco com escopo', '''
int x = 10;
{
  int y = 20;
  int z = x + y;
}
''', deveGerarErro: false, deveConterBytecode: ['enterScope', 'exitScope']);

  testar('7.2 - Escopo aninhado', '''
int x = 10;
{
  int y = 20;
  {
    int z = 30;
    int w = x + y + z;
  }
}
''', deveGerarErro: false, deveConterBytecode: ['enterScope', 'exitScope']);

  testar('7.3 - Variável em escopo interno', '''
int x = 10;
{
  int y = 20;
}
int z = y;
''', deveGerarErro: true, erroEsperado: 'não declarada|antes da declaração');

  testar('7.4 - For com escopo', '''
int x = 10;
for (int i = 0; i < 5; i++) {
  int y = i;
}
''', deveGerarErro: false, deveConterBytecode: ['enterScope', 'exitScope']);

  testar('7.5 - If com escopo', '''
int x = 10;
if (x > 5) {
  int y = 20;
  int z = x + y;
}
''', deveGerarErro: false, deveConterBytecode: ['enterScope', 'exitScope']);

  // ===================================================================
  // 8. CASOS COMBINADOS
  // ===================================================================
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('8️⃣  CASOS COMBINADOS');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  testar('8.1 - Programa completo (tudo junto)', '''
int soma = 0;
for (int i = 0; i < 10; i++) {
  if (i > 5) {
    soma = soma + i;
  } else {
    int temp = i * 2;
    soma = soma + temp;
  }
}
int resultado = soma * 2;
''', deveGerarErro: false, deveConterBytecode: ['for_start', 'jumpIfFalse', 'enterScope', 'exitScope']);

  testar('8.2 - Operadores lógicos em condicionais', '''
int x = 10;
bool a = true;
bool b = false;
if (x > 5 && (a || b)) {
  x = x + 1;
}
''', deveGerarErro: false, deveConterBytecode: ['and', 'or', 'jumpIfFalse']);

  // ===================================================================
  // RELATÓRIO FINAL
  // ===================================================================
  print('\n╔════════════════════════════════════════════════════════════╗');
  print('║                    RELATÓRIO FINAL                         ║');
  print('╚════════════════════════════════════════════════════════════╝\n');

  print('📊 Estatísticas:');
  print('   • Total de testes: $totalTestes');
  print('   • ✅ Passaram: $testesPassaram');
  print('   • ❌ Falharam: $testesFalharam');
  print('   • Taxa de sucesso: ${(testesPassaram / totalTestes * 100).toStringAsFixed(1)}%\n');

  if (testesFalharam > 0) {
    print('❌ ERROS ENCONTRADOS:\n');
    for (final erro in erros) {
      print('   • $erro');
    }
    print('');
  }

  if (testesPassaram == totalTestes) {
    print('🎉 PARABÉNS! Todos os testes passaram!');
    print('✅ A implementação de bytecode está 100% funcional!\n');
    exit(0);
  } else {
    print('⚠️  Alguns testes falharam. Verifique os erros acima.\n');
    exit(1);
  }
}

void testar(String nome, String codigo,
    {bool deveGerarErro = false,
    String? erroEsperado,
    List<String>? deveConterBytecode}) {
  totalTestes++;

  try {
    final lexer = Lexer(codigo);
    final tokens = lexer.analisar();

    if (lexer.listaErrosEstruturados.isNotEmpty && !deveGerarErro) {
      falhar(nome, 'Erros léxicos inesperados: ${lexer.listaErrosEstruturados}');
      return;
    }

    final stream = TokenStream(tokens);
    final parser = Parser(stream, codigo);
    final program = parser.parseProgram();

    if (parser.errors.isNotEmpty && !deveGerarErro) {
      falhar(nome, 'Erros de parse inesperados: ${parser.errors}');
      return;
    }

    final analyzer = SemanticAnalyzer(null, codigo);
    final symbolTable = analyzer.analyze(program);

    final generator = BytecodeGenerator(symbolTable);
    final bytecode = generator.generate(program);

    final bytecodeStr = bytecode.toString().toLowerCase();

    // Verificar se deve gerar erro
    if (deveGerarErro) {
      final temErro = generator.errors.isNotEmpty ||
          analyzer.errors.any((e) => !e.isWarning);
      if (!temErro) {
        falhar(nome, 'Esperava-se erro, mas nenhum foi gerado');
        return;
      }
      if (erroEsperado != null) {
        final mensagens = [
          ...generator.errors.map((e) => e.mensagem.toLowerCase()),
          ...analyzer.errors
              .where((e) => !e.isWarning)
              .map((e) => e.mensagem.toLowerCase())
        ];
        final palavrasEsperadas = erroEsperado.toLowerCase().split('|');
        final temErroEsperado = palavrasEsperadas.any((palavra) =>
            mensagens.any((m) => m.contains(palavra.trim())));
        if (!temErroEsperado) {
          falhar(nome,
              'Erro gerado não contém "$erroEsperado". Erros: $mensagens');
          return;
        }
      }
    } else {
      // Não deve gerar erro
      if (generator.errors.isNotEmpty) {
        falhar(nome,
            'Erros inesperados na geração: ${generator.errors.map((e) => e.mensagem)}');
        return;
      }
      final semanticErrors = analyzer.errors.where((e) => !e.isWarning);
      if (semanticErrors.isNotEmpty) {
        falhar(nome,
            'Erros semânticos inesperados: ${semanticErrors.map((e) => e.mensagem)}');
        return;
      }

      // Verificar se contém bytecode esperado
      if (deveConterBytecode != null) {
        for (final esperado in deveConterBytecode) {
          final esperadoLower = esperado.toLowerCase();
          if (!bytecodeStr.contains(esperadoLower)) {
            falhar(nome,
                'Bytecode não contém "$esperado". Bytecode gerado:\n$bytecodeStr');
            return;
          }
        }
      }
    }

    passar(nome);
  } catch (e, stackTrace) {
    falhar(nome, 'Erro inesperado: $e\n$stackTrace');
  }
}

void passar(String nome) {
  testesPassaram++;
  print('   ✅ $nome');
}

void falhar(String nome, String motivo) {
  testesFalharam++;
  erros.add('$nome: $motivo');
  print('   ❌ $nome');
  print('      Motivo: $motivo');
}

