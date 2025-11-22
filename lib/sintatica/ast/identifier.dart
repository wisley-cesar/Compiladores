part of 'package:compilador/sintatica/ast/ast.dart';

class Identifier extends Expr {
  final String name;
  final int linha;
  final int coluna;

  Identifier(this.name, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitIdentifier(this);
}
