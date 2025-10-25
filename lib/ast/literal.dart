import 'node.dart';
import 'expr.dart';

class Literal extends Expr {
  final String lexeme;
  final String kind; // 'int', 'double', 'string', 'bool'

  Literal(this.lexeme, this.kind);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitLiteral(this);
}
