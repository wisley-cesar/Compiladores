part of 'package:compilador/ast/ast.dart';

class WhileStmt extends Stmt {
  final Expr condition;
  final Stmt body;
  final int linha;
  final int coluna;

  WhileStmt(this.condition, this.body, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitWhileStmt(this);
}
