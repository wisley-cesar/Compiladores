part of 'package:compilador/ast/ast.dart';

class Unary extends Expr {
  final String operator;
  final Expr operand;
  final int linha;
  final int coluna;

  Unary(this.operator, this.operand, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitUnary(this);
}
