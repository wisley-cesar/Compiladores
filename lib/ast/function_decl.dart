part of 'package:compilador/ast/ast.dart';

class Param {
  final String type;
  final String name;
  Param(this.type, this.name);
}

class FunctionDecl extends Stmt {
  final List<String> modifiers; // e.g., ['public', 'static']
  final String returnType;
  final String name;
  final List<Param> params;
  final Block body;
  final int linha;
  final int coluna;

  FunctionDecl(
    this.modifiers,
    this.returnType,
    this.name,
    this.params,
    this.body,
    this.linha,
    this.coluna,
  );

  @override
  T accept<T>(AstVisitor<T> visitor) => visitor.visitFunctionDecl(this);
}
