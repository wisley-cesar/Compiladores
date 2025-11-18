part of 'package:compilador/ast/ast.dart';

class Block extends Stmt {
  final List<Stmt> statements;
  final int linha;
  final int coluna;

  Block(this.statements, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitBlock(this);
}
