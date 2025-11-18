part of 'package:compilador/ast/ast.dart';

class Call extends Expr {
  final Expr callee; // usually Identifier
  final List<Expr> args;
  final int linha;
  final int coluna;

  Call(this.callee, this.args, this.linha, this.coluna);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitCall(this);
}
