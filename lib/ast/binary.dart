import 'expr.dart';

class Binary extends Expr {
  final Expr left;
  final String operator;
  final Expr right;

  Binary(this.left, this.operator, this.right);

  @override
  T accept<T>(visitor) => visitor.visitLiteral(this); // visitor dynamic; not used in current flow
}
