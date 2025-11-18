part of 'package:compilador/ast/ast.dart';

class Binary extends Expr {
  final Expr left;
  final String operator;
  final Expr right;
  final int linha;
  final int coluna;

  Binary(this.left, this.operator, this.right, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitBinary(this);
}
