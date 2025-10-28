part of ast;

class VarDecl extends Stmt {
  final String keyword; // e.g., 'uids' or other
  final String name;
  final Expr? initializer;
  final int linha;
  final int coluna;

  VarDecl(this.keyword, this.name, this.initializer, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitVarDecl(this);
}

