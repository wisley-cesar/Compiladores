part of 'package:compilador/sintatica/ast/ast.dart';

class IfStmt extends Stmt {
  final Expr condition;
  final Stmt thenBranch;
  final Stmt? elseBranch;
  final int linha;
  final int coluna;

  IfStmt(
    this.condition,
    this.thenBranch,
    this.elseBranch,
    this.linha,
    this.coluna,
  );

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitIfStmt(this);
}
