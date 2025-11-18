import 'package:compilador/ast/ast.dart';
import 'package:compilador/bytecode.dart';
import 'package:compilador/symbol_table.dart';
import 'package:compilador/semantic_error.dart';

/// Gerador de bytecode a partir de uma AST
/// Implementa o padrão Visitor para percorrer a árvore sintática
/// e gerar código de máquina virtual (bytecode)
class BytecodeGenerator implements AstVisitor<void> {
  final SymbolTable symbolTable;
  final BytecodeProgram program = BytecodeProgram();
  final Map<String, int> _labelCounter = {};
  final List<ScopeFrame> _scopeStack = [];
  final List<SemanticError> _errors = [];

  BytecodeGenerator(this.symbolTable) {
    // Inicializa escopo global
    _scopeStack.add(ScopeFrame());
  }

  List<SemanticError> get errors => _errors;

  /// Gera bytecode para um programa completo
  BytecodeProgram generate(Program program) {
    this.program.instructions.clear();
    this.program.labels.clear();

    for (final stmt in program.statements) {
      stmt.accept(this);
    }

    this.program.add(BytecodeInstruction(Opcode.halt));
    return this.program;
  }

  // ============================================================================
  // Statements
  // ============================================================================

  @override
  void visitProgram(Program node) {
    for (final stmt in node.statements) {
      stmt.accept(this);
    }
  }

  @override
  void visitVarDecl(VarDecl node) {
    // Verifica se a variável já foi declarada no escopo atual
    final existing = symbolTable.currentScopeLookup(node.name);
    if (existing == null) {
      // Se não existe, adiciona ao escopo atual na tabela de símbolos
      // (isso já deve ter sido feito pelo semantic analyzer, mas verificamos)
      try {
        symbolTable.add(node.name, type: _inferType(node.initializer));
      } catch (e) {
        _errors.add(SemanticError(
          'Erro ao declarar variável "${node.name}": $e',
          simbolo: node.name,
          linha: node.linha,
          coluna: node.coluna,
        ));
        return;
      }
    }

    // Marca variável como declarada no escopo atual
    _scopeStack.last.declaredVars.add(node.name);

    // Se há inicializador, avalia e armazena
    if (node.initializer != null) {
      node.initializer!.accept(this); // Avalia expressão e coloca resultado na pilha
      program.add(BytecodeInstruction(Opcode.storeVar, node.name));
    } else {
      // Inicializa com valor padrão baseado no tipo
      final symbol = symbolTable.lookup(node.name);
      if (symbol?.type == 'int') {
        program.add(BytecodeInstruction(Opcode.pushInt, 0));
      } else if (symbol?.type == 'double') {
        program.add(BytecodeInstruction(Opcode.pushDouble, 0.0));
      } else if (symbol?.type == 'bool') {
        program.add(BytecodeInstruction(Opcode.pushBool, false));
      } else if (symbol?.type == 'string') {
        program.add(BytecodeInstruction(Opcode.pushString, ''));
      } else {
        program.add(BytecodeInstruction(Opcode.pushNull));
      }
      program.add(BytecodeInstruction(Opcode.storeVar, node.name));
    }
  }

  @override
  void visitAssign(Assign node) {
    // Verifica se a variável existe
    final symbol = symbolTable.lookup(node.target.name);
    if (symbol == null) {
      _errors.add(SemanticError(
        'Atribuição para variável não declarada "${node.target.name}"',
        simbolo: node.target.name,
        linha: node.linha,
        coluna: node.coluna,
      ));
      return;
    }

    // Avalia valor e armazena
    node.value.accept(this);
    program.add(BytecodeInstruction(Opcode.storeVar, node.target.name));
  }

  @override
  void visitIfStmt(IfStmt node) {
    final elseLabel = _newLabel('else');
    final endLabel = _newLabel('endif');

    // Avalia condição
    node.condition.accept(this);

    // Salta para else se falso
    program.add(BytecodeInstruction(Opcode.jumpIfFalse, elseLabel));

    // Bloco then
    node.thenBranch.accept(this);

    if (node.elseBranch != null) {
      // Salta para o fim (para pular o else)
      program.add(BytecodeInstruction(Opcode.jump, endLabel));
      program.addLabel(elseLabel);
      node.elseBranch!.accept(this);
      program.addLabel(endLabel);
    } else {
      program.addLabel(elseLabel);
    }
  }

