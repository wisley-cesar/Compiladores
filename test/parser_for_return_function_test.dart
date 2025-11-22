import 'package:test/test.dart';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/sintatica/ast/ast.dart';

void main() {
  test('Parse for-loop, return and function declaration/call', () {
    final src = '''
int sum(int a, int b) {
  return a + b;
}

int main() {
  int s = 0;
  for (int i = 0; i < 10; i = i + 1) {
    s = sum(s, i);
  }
  return s;
}
''';

    final lexer = Lexer(src);
    final tokens = lexer.analisar();
    expect(lexer.listaErrosEstruturados, isEmpty);

    final parser = Parser(TokenStream(tokens), src);
    final program = parser.parseProgram();

    expect(parser.errors, isEmpty, reason: 'Não deve haver erros de parsing');

    final json = astToJson(program);
    final s = json.toString();
    expect(s, contains('FunctionDecl'));
    expect(s, contains('ForStmt'));
    expect(s, contains('ReturnStmt'));
    expect(s, contains('Call'));
  });
}
