import 'ast/program.dart';
import 'ast/var_decl.dart';
import 'ast/literal.dart';
import 'ast/identifier.dart';
import 'ast/expr.dart';
import 'ast/binary.dart';
import 'ast/unary.dart';
import 'symbol_table.dart';

class SemanticAnalyzer {
  final SymbolTable symbols;

  SemanticAnalyzer([SymbolTable? table]) : symbols = table ?? SymbolTable();

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
      symbols.add(decl.name, type: inferred, isMutable: true);
    } else {
      // other kinds not handled yet
      symbols.add(decl.name, type: null, isMutable: true);
    }
  }

  String? _inferType(Expr? expr) {
    if (expr == null) return 'dynamic';
    if (expr is Literal) return expr.kind;
    if (expr is Identifier) {
      final s = symbols.lookup(expr.name);
      return s?.type ?? 'dynamic';
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
