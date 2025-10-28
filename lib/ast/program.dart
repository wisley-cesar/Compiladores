part of ast;

class Program extends AstNode {
  final List<Stmt> statements;
  Program(this.statements);

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitProgram(this);
}
