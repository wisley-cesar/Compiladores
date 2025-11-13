import 'package:compilador/ast/ast.dart';
import 'symbol_table.dart';
import 'semantic_error.dart';
import 'package:compilador/error_context.dart';

class SemanticAnalyzer {
  final SymbolTable symbols;
  final String src;
  final List<SemanticError> errors = [];

  /// [src] é opcional; se fornecido, será usado para preencher `contexto` nos
  /// erros semânticos.
  SemanticAnalyzer([SymbolTable? table, this.src = '']) : symbols = table ?? SymbolTable();

  SymbolTable analyze(Program program) {
    for (final s in program.statements) {
      if (s is VarDecl) {
        _handleVarDecl(s);
      }
    }
    return symbols;
  }

  void _handleVarDecl(VarDecl decl) {
    if (decl.keyword == 'uids') {
      final inferred = _inferType(decl.initializer);
      try {
        symbols.add(decl.name, type: inferred, isMutable: true);
      } on StateError catch (e) {
        errors.add(SemanticError(e.message, simbolo: decl.name, linha: decl.linha, coluna: decl.coluna, contexto: extractLineContext(src, decl.linha)));
      }
    } else {
      // other kinds not handled yet
      try {
        symbols.add(decl.name, type: null, isMutable: true);
      } on StateError catch (e) {
        errors.add(SemanticError(e.message, simbolo: decl.name, linha: decl.linha, coluna: decl.coluna, contexto: extractLineContext(src, decl.linha)));
      }
    }
  }

  String? _inferType(Expr? expr) {
    if (expr == null) return 'dynamic';
    if (expr is Literal) return expr.kind;
    if (expr is Identifier) {
      final s = symbols.lookup(expr.name);
      if (s == null) {
        errors.add(SemanticError('Uso de variável antes da declaração', simbolo: expr.name, linha: expr.linha, coluna: expr.coluna, contexto: extractLineContext(src, expr.linha)));
        return 'dynamic';
      }
      return s.type ?? 'dynamic';
    }
    if (expr is Unary) {
      final opType = _inferType(expr.operand);
      return opType ?? 'dynamic';
    }
    if (expr is Binary) {
      final left = _inferType(expr.left);
      final right = _inferType(expr.right);
      if (left == null || right == null) return 'dynamic';
      // divisão sempre produz double
      if (expr.operator == '/') return 'double';
      if (left == 'double' || right == 'double') return 'double';
      if (left == 'int' && right == 'int') return 'int';
      // fallback
      return 'dynamic';
    }
    return 'dynamic';
  }
}
