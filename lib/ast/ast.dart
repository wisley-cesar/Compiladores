library ast;

part 'node.dart';
part 'program.dart';
part 'stmt.dart';
part 'var_decl.dart';
part 'assign.dart';
part 'if_stmt.dart';
part 'while_stmt.dart';
part 'block.dart';
part 'expr.dart';
part 'literal.dart';
part 'identifier.dart';
part 'binary.dart';
part 'unary.dart';

/// Visitor tipado para os nós do AST
abstract class AstVisitor<T> {
  T visitProgram(Program node);
  T visitVarDecl(VarDecl node);
  T visitAssign(Assign node);
  T visitIfStmt(IfStmt node);
  T visitWhileStmt(WhileStmt node);
  T visitBlock(Block node);
  T visitLiteral(Literal node);
  T visitIdentifier(Identifier node);
  T visitBinary(Binary node);
  T visitUnary(Unary node);
}

/// Nó base do AST
abstract class AstNode {
  T accept<T>(AstVisitor<T> visitor);
}

/// Serializa um nó AST (e seus filhos) para um Map que pode ser convertido em JSON.
Map<String, dynamic> astToJson(AstNode node) {
  if (node is Program) {
    return {
      'type': 'Program',
      'statements': node.statements.map((s) => astToJson(s)).toList(),
    };
  }
  if (node is VarDecl) {
    return {
      'type': 'VarDecl',
      'keyword': node.keyword,
      'name': node.name,
      'initializer': node.initializer != null
          ? astToJson(node.initializer!)
          : null,
      'linha': node.linha,
      'coluna': node.coluna,
    };
  }
  if (node is Assign) {
    return {
      'type': 'Assign',
      'target': astToJson(node.target),
      'value': astToJson(node.value),
      'linha': node.linha,
      'coluna': node.coluna,
    };
  }
  if (node is IfStmt) {
    return {
      'type': 'IfStmt',
      'condition': astToJson(node.condition),
      'then': astToJson(node.thenBranch),
      'else': node.elseBranch != null ? astToJson(node.elseBranch!) : null,
      'linha': node.linha,
      'coluna': node.coluna,
    };
  }
  if (node is WhileStmt) {
    return {
      'type': 'WhileStmt',
      'condition': astToJson(node.condition),
      'body': astToJson(node.body),
      'linha': node.linha,
      'coluna': node.coluna,
    };
  }
  if (node is Block) {
    return {
      'type': 'Block',
      'statements': node.statements.map((s) => astToJson(s)).toList(),
      'linha': node.linha,
      'coluna': node.coluna,
    };
  }
  if (node is Literal) {
    return {
      'type': 'Literal',
      'lexeme': node.lexeme,
      'kind': node.kind,
      'linha': node.linha,
      'coluna': node.coluna,
    };
  }
  if (node is Identifier) {
    return {
      'type': 'Identifier',
      'name': node.name,
      'linha': node.linha,
      'coluna': node.coluna,
    };
  }
  if (node is Binary) {
    return {
      'type': 'Binary',
      'operator': node.operator,
      'left': astToJson(node.left),
      'right': astToJson(node.right),
      'linha': node.linha,
      'coluna': node.coluna,
    };
  }
  if (node is Unary) {
    return {
      'type': 'Unary',
      'operator': node.operator,
      'operand': astToJson(node.operand),
      'linha': node.linha,
      'coluna': node.coluna,
    };
  }
  // fallback: return a minimal representation
  return {'type': 'Unknown', 'class': node.runtimeType.toString()};
}
