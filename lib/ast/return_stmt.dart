part of ast;

class ReturnStmt extends Stmt {
  final Expr? value;
  final int linha;
  final int coluna;

  ReturnStmt(this.value, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitReturn(this);
}
