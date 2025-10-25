abstract class AstNode {
  T accept<T>(AstVisitor<T> visitor);
}

/// Usamos `dynamic` nas assinaturas do visitor para evitar ciclos de import
/// entre os nós do AST (cada nó importa `node.dart`). Isso simplifica o
/// esqueleto inicial do parser/visitor. Podemos refinar os tipos mais tarde.
abstract class AstVisitor<T> {
  T visitProgram(dynamic node);
  T visitVarDecl(dynamic node);
  T visitLiteral(dynamic node);
  T visitIdentifier(dynamic node);
}
