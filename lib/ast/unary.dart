import 'expr.dart';

class Unary extends Expr {
  final String operator;
  final Expr operand;

  Unary(this.operator, this.operand);

  @override
  T accept<T>(visitor) => visitor.visitLiteral(this);
}
