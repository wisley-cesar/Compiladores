import 'node.dart';
import 'expr.dart';

class Identifier extends Expr {
  final String name;
  Identifier(this.name);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitIdentifier(this);
}
