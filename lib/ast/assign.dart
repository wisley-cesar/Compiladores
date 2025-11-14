part of ast;

class Assign extends Stmt {
  final Identifier target;
  final Expr value;
  final int linha;
  final int coluna;

  Assign(this.target, this.value, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitAssign(this);
}
