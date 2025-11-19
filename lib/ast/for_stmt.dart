part of 'package:compilador/ast/ast.dart';

class ForStmt extends Stmt {
  final Stmt? init; // varDecl or exprStmt or null
  final Expr? condition;
  final Expr? update;
  final Stmt body;
  final int linha;
  final int coluna;

  ForStmt(
    this.init,
    this.condition,
    this.update,
    this.body,
    this.linha,
    this.coluna,
  );

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitFor(this);
}