  @override
  void visitWhileStmt(WhileStmt node) {
    final loopStart = _newLabel('loop_start');
    final loopEnd = _newLabel('loop_end');

    program.addLabel(loopStart);

    // Avalia condição
    node.condition.accept(this);

    // Salta para o fim se falso
    program.add(BytecodeInstruction(Opcode.jumpIfFalse, loopEnd));

    // Corpo do loop
    node.body.accept(this);

    // Salta de volta para o início
    program.add(BytecodeInstruction(Opcode.jump, loopStart));

    program.addLabel(loopEnd);
  }

  @override
  void visitFor(ForStmt node) {
    // Entra em novo escopo para a variável do loop
    _scopeStack.add(ScopeFrame());
    program.add(BytecodeInstruction(Opcode.enterScope));

    // Inicialização (se houver)
    if (node.init != null) {
      node.init!.accept(this);
    }

    final loopStart = _newLabel('for_start');
    final loopEnd = _newLabel('for_end');
    final loopContinue = _newLabel('for_continue');

    program.addLabel(loopStart);

    // Condição (se houver)
    if (node.condition != null) {
      node.condition!.accept(this);
      program.add(BytecodeInstruction(Opcode.jumpIfFalse, loopEnd));
    }

    // Corpo do loop
    node.body.accept(this);

    program.addLabel(loopContinue);

    // Update (se houver)
    if (node.update != null) {
      node.update!.accept(this);
      program.add(BytecodeInstruction(Opcode.pop)); // Descarta resultado do update
    }

    // Volta para o início
    program.add(BytecodeInstruction(Opcode.jump, loopStart));

    program.addLabel(loopEnd);

    // Sai do escopo
    program.add(BytecodeInstruction(Opcode.exitScope));
    _scopeStack.removeLast();
  }

  @override
  void visitBlock(Block node) {
    _scopeStack.add(ScopeFrame());
    program.add(BytecodeInstruction(Opcode.enterScope));

    for (final stmt in node.statements) {
      stmt.accept(this);
    }

    program.add(BytecodeInstruction(Opcode.exitScope));
    _scopeStack.removeLast();
  }

  @override
  void visitReturn(ReturnStmt node) {
    if (node.value != null) {
      node.value!.accept(this);
    } else {
      program.add(BytecodeInstruction(Opcode.pushNull));
    }
    program.add(BytecodeInstruction(Opcode.return_));
  }

  @override
  void visitFunctionDecl(FunctionDecl node) {
    // Nota: Implementação básica de função
    // Em uma implementação completa, seria necessário guardar o endereço
    // de retorno e gerenciar a pilha de chamadas

    final funcLabel = _newLabel('func_${node.name}');
    program.addLabel(funcLabel);

    _scopeStack.add(ScopeFrame());
    program.add(BytecodeInstruction(Opcode.enterScope));

    // Adiciona parâmetros ao escopo
    for (final param in node.params) {
      _scopeStack.last.declaredVars.add(param.name);
    }

    node.body.accept(this);

    program.add(BytecodeInstruction(Opcode.exitScope));
    _scopeStack.removeLast();
  }

  @override
  void visitCall(Call node) {
    // Verifica se a função existe
    final callee = node.callee;
    if (callee is! Identifier) {
      _errors.add(SemanticError(
        'Callee deve ser um identificador',
        linha: node.linha,
        coluna: node.coluna,
      ));
      return;
    }

    final funcName = callee.name;
    final symbol = symbolTable.lookup(funcName);
    if (symbol == null) {
      _errors.add(SemanticError(
        'Chamada para função não declarada "$funcName"',
        simbolo: funcName,
        linha: node.linha,
        coluna: node.coluna,
      ));
      return;
    }

    // Avalia argumentos (em ordem)
    for (final arg in node.args) {
      arg.accept(this);
    }

    // Chama função
    program.add(BytecodeInstruction(Opcode.call, {
      'name': funcName,
      'argCount': node.args.length,
    }));
  }

  @override
  void visitExprStmt(ExprStmt node) {
    node.expr.accept(this);
    // Descarta resultado da expressão
    program.add(BytecodeInstruction(Opcode.pop));
  }

  // ============================================================================
  // Expressions
  // ============================================================================

