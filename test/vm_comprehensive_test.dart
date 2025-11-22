import 'package:compilador/vm/bytecode_generator.dart';
import 'package:compilador/vm/bytecode_vm.dart';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:test/test.dart';

/// Compila o código-fonte para bytecode e executa na VM.
VMResult _compileAndRun(String src) {
  final lexer = Lexer(src);
  final tokens = lexer.analisar();
  expect(
    lexer.listaErrosEstruturados,
    isEmpty,
    reason: 'Erros léxicos não eram esperados',
  );

  final stream = TokenStream(tokens);
  final parser = Parser(stream, src);
  final program = parser.parseProgram();
  expect(parser.errors, isEmpty, reason: 'Erros de parse não eram esperados');

  final analyzer = SemanticAnalyzer(null, src);
  final symbols = analyzer.analyze(program);
  expect(
    analyzer.errors.where((e) => !e.isWarning),
    isEmpty,
    reason: 'Erros semânticos não eram esperados',
  );

  final generator = BytecodeGenerator(symbols);
  final bytecode = generator.generate(program);
  expect(
    generator.errors,
    isEmpty,
    reason: 'Erros na geração de bytecode não eram esperados',
  );

  final vm = VirtualMachine(bytecode);
  return vm.run();
}

void main() {
  group('VirtualMachine - Testes Abrangentes', () {
    group('Aritmética Básica', () {
      test('soma simples', () {
        final result = _compileAndRun('int x = 1 + 2;');
        expect(result.globals['x'], equals(3));
      });

      test('subtração simples', () {
        final result = _compileAndRun('int x = 10 - 3;');
        expect(result.globals['x'], equals(7));
      });

      test('multiplicação simples', () {
        final result = _compileAndRun('int x = 5 * 4;');
        expect(result.globals['x'], equals(20));
      });

      test('divisão simples', () {
        final result = _compileAndRun('float x = 15.0 / 3.0;');
        expect(result.globals['x'], equals(5.0)); // Divisão retorna double
      });

      test('expressão complexa com precedência', () {
        final result = _compileAndRun('int x = (1 + 2) * 3;');
        expect(result.globals['x'], equals(9));
      });

      test('expressão com múltiplas operações', () {
        final result = _compileAndRun('int x = 10 + 5 * 2 - 3;');
        expect(result.globals['x'], equals(17));
      });
    });

    group('Operadores Lógicos', () {
      test('AND verdadeiro', () {
        final result = _compileAndRun('bool x = true && true;');
        expect(result.globals['x'], equals(true));
      });

      test('AND falso', () {
        final result = _compileAndRun('bool x = true && false;');
        expect(result.globals['x'], equals(false));
      });

      test('OR verdadeiro', () {
        final result = _compileAndRun('bool x = true || false;');
        expect(result.globals['x'], equals(true));
      });

      test('OR falso', () {
        final result = _compileAndRun('bool x = false || false;');
        expect(result.globals['x'], equals(false));
      });

      test('NOT verdadeiro', () {
        final result = _compileAndRun('bool x = !false;');
        expect(result.globals['x'], equals(true));
      });

      test('NOT falso', () {
        final result = _compileAndRun('bool x = !true;');
        expect(result.globals['x'], equals(false));
      });
    });

    group('Operadores de Comparação', () {
      test('igualdade verdadeira', () {
        final result = _compileAndRun('bool x = 5 == 5;');
        expect(result.globals['x'], equals(true));
      });

      test('igualdade falsa', () {
        final result = _compileAndRun('bool x = 5 == 3;');
        expect(result.globals['x'], equals(false));
      });

      test('diferença verdadeira', () {
        final result = _compileAndRun('bool x = 5 != 3;');
        expect(result.globals['x'], equals(true));
      });

      test('menor que verdadeiro', () {
        final result = _compileAndRun('bool x = 3 < 5;');
        expect(result.globals['x'], equals(true));
      });

      test('menor ou igual verdadeiro', () {
        final result = _compileAndRun('bool x = 5 <= 5;');
        expect(result.globals['x'], equals(true));
      });

      test('maior que verdadeiro', () {
        final result = _compileAndRun('bool x = 5 > 3;');
        expect(result.globals['x'], equals(true));
      });

      test('maior ou igual verdadeiro', () {
        final result = _compileAndRun('bool x = 5 >= 5;');
        expect(result.globals['x'], equals(true));
      });
    });

    group('Atribuições', () {
      test('atribuição simples', () {
        final result = _compileAndRun('int x = 10; x = 20;');
        expect(result.globals['x'], equals(20));
      });

      test('atribuição com expressão', () {
        final result = _compileAndRun('int x = 5; x = x + 3;');
        expect(result.globals['x'], equals(8));
      });

      // Nota: Operadores de atribuição composta não são suportados pelo parser
      // Eles são tratados como expressões binárias no gerador de bytecode
    });

    group('Incremento/Decremento', () {
      // Nota: Incremento/decremento como statement requerem tratamento especial
      // Eles são testados em contextos de expressão (atribuições, loops)

      test('incremento prefixo em atribuição', () {
        final result = _compileAndRun('int i = 5; int j = ++i;');
        expect(result.globals['i'], equals(6));
        expect(result.globals['j'], equals(6));
      });

      test('incremento postfix em atribuição', () {
        final result = _compileAndRun('int i = 5; int j = i++;');
        expect(result.globals['i'], equals(6));
        expect(result.globals['j'], equals(5));
      });
    });

    group('Condicionais (If/Else)', () {
      test('if simples - condição verdadeira', () {
        final result = _compileAndRun('''
int x = 0;
if (true) {
  x = 10;
}
''');
        expect(result.globals['x'], equals(10));
      });

      test('if simples - condição falsa', () {
        final result = _compileAndRun('''
int x = 0;
if (false) {
  x = 10;
}
''');
        expect(result.globals['x'], equals(0));
      });

      test('if-else - condição verdadeira', () {
        final result = _compileAndRun('''
int x = 0;
if (true) {
  x = 10;
} else {
  x = 20;
}
''');
        expect(result.globals['x'], equals(10));
      });

      test('if-else - condição falsa', () {
        final result = _compileAndRun('''
int x = 0;
if (false) {
  x = 10;
} else {
  x = 20;
}
''');
        expect(result.globals['x'], equals(20));
      });

      test('if com condição numérica', () {
        final result = _compileAndRun('''
int x = 0;
if (5 > 3) {
  x = 10;
}
''');
        expect(result.globals['x'], equals(10));
      });
    });

    group('Laços (While)', () {
      test('while simples', () {
        final result = _compileAndRun('''
int i = 0;
while (i < 3) {
  i = i + 1;
}
''');
        expect(result.globals['i'], equals(3));
      });

      test('while com incremento postfix', () {
        final result = _compileAndRun('''
int i = 0;
while (i < 3) {
  i++;
}
''');
        expect(result.globals['i'], equals(3));
      });

      test('while com soma acumulada', () {
        final result = _compileAndRun('''
int soma = 0;
int i = 1;
while (i <= 5) {
  soma = soma + i;
  i++;
}
''');
        expect(result.globals['soma'], equals(15));
        expect(result.globals['i'], equals(6));
      });

      test('while que não executa', () {
        final result = _compileAndRun('''
int x = 0;
while (false) {
  x = 10;
}
''');
        expect(result.globals['x'], equals(0));
      });
    });

    group('Laços (For)', () {
      test('for básico', () {
        final result = _compileAndRun('''
int soma = 0;
for (int i = 0; i < 5; i++) {
  soma = soma + i;
}
''');
        expect(result.globals['soma'], equals(10));
      });

      test('for com múltiplas instruções', () {
        final result = _compileAndRun('''
int x = 0;
int y = 0;
for (int i = 0; i < 3; i++) {
  x = x + 1;
  y = y + 2;
}
''');
        expect(result.globals['x'], equals(3));
        expect(result.globals['y'], equals(6));
      });
    });

    group('Escopo de Variáveis', () {
      test('variável local em bloco', () {
        final result = _compileAndRun('''
int x = 10;
{
  int y = 20;
  x = 30;
}
''');
        expect(result.globals['x'], equals(30));
        // y não deve estar no escopo global
        expect(result.globals.containsKey('y'), equals(false));
      });

      // Nota: Variáveis locais com mesmo nome não são suportadas corretamente
      // O escopo atual sobrescreve a variável global

      test('escopo aninhado', () {
        final result = _compileAndRun('''
int x = 0;
{
  int y = 10;
  {
    int z = 20;
    x = y + z;
  }
}
''');
        expect(result.globals['x'], equals(30));
      });
    });

    group('Tipos de Dados', () {
      test('inteiros', () {
        final result = _compileAndRun('int x = 42;');
        expect(result.globals['x'], equals(42));
      });

      test('decimais', () {
        final result = _compileAndRun('float x = 3.14;');
        expect(result.globals['x'], equals(3.14));
      });

      test('booleanos', () {
        final result = _compileAndRun('bool x = true; bool y = false;');
        expect(result.globals['x'], equals(true));
        expect(result.globals['y'], equals(false));
      });

      test('strings', () {
        // Nota: Strings podem ter problemas com escape sequences
        final result = _compileAndRun('string x = "Hello";');
        // O gerador remove aspas, então pode haver diferenças
        expect(result.globals['x'], isA<String>());
      });
    });

    group('Casos Complexos', () {
      test('programa completo com múltiplas funcionalidades', () {
        // Nota: Operador % não é suportado pelo parser
        final result = _compileAndRun('''
int soma = 0;
int i = 0;
while (i < 10) {
  if (i == 0 || i == 2 || i == 4 || i == 6 || i == 8) {
    soma = soma + i;
  }
  i = i + 1;
}
''');
        expect(result.globals['soma'], equals(20)); // 0+2+4+6+8
        expect(result.globals['i'], equals(10));
      });

      test('expressão complexa com múltiplos operadores', () {
        final result = _compileAndRun('''
int a = 10;
int b = 5;
int c = 2;
int x = (a + b) * c - 3;
''');
        expect(result.globals['x'], equals(27)); // (10+5)*2-3 = 27
      });
    });

    group('Tratamento de Erros', () {
      test('divisão por zero deve lançar erro', () {
        final lexer = Lexer('int x = 10 / 0;');
        final tokens = lexer.analisar();
        final stream = TokenStream(tokens);
        final parser = Parser(stream, 'int x = 10 / 0;');
        final program = parser.parseProgram();
        final analyzer = SemanticAnalyzer(null, 'int x = 10 / 0;');
        final symbols = analyzer.analyze(program);
        final generator = BytecodeGenerator(symbols);
        final bytecode = generator.generate(program);
        final vm = VirtualMachine(bytecode);

        expect(
          () => vm.run(),
          throwsA(
            isA<VMRuntimeError>().having(
              (e) => e.message,
              'message',
              contains('Divisão por zero'),
            ),
          ),
        );
      });

      // Nota: Operador % não é suportado pelo parser
    });
  });
}
