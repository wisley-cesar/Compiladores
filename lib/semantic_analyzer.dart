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
  SemanticAnalyzer([SymbolTable? table, this.src = ''])
    : symbols = table ?? SymbolTable();

  SymbolTable analyze(Program program) {
    for (final s in program.statements) {
      _analyzeStmt(s);
    }
    return symbols;
  }

  void _analyzeStmt(Stmt s) {
    if (s is VarDecl) {
      _handleVarDecl(s);
      return;
    }
    if (s is Assign) {
      _handleAssign(s);
      return;
    }
    if (s is IfStmt) {
      _handleIf(s);
      return;
    }
    if (s is WhileStmt) {
      _handleWhile(s);
      return;
    }
    if (s is Block) {
      _handleBlock(s);
      return;
    }
    // other statements can be added here
  }

  void _handleAssign(Assign a) {
    final name = a.target.name;
    final sym = symbols.lookup(name);
    if (sym == null) {
      errors.add(
        SemanticError(
          'Atribuição para variável não declarada',
          simbolo: name,
          linha: a.linha,
          coluna: a.coluna,
          contexto: extractLineContext(src, a.linha),
        ),
      );
      return;
    }
    final valueType = _inferType(a.value);
    if (sym.type != null && valueType != null && valueType != 'dynamic') {
      final dest = sym.type!;
      final srcType = valueType;
      final allowed =
          (dest == srcType) || (dest == 'double' && srcType == 'int');
      if (!allowed) {
        errors.add(
          SemanticError(
            'Tipo incompatível na atribuição: esperado ${sym.type}, encontrado $valueType',
            simbolo: name,
            linha: a.linha,
            coluna: a.coluna,
            contexto: extractLineContext(src, a.linha),
          ),
        );
      } else {
        // se a atribuição depender de coerção implícita int -> double, emite aviso
        if (dest == 'double' && srcType == 'int') {
          errors.add(
            SemanticError(
              'Coerção implícita int -> double na atribuição para "$name"',
              simbolo: name,
              linha: a.linha,
              coluna: a.coluna,
              contexto: extractLineContext(src, a.linha),
              isWarning: true,
            ),
          );
        }
      }
    }
  }

  void _handleIf(IfStmt ifs) {
    final condType = _inferType(ifs.condition);
    if (condType != 'bool') {
      errors.add(
        SemanticError(
          'Condição de if deve ser booleano, encontrado $condType',
          linha: ifs.linha,
          coluna: ifs.coluna,
          contexto: extractLineContext(src, ifs.linha),
        ),
      );
    }
    _analyzeStmt(ifs.thenBranch);
    if (ifs.elseBranch != null) _analyzeStmt(ifs.elseBranch!);
  }

  void _handleWhile(WhileStmt w) {
    final condType = _inferType(w.condition);
    if (condType != 'bool') {
      errors.add(
        SemanticError(
          'Condição de while deve ser booleano, encontrado $condType',
          linha: w.linha,
          coluna: w.coluna,
          contexto: extractLineContext(src, w.linha),
        ),
      );
    }
    _analyzeStmt(w.body);
  }

  void _handleBlock(Block b) {
    symbols.enterScope();
    for (final s in b.statements) {
      _analyzeStmt(s);
    }
    symbols.exitScope();
  }

  void _handleVarDecl(VarDecl decl) {
    if (decl.keyword == 'uids') {
      final inferred = _inferType(decl.initializer);
      try {
        symbols.add(decl.name, type: inferred, isMutable: true);
      } on StateError catch (e) {
        errors.add(
          SemanticError(
            e.message,
            simbolo: decl.name,
            linha: decl.linha,
            coluna: decl.coluna,
            contexto: extractLineContext(src, decl.linha),
          ),
        );
      }
      return;
    }

    // Map declaration keyword to an explicit language type
    String? declaredType;
    switch (decl.keyword) {
      case 'int':
        declaredType = 'int';
        break;
      case 'float':
        declaredType = 'double';
        break;
      case 'bool':
        declaredType = 'bool';
        break;
      case 'string':
        declaredType = 'string';
        break;
      default:
        declaredType = null;
    }

    try {
      if (decl.initializer != null) {
        final initType = _inferType(decl.initializer);
        final compatible =
            (declaredType == null) ||
            (initType == declaredType) ||
            (declaredType == 'double' && initType == 'int');
        if (!compatible) {
          errors.add(
            SemanticError(
              'Inicializador incompatível: declarado ${declaredType}, encontrado ${initType}',
              simbolo: decl.name,
              linha: decl.linha,
              coluna: decl.coluna,
              contexto: extractLineContext(src, decl.linha),
            ),
          );
        } else {
          // aviso para coerção implícita int -> double no inicializador
          if (declaredType == 'double' && initType == 'int') {
            errors.add(
              SemanticError(
                'Coerção implícita int -> double no inicializador da variável "${decl.name}"',
                simbolo: decl.name,
                linha: decl.linha,
                coluna: decl.coluna,
                contexto: extractLineContext(src, decl.linha),
                isWarning: true,
              ),
            );
          }
        }
        symbols.add(decl.name, type: declaredType, isMutable: true);
      } else {
        symbols.add(decl.name, type: declaredType, isMutable: true);
      }
    } on StateError catch (e) {
      errors.add(
        SemanticError(
          e.message,
          simbolo: decl.name,
          linha: decl.linha,
          coluna: decl.coluna,
          contexto: extractLineContext(src, decl.linha),
        ),
      );
    }
  }

  String? _inferType(Expr? expr) {
    if (expr == null) return 'dynamic';
    if (expr is Literal) return expr.kind;
    if (expr is Identifier) {
      final s = symbols.lookup(expr.name);
      if (s == null) {
        errors.add(
          SemanticError(
            'Uso de variável antes da declaração',
            simbolo: expr.name,
            linha: expr.linha,
            coluna: expr.coluna,
            contexto: extractLineContext(src, expr.linha),
          ),
        );
        return 'dynamic';
      }
      return s.type ?? 'dynamic';
    }
    if (expr is Unary) {
      final op = expr.operator;
      final operandType = _inferType(expr.operand);
      if (op == '!') {
        return 'bool';
      }
      // unary + / - preserve numeric type
      if (op == '+' || op == '-') {
        if (operandType == 'double') return 'double';
        if (operandType == 'int') return 'int';
        return 'dynamic';
      }
      return operandType ?? 'dynamic';
    }
    if (expr is Binary) {
      final left = _inferType(expr.left);
      final right = _inferType(expr.right);
      if (left == null || right == null) return 'dynamic';
      final op = expr.operator;
      // logical operators -> bool
      if (op == '&&' || op == '||') return 'bool';
      // equality and relational operators -> bool
      if (op == '==' ||
          op == '!=' ||
          op == '<' ||
          op == '>' ||
          op == '<=' ||
          op == '>=') {
        return 'bool';
      }
      // arithmetic
      if (op == '/') return 'double';
      if (left == 'double' || right == 'double') return 'double';
      if (left == 'int' && right == 'int') return 'int';
      return 'dynamic';
    }
    return 'dynamic';
  }
}
