part of 'package:compilador/ast/ast.dart';

class ExprStmt extends Stmt {
  final Expr expr;
  final int linha;
  final int coluna;

  ExprStmt(this.expr, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitExprStmt(this);
}
