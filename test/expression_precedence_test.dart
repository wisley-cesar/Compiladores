import 'package:test/test.dart';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/sintatica/ast/ast.dart';

void main() {
  group('Parser - precedência e associatividade de expressões', () {
    test('1 + 2 * 3 -> 1 + (2 * 3)', () {
      final src = 'a = 1 + 2 * 3;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();

      expect(program.statements, isNotEmpty);
      final stmt = program.statements.first as Assign;
      final top = stmt.value as Binary;
      expect(top.operator, equals('+'));

      // direita deve ser um Binary '*'
      expect(top.right, isA<Binary>());
      final right = top.right as Binary;
      expect(right.operator, equals('*'));
      expect((right.left as Literal).lexeme, equals('2'));
      expect((right.right as Literal).lexeme, equals('3'));
    });

    test('10 - 5 - 2 -> (10 - 5) - 2 (left associativity)', () {
      final src = 'a = 10 - 5 - 2;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();

      final stmt = program.statements.first as Assign;
      final top = stmt.value as Binary;
      expect(top.operator, equals('-'));

      // left should itself be a Binary (10 - 5)
      expect(top.left, isA<Binary>());
      final left = top.left as Binary;
      expect(left.operator, equals('-'));
      expect((left.left as Literal).lexeme, equals('10'));
      expect((left.right as Literal).lexeme, equals('5'));
      expect((top.right as Literal).lexeme, equals('2'));
    });

    test('-a * b -> ( -a ) * b', () {
      final src = 'a = -x * y;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();

      final stmt = program.statements.first as Assign;
      final top = stmt.value as Binary;
      expect(top.operator, equals('*'));

      expect(top.left, isA<Unary>());
      final unary = top.left as Unary;
      expect(unary.operator, equals('-'));
      expect((unary.operand as Identifier).name, equals('x'));
      expect((top.right as Identifier).name, equals('y'));
    });
  });
}
