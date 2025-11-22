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
  expect(lexer.listaErrosEstruturados, isEmpty,
      reason: 'Erros léxicos não eram esperados');

  final stream = TokenStream(tokens);
  final parser = Parser(stream, src);
  final program = parser.parseProgram();
  expect(parser.errors, isEmpty, reason: 'Erros de parse não eram esperados');

  final analyzer = SemanticAnalyzer(null, src);
  final symbols = analyzer.analyze(program);
  expect(analyzer.errors.where((e) => !e.isWarning), isEmpty,
      reason: 'Erros semânticos não eram esperados');

  final generator = BytecodeGenerator(symbols);
  final bytecode = generator.generate(program);
  expect(generator.errors, isEmpty,
      reason: 'Erros na geração de bytecode não eram esperados');

  final vm = VirtualMachine(bytecode);
  return vm.run();
}

void main() {
  group('VirtualMachine', () {
    test('executa atribuições e aritmética simples', () {
      final result = _compileAndRun('''
int x = 1;
x = x + 2;
''');

      expect(result.globals['x'], equals(3));
    });

    test('executa while com incremento postfix', () {
      final result = _compileAndRun('''
int i = 0;
while (i < 3) {
  i++;
}
''');

      expect(result.globals['i'], equals(3));
    });
  });
}
