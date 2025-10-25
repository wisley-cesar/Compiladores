import 'node.dart';
import 'stmt.dart';
import 'expr.dart';

class VarDecl extends Stmt {
  final String keyword; // e.g., 'uids' or other
  final String name;
  final Expr? initializer;

  VarDecl(this.keyword, this.name, this.initializer);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitVarDecl(this);
}
