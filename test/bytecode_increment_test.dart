import 'package:test/test.dart';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/vm/bytecode_generator.dart';
import 'package:compilador/vm/bytecode.dart';
import 'dart:convert'; 
void main() {
  group('Bytecode Generator - Increment/Decrement Operators', () {
    test('prefixo ++i em expressão', () {
      final src = '''
int i = 5;
++i;
''';
      
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream, src);
      final program = parser.parseProgram();
      
      expect(parser.errors, isEmpty, reason: 'Não deve haver erros de parse');
      
      final analyzer = SemanticAnalyzer(null, src);
      final symbolTable = analyzer.analyze(program);
      
      expect(analyzer.errors.where((e) => !e.isWarning).isEmpty, isTrue,
          reason: 'Não deve haver erros semânticos');
      
    final generator = BytecodeGenerator(symbolTable);
    final bytecode = generator.generate(program);
      
      expect(generator.errors, isEmpty, reason: 'Não deve haver erros de geração');
      
      // Verifica instruções
      final instructions = bytecode.instructions;
      
      // Deve ter: pushInt(5), storeVar("i"), loadVar("i"), pushInt(1), add, storeVar("i"), pop, halt
      expect(instructions.length, greaterThanOrEqualTo(7));
      
      // Verifica que há loadVar, pushInt(1), add, storeVar para ++i
      final loadVarIndex = instructions.indexWhere((i) => 
          i.opcode == Opcode.loadVar && i.operand == 'i');
      expect(loadVarIndex, greaterThan(0), reason: 'Deve ter loadVar("i")');
      
      int pushOneIndex = -1;
      for (int idx = loadVarIndex + 1; idx < instructions.length; idx++) {
        final inst = instructions[idx];
        if (inst.opcode == Opcode.pushInt && inst.operand == 1) {
          pushOneIndex = idx;
          break;
        }
      }
      expect(pushOneIndex, greaterThan(loadVarIndex),
          reason: 'Deve ter pushInt(1) após loadVar');

      int addIndex = -1;
      for (int idx = pushOneIndex + 1; idx < instructions.length; idx++) {
        final inst = instructions[idx];
        if (inst.opcode == Opcode.add) {
          addIndex = idx;
          break;
        }
      }
      expect(addIndex, greaterThan(pushOneIndex),
          reason: 'Deve ter add após pushInt(1)');

      int storeVarIndex = -1;
      for (int idx = addIndex + 1; idx < instructions.length; idx++) {
        final inst = instructions[idx];
        if (inst.opcode == Opcode.storeVar && inst.operand == 'i') {
          storeVarIndex = idx;
          break;
        }
      }
      expect(storeVarIndex, greaterThan(addIndex),
          reason: 'Deve ter storeVar("i") após add');
      
      print('\n=== Prefixo ++i ===');
      print(bytecode.toString());
      print('\n=== JSON ===');
      print(JsonEncoder.withIndent('  ').convert(bytecode.toJson()));
    });
    
    test('postfix i++ em expressão', () {
      final src = '''
int i = 5;
i++;
''';
      
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream, src);
      final program = parser.parseProgram();
      
      expect(parser.errors, isEmpty, reason: 'Não deve haver erros de parse');
      
      final analyzer = SemanticAnalyzer(null, src);
      final symbolTable = analyzer.analyze(program);
      
      expect(analyzer.errors.where((e) => !e.isWarning).isEmpty, isTrue,
          reason: 'Não deve haver erros semânticos');
      
    final generator = BytecodeGenerator(symbolTable);
    final bytecode = generator.generate(program);
      
      expect(generator.errors, isEmpty, reason: 'Não deve haver erros de geração');
      
      final instructions = bytecode.instructions;
      
      // Para postfix: deve carregar i duas vezes (uma para retornar, outra para incrementar)
      // pushInt(5), storeVar("i"), loadVar("i"), loadVar("i"), pushInt(1), add, storeVar("i"), pop, halt
      expect(instructions.length, greaterThanOrEqualTo(8));
      
      // Verifica que há dois loadVar("i") consecutivos (postfix)
      final loadVarIndices = instructions.asMap().entries
          .where((e) => e.value.opcode == Opcode.loadVar && e.value.operand == 'i')
          .map((e) => e.key)
          .toList();
      
      expect(loadVarIndices.length, greaterThanOrEqualTo(2),
          reason: 'Postfix deve carregar variável duas vezes');
      
      print('\n=== Postfix i++ ===');
      print(bytecode.toString());
      print('\n=== JSON ===');
      print(JsonEncoder.withIndent('  ').convert(bytecode.toJson()));
    });
    
    test('--i (prefixo decremento)', () {
      final src = '''
int i = 10;
--i;
''';
      
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream, src);
      final program = parser.parseProgram();
      
      expect(parser.errors, isEmpty);
      
      final analyzer = SemanticAnalyzer(null, src);
      final symbolTable = analyzer.analyze(program);
      
    final generator = BytecodeGenerator(symbolTable);
    final bytecode = generator.generate(program);
      
      expect(generator.errors, isEmpty);
      
      // Verifica que usa 'sub' ao invés de 'add'
      final subIndex = bytecode.instructions.indexWhere((i) => i.opcode == Opcode.sub);
      expect(subIndex, greaterThan(0), reason: 'Deve ter sub para --i');
      
      print('\n=== Prefixo --i ===');
      print(bytecode.toString());
    });
    
    test('i-- (postfix decremento)', () {
      final src = '''
int i = 10;
i--;
''';
      
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream, src);
      final program = parser.parseProgram();
      
      expect(parser.errors, isEmpty);
      
      final analyzer = SemanticAnalyzer(null, src);
      final symbolTable = analyzer.analyze(program);
      
    final generator = BytecodeGenerator(symbolTable);
    final bytecode = generator.generate(program);
      
      expect(generator.errors, isEmpty);
      
      // Verifica que usa 'sub'
      final subIndex = bytecode.instructions.indexWhere((i) => i.opcode == Opcode.sub);
      expect(subIndex, greaterThan(0), reason: 'Deve ter sub para i--');
      
      print('\n=== Postfix i-- ===');
      print(bytecode.toString());
    });
    
    test('i++ em loop for', () {
      final src = '''
for (int i = 0; i < 5; i++) {
  int x = i;
}
''';
      
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream, src);
      final program = parser.parseProgram();
      
      expect(parser.errors, isEmpty);
      
      final analyzer = SemanticAnalyzer(null, src);
      final symbolTable = analyzer.analyze(program);
      
      final generator = BytecodeGenerator(symbolTable);
      final bytecode = generator.generate(program);
      
      expect(generator.errors, isEmpty);
      
      // Verifica que há incremento no update do for
      final instructions = bytecode.instructions;
      final hasIncrement = instructions.any((i) => 
          (i.opcode == Opcode.loadVar && i.operand == 'i') ||
          (i.opcode == Opcode.add));
      
      expect(hasIncrement, isTrue, reason: 'Deve ter incremento no for');
      
      print('\n=== i++ em for loop ===');
      print(bytecode.toString());
    });
    
    test('++i em atribuição', () {
      final src = '''
int i = 5;
int j = ++i;
''';
      
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream, src);
      final program = parser.parseProgram();
      
      expect(parser.errors, isEmpty);
      
      final analyzer = SemanticAnalyzer(null, src);
      final symbolTable = analyzer.analyze(program);
      
      final generator = BytecodeGenerator(symbolTable);
      final bytecode = generator.generate(program);
      
      expect(generator.errors, isEmpty);
      
      print('\n=== ++i em atribuição ===');
      print(bytecode.toString());
    });
    
    test('i++ em atribuição', () {
      final src = '''
int i = 5;
int j = i++;
''';
      
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream, src);
      final program = parser.parseProgram();
      
      expect(parser.errors, isEmpty);
      
      final analyzer = SemanticAnalyzer(null, src);
      final symbolTable = analyzer.analyze(program);
      
      final generator = BytecodeGenerator(symbolTable);
      final bytecode = generator.generate(program);
      
      expect(generator.errors, isEmpty);
      
      print('\n=== i++ em atribuição ===');
      print(bytecode.toString());
    });
    
    test('erro: ++ aplicado a variável não declarada', () {
      final src = '''
++x;
''';
      
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream, src);
      final program = parser.parseProgram();
      
      final analyzer = SemanticAnalyzer(null, src);
      final symbolTable = analyzer.analyze(program);
      
      final generator = BytecodeGenerator(symbolTable);
      final bytecode = generator.generate(program);
      
      // Deve ter erro: variável não declarada
      expect(generator.errors, isNotEmpty);
      expect(generator.errors.any((e) => 
          e.mensagem.contains('não declarada')), isTrue);
      
      print('\n=== Erro: variável não declarada ===');
      for (final e in generator.errors) {
        print(e);
      }
    });
    
    test('erro: ++ aplicado a tipo não numérico', () {
      final src = '''
string s = "hello";
++s;
''';
      
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final stream = TokenStream(tokens);
      final parser = Parser(stream, src);
      final program = parser.parseProgram();
      
      final analyzer = SemanticAnalyzer(null, src);
      final symbolTable = analyzer.analyze(program);
      
      final generator = BytecodeGenerator(symbolTable);
      final bytecode = generator.generate(program);
      
      // Deve ter erro: tipo não numérico
      expect(generator.errors, isNotEmpty);
      expect(generator.errors.any((e) => 
          e.mensagem.contains('numéricos')), isTrue);
      
      print('\n=== Erro: tipo não numérico ===');
      for (final e in generator.errors) {
        print(e);
      }
    });
  });
}

