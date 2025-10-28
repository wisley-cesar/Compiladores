part of ast;

class Literal extends Expr {
  final String lexeme;
  final String kind; // 'int', 'double', 'string', 'bool'
  final int linha;
  final int coluna;

  Literal(this.lexeme, this.kind, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitLiteral(this);
}
