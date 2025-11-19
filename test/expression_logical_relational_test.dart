import 'package:test/test.dart';
import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/ast/ast.dart';

void main() {
  group('Parser - operadores lógicos/relacionais e parênteses', () {
    test('a = true && false || true -> (a && b) || c', () {
      final src = 'a = true && false || true;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();

      final stmt = program.statements.first as Assign;
      final top = stmt.value as Binary;
      expect(top.operator, equals('||'));
      expect(top.left, isA<Binary>());
      expect((top.left as Binary).operator, equals('&&'));
    });

    test('a = x < y + z -> relational uses additive on right', () {
      final src = 'a = x < y + z;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();

      final stmt = program.statements.first as Assign;
      final top = stmt.value as Binary;
      expect(top.operator, equals('<'));
      expect(top.right, isA<Binary>()); // y + z
    });

    test('a = (a || b) && c -> parentheses change binding', () {
      final src = 'a = (a || b) && c;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();

      final stmt = program.statements.first as Assign;
      final top = stmt.value as Binary;
      expect(top.operator, equals('&&'));
      expect(top.left, isA<Binary>());
      expect((top.left as Binary).operator, equals('||'));
    });

    test('a = 1 < 2 < 3 -> left associativity for relational', () {
      final src = 'a = 1 < 2 < 3;';
      final lexer = Lexer(src);
      final tokens = lexer.analisar();
      final parser = Parser(TokenStream(tokens), src);
      final program = parser.parseProgram();

      final stmt = program.statements.first as Assign;
      final top = stmt.value as Binary;
      expect(top.operator, equals('<'));
      expect(top.left, isA<Binary>());
      final left = top.left as Binary;
      expect(left.left, isA<Literal>());
      expect((left.left as Literal).lexeme, equals('1'));
      expect((left.right as Literal).lexeme, equals('2'));
      expect((top.right as Literal).lexeme, equals('3'));
    });
  });
}