  @override
  void visitLiteral(Literal node) {
    switch (node.kind) {
      case 'int':
        program.add(BytecodeInstruction(
            Opcode.pushInt, int.tryParse(node.lexeme) ?? 0));
        break;
      case 'double':
        program.add(BytecodeInstruction(
            Opcode.pushDouble, double.tryParse(node.lexeme) ?? 0.0));
        break;
      case 'bool':
        program.add(BytecodeInstruction(
            Opcode.pushBool, node.lexeme == 'true'));
        break;
      case 'string':
        // Remove aspas do início e fim
        final value = node.lexeme.length >= 2
            ? node.lexeme.substring(1, node.lexeme.length - 1)
            : node.lexeme;
        program.add(BytecodeInstruction(Opcode.pushString, value));
        break;
      default:
        program.add(BytecodeInstruction(Opcode.pushNull));
    }
  }

  @override
  void visitIdentifier(Identifier node) {
    // Verifica se a variável existe
    final symbol = symbolTable.lookup(node.name);
    if (symbol == null) {
      _errors.add(SemanticError(
        'Uso de variável não declarada "${node.name}"',
        simbolo: node.name,
        linha: node.linha,
        coluna: node.coluna,
      ));
      // Carrega valor padrão para continuar
      program.add(BytecodeInstruction(Opcode.pushNull));
      return;
    }

    // Carrega variável na pilha
    program.add(BytecodeInstruction(Opcode.loadVar, node.name));
  }

  @override
  void visitBinary(Binary node) {
    final op = node.operator;

    // Tratamento especial para atribuição com operadores compostos
    if (op == '=') {
      // Atribuição simples
      if (node.left is Identifier) {
        final id = node.left as Identifier;
        final symbol = symbolTable.lookup(id.name);
        if (symbol == null) {
          _errors.add(SemanticError(
            'Atribuição para variável não declarada "${id.name}"',
            simbolo: id.name,
            linha: node.linha,
            coluna: node.coluna,
          ));
          return;
        }
        node.right.accept(this);
        program.add(BytecodeInstruction(Opcode.storeVar, id.name));
        // Retorna valor armazenado na pilha (para permitir atribuições encadeadas)
      } else {
        // Atribuição complexa não suportada no momento
        _errors.add(SemanticError(
          'Lado esquerdo de atribuição deve ser identificador',
          linha: node.linha,
          coluna: node.coluna,
        ));
      }
      return;
    }

    // Operadores de atribuição composta
    if (op == '+=' || op == '-=' || op == '*=' || op == '/=') {
      if (node.left is Identifier) {
        final id = node.left as Identifier;
        final symbol = symbolTable.lookup(id.name);
        if (symbol == null) {
          _errors.add(SemanticError(
            'Atribuição para variável não declarada "${id.name}"',
            simbolo: id.name,
            linha: node.linha,
            coluna: node.coluna,
          ));
          return;
        }

        // Carrega valor atual da variável
        program.add(BytecodeInstruction(Opcode.loadVar, id.name));
        // Avalia expressão à direita
        node.right.accept(this);

        // Aplica operação correspondente
        final baseOp = op.substring(0, op.length - 1);
        _emitArithmeticOp(baseOp);

        // Armazena resultado
        program.add(BytecodeInstruction(Opcode.storeVar, id.name));
      } else {
        _errors.add(SemanticError(
          'Lado esquerdo de atribuição deve ser identificador',
          linha: node.linha,
          coluna: node.coluna,
        ));
      }
      return;
    }

    // Operações binárias normais
    node.left.accept(this);
    node.right.accept(this);

    // Operadores aritméticos
    if (op == '+' || op == '-' || op == '*' || op == '/' || op == '%') {
      _emitArithmeticOp(op);
    }
    // Operadores lógicos
    else if (op == '&&') {
      program.add(BytecodeInstruction(Opcode.and));
    } else if (op == '||') {
      program.add(BytecodeInstruction(Opcode.or));
    }
    // Operadores de comparação
    else if (op == '==') {
      program.add(BytecodeInstruction(Opcode.eq));
    } else if (op == '!=') {
      program.add(BytecodeInstruction(Opcode.ne));
    } else if (op == '<') {
      program.add(BytecodeInstruction(Opcode.lt));
    } else if (op == '<=') {
      program.add(BytecodeInstruction(Opcode.le));
    } else if (op == '>') {
      program.add(BytecodeInstruction(Opcode.gt));
    } else if (op == '>=') {
      program.add(BytecodeInstruction(Opcode.ge));
    }
  }

