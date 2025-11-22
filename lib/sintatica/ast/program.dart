part of 'package:compilador/sintatica/ast/ast.dart';

class Program extends AstNode {
  final List<Stmt> statements;
  Program(this.statements);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitProgram(this);
}
