import 'package:compilador/ast/ast.dart';
import 'symbol_table.dart';
import 'semantic_error.dart';
import 'package:compilador/error_context.dart';

class SemanticAnalyzer {
  final SymbolTable symbols;
  final String src;
  final List<SemanticError> errors = [];
  final Set<String> _predeclared = {}; // names pre-registered in pre-scan
  final Map<String, FunctionDecl> _functions = {};
  final List<String?> _returnTypeStack = [];

  /// [src] é opcional; se fornecido, será usado para preencher `contexto` nos
  /// erros semânticos.
  SemanticAnalyzer([SymbolTable? table, this.src = ''])
    : symbols = table ?? SymbolTable();

  SymbolTable analyze(Program program) {
    // Pre-scan top-level statements and register variable declarations
    // to emulate Dart-like behavior for top-level declarations: allow
    // references to top-level symbols even if their declaration appears
    // later in the file. We only register the symbol name and the
    // declared type (if explicit). Initializers will be analyzed later.
    for (final s in program.statements) {
      if (s is VarDecl) {
        // Only pre-register variables with explicit types (not 'uids').
        // For 'uids' we keep the original behavior to allow inference and
        // to detect usage-before-declaration in initializers.
        if (s.keyword == 'uids') continue;

        try {
          String? declaredType;
          switch (s.keyword) {
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
          // If symbol already exists at any visible scope, report redeclaration
          if (symbols.lookup(s.name) != null) {
            errors.add(
              SemanticError(
                'Redeclaração da variável "${s.name}" no escopo global',
                simbolo: s.name,
                linha: s.linha,
                coluna: s.coluna,
                contexto: extractLineContext(src, s.linha),
              ),
            );
            continue;
          }
          symbols.add(s.name, type: declaredType, isMutable: true);
          _predeclared.add(s.name);
        } on StateError catch (e) {
          errors.add(
            SemanticError(
              e.message,
              simbolo: s.name,
              linha: s.linha,
              coluna: s.coluna,
              contexto: extractLineContext(src, s.linha),
            ),
          );
        }
      }
      if (s is FunctionDecl) {
        // Register top-level function signatures so calls/recursion resolve
        if (symbols.lookup(s.name) != null) {
          errors.add(
            SemanticError(
              'Redeclaração da função "${s.name}" no escopo global',
              simbolo: s.name,
              linha: s.linha,
              coluna: s.coluna,
              contexto: extractLineContext(src, s.linha),
            ),
          );
          continue;
        }
        // store function declaration for later signature checks
        _functions[s.name] = s;
        // encode function return type in the symbol table as 'fn:RET'
        symbols.add(s.name, type: 'fn:${s.returnType}', isMutable: false);
        _predeclared.add(s.name);
      }
    }

    // Now perform regular analysis (this will analyze initializers and
    // bodies, and detect local undeclared uses). This keeps local
    // declare-before-use semantics while being permissive for top-level.
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
    if (s is ForStmt) {
      _handleFor(s);
      return;
    }
    if (s is ReturnStmt) {
      _handleReturn(s);
      return;
    }
    if (s is FunctionDecl) {
      _handleFunctionDecl(s);
      return;
    }
    if (s is ExprStmt) {
      _handleExprStmt(s);
      return;
    }
    // other statements can be added here
  }

  void _handleExprStmt(ExprStmt s) {
    _inferType(s.expr);
  }

  void _handleFor(ForStmt f) {
    symbols.enterScope();
    if (f.init != null) {
      // init may be a VarDecl or ExprStmt
      if (f.init is VarDecl) {
        _handleVarDecl(f.init as VarDecl);
      } else if (f.init is ExprStmt) {
        _handleExprStmt(f.init as ExprStmt);
      }
    }
    if (f.condition != null) {
      final condType = _inferType(f.condition);
      if (condType != 'bool') {
        errors.add(
          SemanticError(
            'Condição de for deve ser booleano, encontrado $condType',
            linha: f.linha,
            coluna: f.coluna,
            contexto: extractLineContext(src, f.linha),
          ),
        );
      }
    }
    if (f.update != null) {
      _inferType(f.update);
    }
    _analyzeStmt(f.body);
    symbols.exitScope();
  }

  void _handleReturn(ReturnStmt r) {
    if (_returnTypeStack.isEmpty || _returnTypeStack.last == null) {
      errors.add(
        SemanticError(
          'Retorno fora de função',
          linha: r.linha,
          coluna: r.coluna,
          contexto: extractLineContext(src, r.linha),
        ),
      );
      return;
    }
    final expected = _returnTypeStack.last!;
    final got = r.value != null ? _inferType(r.value) : 'void';
    if (expected != 'void') {
      if (got == 'dynamic') return; // unable to infer, skip
      final allowed =
          (expected == got) || (expected == 'double' && got == 'int');
      if (!allowed) {
        errors.add(
          SemanticError(
            'Tipo de retorno incompatível: esperado $expected, encontrado $got',
            linha: r.linha,
            coluna: r.coluna,
            contexto: extractLineContext(src, r.linha),
          ),
        );
      }
    } else {
      // expected void but got a value
      if (got != 'void' && got != 'dynamic') {
        errors.add(
          SemanticError(
            'Função void não deve retornar um valor',
            linha: r.linha,
            coluna: r.coluna,
            contexto: extractLineContext(src, r.linha),
          ),
        );
      }
    }
  }

  void _handleFunctionDecl(FunctionDecl f) {
    // Function already registered in pre-scan for top-level cases; if it's
    // a nested declaration, check redeclaration in current scope.
    final existing = symbols.currentScopeLookup(f.name);
    if (existing != null && !_predeclared.contains(f.name)) {
      errors.add(
        SemanticError(
          'Redeclaração da função "${f.name}" no mesmo escopo',
          simbolo: f.name,
          linha: f.linha,
          coluna: f.coluna,
          contexto: extractLineContext(src, f.linha),
        ),
      );
      return;
    }

    // Register function for nested case if required
    if (existing == null) {
      try {
        symbols.add(f.name, type: 'fn:${f.returnType}', isMutable: false);
      } on StateError catch (e) {
        errors.add(
          SemanticError(
            e.message,
            simbolo: f.name,
            linha: f.linha,
            coluna: f.coluna,
            contexto: extractLineContext(src, f.linha),
          ),
        );
      }
    }

    // store declaration for signature checks
    _functions[f.name] = f;

    // Analyze body with new scope containing params
    symbols.enterScope();
    for (final p in f.params) {
      try {
        symbols.add(p.name, type: p.type, isMutable: false);
      } on StateError catch (e) {
        errors.add(
          SemanticError(
            'Redeclaração de parâmetro "${p.name}" em função "${f.name}"',
            simbolo: p.name,
            linha: f.linha,
            coluna: f.coluna,
            contexto: extractLineContext(src, f.linha),
          ),
        );
      }
    }
    // push expected return type
    _returnTypeStack.add(f.returnType);
    _analyzeStmt(f.body);
    _returnTypeStack.removeLast();
    symbols.exitScope();
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
    // If a symbol was pre-registered in the current scope (e.g., top-level
    // pre-scan), don't add it again — just validate initializer and update
    // inferred type when appropriate.
    final existing = symbols.currentScopeLookup(decl.name);

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
      case 'uids':
        declaredType = null;
        break;
      default:
        declaredType = null;
    }

    if (existing != null) {
      // If this existing symbol was not predeclared during pre-scan, then
      // it's a true redeclaration (e.g., two `uids x` in the same scope).
      if (!_predeclared.contains(decl.name)) {
        errors.add(
          SemanticError(
            'Redeclaração da variável "${decl.name}" no mesmo escopo',
            simbolo: decl.name,
            linha: decl.linha,
            coluna: decl.coluna,
            contexto: extractLineContext(src, decl.linha),
          ),
        );
        return;
      }
      // Validate initializer compatibility and update inferred type if needed
      if (decl.initializer != null) {
        final initType = _inferType(decl.initializer);
        final compatible =
            (declaredType == null) ||
            (initType == declaredType) ||
            (declaredType == 'double' && initType == 'int');
        if (!compatible) {
          errors.add(
            SemanticError(
              'Inicializador incompatível: declarado $declaredType, encontrado $initType',
              simbolo: decl.name,
              linha: decl.linha,
              coluna: decl.coluna,
              contexto: extractLineContext(src, decl.linha),
            ),
          );
        } else {
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
        // If symbol had no declared type (uids) and we inferred one, update it
        if (existing.type == null && initType != null) existing.type = initType;
        // If initializer absent and symbol still has no type, set to 'dynamic'
        if (existing.type == null && decl.initializer == null)
          existing.type = 'dynamic';
      }
      return;
    }

    // Otherwise behave as before and add the symbol to the current scope
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
              'Inicializador incompatível: declarado $declaredType, encontrado $initType',
              simbolo: decl.name,
              linha: decl.linha,
              coluna: decl.coluna,
              contexto: extractLineContext(src, decl.linha),
            ),
          );
        } else {
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
        // For 'uids' use the inferred type; otherwise use declaredType
        final toAddType = decl.keyword == 'uids'
            ? (initType ?? 'dynamic')
            : declaredType;
        symbols.add(decl.name, type: toAddType, isMutable: true);
      } else {
        final toAddType = decl.keyword == 'uids' ? 'dynamic' : declaredType;
        symbols.add(decl.name, type: toAddType, isMutable: true);
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
      // assignment as expression: check target and value
      if (op == '=') {
        // left should be identifier (simple case)
        if (expr.left is Identifier) {
          final id = expr.left as Identifier;
          final s = symbols.lookup(id.name);
          final rightType = _inferType(expr.right);
          if (s == null) {
            errors.add(
              SemanticError(
                'Atribuição para variável não declarada',
                simbolo: id.name,
                linha: expr.linha,
                coluna: expr.coluna,
                contexto: extractLineContext(src, expr.linha),
              ),
            );
            return 'dynamic';
          }
          final dest = s.type ?? 'dynamic';
          final srcType = rightType ?? 'dynamic';
          if (dest != 'dynamic' && srcType != 'dynamic') {
            final allowed =
                (dest == srcType) || (dest == 'double' && srcType == 'int');
            if (!allowed) {
              errors.add(
                SemanticError(
                  'Tipo incompatível na atribuição: esperado $dest, encontrado $srcType',
                  simbolo: id.name,
                  linha: expr.linha,
                  coluna: expr.coluna,
                  contexto: extractLineContext(src, expr.linha),
                ),
              );
            } else if (dest == 'double' && srcType == 'int') {
              errors.add(
                SemanticError(
                  'Coerção implícita int -> double na atribuição para "${id.name}"',
                  simbolo: id.name,
                  linha: expr.linha,
                  coluna: expr.coluna,
                  contexto: extractLineContext(src, expr.linha),
                  isWarning: true,
                ),
              );
            }
          }
          return dest;
        }
        // fallback: infer right side
        return _inferType(expr.right);
      }

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
    if (expr is Call) {
      // analyze arguments
      for (final a in expr.args) {
        _inferType(a);
      }
      // if callee is identifier, try to check signature
      if (expr.callee is Identifier) {
        final id = expr.callee as Identifier;
        final f = _functions[id.name];
        if (f == null) {
          // not a known function declaration; try symbol lookup
          final s = symbols.lookup(id.name);
          if (s == null) {
            errors.add(
              SemanticError(
                'Chamada para função não declarada "${id.name}"',
                simbolo: id.name,
                linha: expr.linha,
                coluna: expr.coluna,
                contexto: extractLineContext(src, expr.linha),
              ),
            );
            return 'dynamic';
          }
          // If symbol exists and encodes fn:RET, return return type
          if (s.type != null && s.type!.startsWith('fn:')) {
            return s.type!.substring(3);
          }
          // Otherwise allow as dynamic
          return s.type ?? 'dynamic';
        }
        // check arity
        if (f.params.length != expr.args.length) {
          errors.add(
            SemanticError(
              'Aridade incorreta na chamada de "${id.name}": esperado ${f.params.length}, encontrado ${expr.args.length}',
              simbolo: id.name,
              linha: expr.linha,
              coluna: expr.coluna,
              contexto: extractLineContext(src, expr.linha),
            ),
          );
        } else {
          // check argument types vs params
          for (var i = 0; i < expr.args.length && i < f.params.length; i++) {
            final at = _inferType(expr.args[i]);
            final pt = f.params[i].type;
            if (at == 'dynamic') continue;
            final allowed = (pt == at) || (pt == 'double' && at == 'int');
            if (!allowed) {
              errors.add(
                SemanticError(
                  'Tipo de argumento incompatível na chamada de "${id.name}" para parâmetro ${f.params[i].name}: esperado $pt, encontrado $at',
                  simbolo: id.name,
                  linha: expr.linha,
                  coluna: expr.coluna,
                  contexto: extractLineContext(src, expr.linha),
                ),
              );
            }
          }
        }
        return f.returnType;
      }
      return 'dynamic';
    }
    return 'dynamic';
  }
}
