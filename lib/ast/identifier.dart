part of ast;

class Identifier extends Expr {
  final String name;
  final int linha;
  final int coluna;

  Identifier(this.name, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitIdentifier(this);
}