  @override
  void visitUnary(Unary node) {
    final op = node.operator;

    // Tratamento especial para incremento/decremento
    final isPostfix = op == '++post' || op == '--post';
    final isPrefix = op == '++' || op == '--';
    
    if (isPrefix || isPostfix) {
      if (node.operand is Identifier) {
        final id = node.operand as Identifier;
        final symbol = symbolTable.lookup(id.name);
        if (symbol == null) {
          _errors.add(SemanticError(
            'Operador ${op} aplicado a variável não declarada "${id.name}"',
            simbolo: id.name,
            linha: node.linha,
            coluna: node.coluna,
          ));
          return;
        }

        if (symbol.type != 'int' && symbol.type != 'double') {
          _errors.add(SemanticError(
            'Operador ${op} só pode ser aplicado a tipos numéricos',
            simbolo: id.name,
            linha: node.linha,
            coluna: node.coluna,
          ));
          return;
        }

        final baseOp = op.startsWith('++') ? '++' : '--';
        
        if (isPostfix) {
          // POSTFIX (i++, i--): retorna valor atual, depois incrementa
          // 1. Carrega valor atual (será retornado)
          program.add(BytecodeInstruction(Opcode.loadVar, id.name));
          
          // 2. Duplica valor na pilha (uma cópia para retornar, outra para incrementar)
          program.add(BytecodeInstruction(Opcode.loadVar, id.name));
          
          // 3. Empilha 1 para incremento/decremento
          if (symbol.type == 'int') {
            program.add(BytecodeInstruction(Opcode.pushInt, 1));
          } else {
            program.add(BytecodeInstruction(Opcode.pushDouble, 1.0));
          }
          
          // 4. Aplica incremento/decremento
          if (baseOp == '++') {
            program.add(BytecodeInstruction(Opcode.add));
          } else {
            program.add(BytecodeInstruction(Opcode.sub));
          }
          
          // 5. Armazena novo valor (a cópia do valor antigo ainda está no topo da pilha)
          program.add(BytecodeInstruction(Opcode.storeVar, id.name));
          // Valor retornado (antigo) já está na pilha
        } else {
          // PREFIXO (++i, --i): incrementa primeiro, depois retorna novo valor
          // 1. Carrega valor atual
          program.add(BytecodeInstruction(Opcode.loadVar, id.name));
          
          // 2. Empilha 1 para incremento/decremento
          if (symbol.type == 'int') {
            program.add(BytecodeInstruction(Opcode.pushInt, 1));
          } else {
            program.add(BytecodeInstruction(Opcode.pushDouble, 1.0));
          }
          
          // 3. Aplica incremento/decremento
          if (baseOp == '++') {
            program.add(BytecodeInstruction(Opcode.add));
          } else {
            program.add(BytecodeInstruction(Opcode.sub));
          }
          
          // 4. Armazena novo valor
          program.add(BytecodeInstruction(Opcode.storeVar, id.name));
          // O novo valor já está na pilha (para uso em expressões)
        }
      } else {
        _errors.add(SemanticError(
          'Operador ${op} só pode ser aplicado a identificadores',
          linha: node.linha,
          coluna: node.coluna,
        ));
      }
      return;
    }

    // Operadores unários normais
    node.operand.accept(this);

    if (op == '-') {
      // Negação numérica: 0 - valor
      program.add(BytecodeInstruction(Opcode.pushInt, 0));
      program.add(BytecodeInstruction(Opcode.pushDouble, 0.0));
      program.add(BytecodeInstruction(Opcode.sub));
    } else if (op == '+') {
      // Unário + não faz nada, valor já está na pilha
    } else if (op == '!') {
      program.add(BytecodeInstruction(Opcode.not));
    }
  }

  // ============================================================================
  // Helper methods
  // ============================================================================

  void _emitArithmeticOp(String op) {
    switch (op) {
      case '+':
        program.add(BytecodeInstruction(Opcode.add));
        break;
      case '-':
        program.add(BytecodeInstruction(Opcode.sub));
        break;
      case '*':
        program.add(BytecodeInstruction(Opcode.mul));
        break;
      case '/':
        program.add(BytecodeInstruction(Opcode.div));
        break;
      case '%':
        program.add(BytecodeInstruction(Opcode.mod));
        break;
    }
  }

  String _newLabel(String prefix) {
    final count = _labelCounter[prefix] ??= 0;
    _labelCounter[prefix] = count + 1;
    return '${prefix}_$count';
  }

  String? _inferType(Expr? expr) {
    if (expr == null) return null;
    if (expr is Literal) return expr.kind;
    if (expr is Identifier) {
      final s = symbolTable.lookup(expr.name);
      return s?.type;
    }
    // Para outras expressões, o tipo é inferido durante análise semântica
    return null;
  }
}

/// Representa um frame de escopo durante a geração de bytecode
class ScopeFrame {
  final Set<String> declaredVars = {};
}


