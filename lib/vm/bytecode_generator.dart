import 'package:compilador/sintatica/ast/ast.dart';
import 'package:compilador/vm/bytecode.dart';
import 'package:compilador/symbol_table.dart';
import 'package:compilador/semantic_error.dart';

/// Gerador de bytecode a partir de uma AST
///
/// **Estratégia de Implementação:**
///
/// Este gerador implementa o padrão Visitor para percorrer a árvore sintática (AST)
/// e gerar código de máquina virtual (bytecode). A estratégia baseia-se em:
///
/// 1. **Pilha de Valores**: O bytecode usa uma pilha para avaliar expressões.
///    - Valores são empilhados com `pushInt`, `pushDouble`, `pushBool`, `pushString`
///    - Operações binárias consomem dois valores do topo da pilha e empilham o resultado
///    - Operações unárias consomem um valor e empilham o resultado
///
/// 2. **Labels para Controle de Fluxo**: Saltos condicionais e incondicionais usam labels
///    - Labels são gerados automaticamente com contadores únicos (ex: `loop_start_0`, `else_1`)
///    - Labels são associados a índices de instruções para permitir saltos
///
/// 3. **Gerenciamento de Escopos**: Variáveis são gerenciadas por escopo
///    - `enterScope` marca início de novo escopo (blocos, funções, loops)
///    - `exitScope` marca fim do escopo atual
///    - Variáveis são armazenadas/carregadas por nome no escopo atual
///
/// 4. **Tratamento de Erros**: Verificações semânticas durante a geração
///    - Variáveis não declaradas são detectadas antes de uso
///    - Erros são coletados mas não interrompem a geração (permite múltiplos erros)
///
/// **Exemplo de uso:**
/// ```dart
/// final analyzer = SemanticAnalyzer(null, src);
/// final symbolTable = analyzer.analyze(program);
/// final generator = BytecodeGenerator(symbolTable);
/// final bytecode = generator.generate(program);
/// ```
class BytecodeGenerator implements AstVisitor<void> {
  final SymbolTable symbolTable;
  final BytecodeProgram program = BytecodeProgram();
  final Map<String, int> _labelCounter = {};
  final List<ScopeFrame> _scopeStack = [];
  final List<SemanticError> _errors = [];

  BytecodeGenerator(this.symbolTable) {
    // Inicializa escopo global (escopo raiz do programa)
    _scopeStack.add(ScopeFrame());
  }

  List<SemanticError> get errors => _errors;

  /// Gera bytecode para um programa completo
  ///
  /// **Estratégia:**
  /// 1. Limpa instruções e labels anteriores
  /// 2. Percorre cada statement do programa usando o padrão Visitor
  /// 3. Adiciona instrução `halt` ao final para terminar execução
  ///
  /// **Exemplo:**
  /// Código: `int x = 10; int y = 20;`
  /// Bytecode gerado:
  /// ```
  /// pushInt(10)
  /// storeVar("x")
  /// pushInt(20)
  /// storeVar("y")
  /// halt
  /// ```
  BytecodeProgram generate(Program program) {
    this.program.instructions.clear();
    this.program.labels.clear();

    for (final stmt in program.statements) {
      stmt.accept(this);
    }

    // Sempre termina com halt para parar a execução da VM
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
    /// **Estratégia para Declaração de Variáveis:**
    ///
    /// 1. Verifica se variável já existe no escopo atual (evita redeclaração)
    /// 2. Se há inicializador: avalia expressão e armazena resultado
    /// 3. Se não há inicializador: empilha valor padrão baseado no tipo
    /// 4. Usa `storeVar` para armazenar valor na variável
    ///
    /// **Exemplo 1 - Com inicializador:**
    /// Código: `int x = 10;`
    /// Bytecode:
    /// ```
    /// pushInt(10)      // Avalia expressão (literal 10)
    /// storeVar("x")    // Armazena na variável x
    /// ```
    ///
    /// **Exemplo 2 - Sem inicializador:**
    /// Código: `int x;`
    /// Bytecode:
    /// ```
    /// pushInt(0)       // Valor padrão para int
    /// storeVar("x")    // Armazena na variável x
    /// ```
    ///
    /// **Exemplo 3 - Inicializador complexo:**
    /// Código: `int x = (a + b) * 2;`
    /// Bytecode:
    /// ```
    /// loadVar("a")     // Carrega a
    /// loadVar("b")     // Carrega b
    /// add              // a + b (resultado na pilha)
    /// pushInt(2)       // Empilha 2
    /// mul              // (a + b) * 2 (resultado na pilha)
    /// storeVar("x")    // Armazena resultado em x
    /// ```

    // Verifica se a variável já foi declarada no escopo atual
    final existing = symbolTable.currentScopeLookup(node.name);
    if (existing == null) {
      // Se não existe, adiciona ao escopo atual na tabela de símbolos
      // (isso já deve ter sido feito pelo semantic analyzer, mas verificamos)
      try {
        symbolTable.add(node.name, type: _inferType(node.initializer));
      } catch (e) {
        _errors.add(
          SemanticError(
            'Erro ao declarar variável "${node.name}": $e',
            simbolo: node.name,
            linha: node.linha,
            coluna: node.coluna,
          ),
        );
        return;
      }
    }

    // Marca variável como declarada no escopo atual (para rastreamento interno)
    _scopeStack.last.declaredVars.add(node.name);

    // Se há inicializador, avalia e armazena
    if (node.initializer != null) {
      // Avalia expressão do inicializador (resultado fica no topo da pilha)
      node.initializer!.accept(this);
      // Armazena valor do topo da pilha na variável
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
    /// **Estratégia para Atribuição:**
    ///
    /// 1. Verifica se variável existe (tratamento de erro)
    /// 2. Avalia expressão do lado direito (resultado na pilha)
    /// 3. Armazena valor na variável usando `storeVar`
    ///
    /// **Exemplo:**
    /// Código: `x = 10;`
    /// Bytecode:
    /// ```
    /// pushInt(10)      // Avalia expressão
    /// storeVar("x")    // Armazena em x
    /// ```
    ///
    /// **Exemplo com expressão:**
    /// Código: `x = a + b;`
    /// Bytecode:
    /// ```
    /// loadVar("a")     // Carrega a
    /// loadVar("b")     // Carrega b
    /// add              // a + b (resultado na pilha)
    /// storeVar("x")    // Armazena resultado em x
    /// ```

    // Verifica se a variável existe (tratamento de erro semântico)
    final symbol = symbolTable.lookup(node.target.name);
    if (symbol == null) {
      _errors.add(
        SemanticError(
          'Atribuição para variável não declarada "${node.target.name}"',
          simbolo: node.target.name,
          linha: node.linha,
          coluna: node.coluna,
        ),
      );
      return;
    }

    // Avalia expressão do lado direito (resultado fica no topo da pilha)
    node.value.accept(this);
    // Armazena valor do topo da pilha na variável
    program.add(BytecodeInstruction(Opcode.storeVar, node.target.name));
  }

  @override
  void visitIfStmt(IfStmt node) {
    /// **Estratégia para If/Else:**
    ///
    /// Usa labels e saltos condicionais para implementar controle de fluxo:
    ///
    /// 1. Avalia condição (resultado booleano na pilha)
    /// 2. Se falso, salta para label do else (ou fim se não há else)
    /// 3. Executa bloco then
    /// 4. Se há else, salta para fim (para pular o else)
    /// 5. Label do else: executa bloco else
    /// 6. Label do fim: continua execução
    ///
    /// **Exemplo 1 - If sem else:**
    /// Código: `if (x > 0) { y = 1; }`
    /// Bytecode:
    /// ```
    /// loadVar("x")           // Carrega x
    /// pushInt(0)             // Empilha 0
    /// gt                     // x > 0 (resultado na pilha)
    /// jumpIfFalse(else_0)    // Se falso, pula para else_0
    /// pushInt(1)             // Bloco then: empilha 1
    /// storeVar("y")          // y = 1
    /// else_0:                // Label do else (fim do if)
    /// ```
    ///
    /// **Exemplo 2 - If com else:**
    /// Código: `if (x > 0) { y = 1; } else { y = 2; }`
    /// Bytecode:
    /// ```
    /// loadVar("x")           // Carrega x
    /// pushInt(0)             // Empilha 0
    /// gt                     // x > 0
    /// jumpIfFalse(else_0)    // Se falso, pula para else_0
    /// pushInt(1)             // Bloco then: y = 1
    /// storeVar("y")
    /// jump(endif_0)          // Pula para fim (evita executar else)
    /// else_0:                // Label do else
    /// pushInt(2)             // Bloco else: y = 2
    /// storeVar("y")
    /// endif_0:               // Label do fim
    /// ```

    final elseLabel = _newLabel('else');
    final endLabel = _newLabel('endif');

    // Avalia condição (resultado booleano fica no topo da pilha)
    node.condition.accept(this);

    // Se condição for falsa, salta para o label do else (ou fim se não há else)
    program.add(BytecodeInstruction(Opcode.jumpIfFalse, elseLabel));

    // Bloco then: executa se condição for verdadeira
    node.thenBranch.accept(this);

    if (node.elseBranch != null) {
      // Se há else, salta para o fim (para não executar o else)
      program.add(BytecodeInstruction(Opcode.jump, endLabel));
      // Label do else: ponto de entrada do bloco else
      program.addLabel(elseLabel);
      // Bloco else: executa se condição for falsa
      node.elseBranch!.accept(this);
      // Label do fim: continua execução após if/else
      program.addLabel(endLabel);
    } else {
      // Se não há else, o label else marca o fim do if
      program.addLabel(elseLabel);
    }
  }

  @override
  void visitWhileStmt(WhileStmt node) {
    /// **Estratégia para While:**
    ///
    /// Implementa loop usando labels e saltos:
    ///
    /// 1. Label de início do loop
    /// 2. Avalia condição (resultado booleano na pilha)
    /// 3. Se falso, salta para fim do loop
    /// 4. Executa corpo do loop
    /// 5. Salta de volta para início (volta ao passo 2)
    /// 6. Label de fim do loop
    ///
    /// **Exemplo:**
    /// Código: `while (x > 0) { x = x - 1; }`
    /// Bytecode:
    /// ```
    /// loop_start_0:          // Label de início
    /// loadVar("x")           // Carrega x
    /// pushInt(0)             // Empilha 0
    /// gt                     // x > 0
    /// jumpIfFalse(loop_end_0) // Se falso, sai do loop
    /// loadVar("x")           // Corpo: carrega x
    /// pushInt(1)             // Empilha 1
    /// sub                    // x - 1
    /// storeVar("x")          // x = x - 1
    /// jump(loop_start_0)     // Volta para início
    /// loop_end_0:            // Label de fim
    /// ```

    final loopStart = _newLabel('loop_start');
    final loopEnd = _newLabel('loop_end');

    // Label de início do loop: ponto de retorno após cada iteração
    program.addLabel(loopStart);

    // Avalia condição (resultado booleano fica no topo da pilha)
    node.condition.accept(this);

    // Se condição for falsa, salta para o fim do loop
    program.add(BytecodeInstruction(Opcode.jumpIfFalse, loopEnd));

    // Corpo do loop: executa enquanto condição for verdadeira
    node.body.accept(this);

    // Salta de volta para o início do loop (próxima iteração)
    program.add(BytecodeInstruction(Opcode.jump, loopStart));

    // Label de fim do loop: continua execução após o loop
    program.addLabel(loopEnd);
  }

  @override
  void visitFor(ForStmt node) {
    /// **Estratégia para For:**
    ///
    /// Implementa loop for com três partes: inicialização, condição, update
    ///
    /// 1. Entra em novo escopo (variável do loop pode ser local)
    /// 2. Executa inicialização (declaração ou atribuição)
    /// 3. Label de início do loop
    /// 4. Avalia condição (se houver) e salta para fim se falsa
    /// 5. Executa corpo do loop
    /// 6. Label de continue (ponto de update)
    /// 7. Executa update (se houver) e descarta resultado
    /// 8. Salta de volta para início
    /// 9. Label de fim do loop
    /// 10. Sai do escopo
    ///
    /// **Exemplo:**
    /// Código: `for (int i = 0; i < 10; i++) { x = x + i; }`
    /// Bytecode:
    /// ```
    /// enterScope              // Novo escopo para i
    /// pushInt(0)              // Inicialização: i = 0
    /// storeVar("i")
    /// for_start_0:            // Início do loop
    /// loadVar("i")            // Condição: i < 10
    /// pushInt(10)
    /// lt
    /// jumpIfFalse(for_end_0)  // Se falso, sai
    /// loadVar("x")            // Corpo: x = x + i
    /// loadVar("i")
    /// add
    /// storeVar("x")
    /// for_continue_0:         // Update
    /// loadVar("i")            // i++ (postfix)
    /// pushInt(1)
    /// add
    /// storeVar("i")
    /// pop                     // Descarta resultado do i++
    /// jump(for_start_0)       // Volta para início
    /// for_end_0:              // Fim do loop
    /// exitScope               // Sai do escopo
    /// ```

    // Entra em novo escopo para a variável do loop (permite variável local)
    _scopeStack.add(ScopeFrame());
    program.add(BytecodeInstruction(Opcode.enterScope));

    // Inicialização (se houver): declaração ou atribuição
    if (node.init != null) {
      node.init!.accept(this);
    }

    final loopStart = _newLabel('for_start');
    final loopEnd = _newLabel('for_end');
    final loopContinue = _newLabel('for_continue');

    // Label de início do loop: ponto de retorno após cada iteração
    program.addLabel(loopStart);

    // Condição (se houver): avalia e salta para fim se falsa
    if (node.condition != null) {
      node.condition!.accept(this);
      program.add(BytecodeInstruction(Opcode.jumpIfFalse, loopEnd));
    }

    // Corpo do loop: executa enquanto condição for verdadeira
    node.body.accept(this);

    // Label de continue: ponto onde o update é executado
    program.addLabel(loopContinue);

    // Update (se houver): incremento/decremento ou atribuição
    if (node.update != null) {
      node.update!.accept(this);
      // Descarta resultado do update (não é usado em expressões)
      program.add(BytecodeInstruction(Opcode.pop));
    }

    // Volta para o início do loop (próxima iteração)
    program.add(BytecodeInstruction(Opcode.jump, loopStart));

    // Label de fim do loop: continua execução após o loop
    program.addLabel(loopEnd);

    // Sai do escopo: variáveis locais do loop são descartadas
    program.add(BytecodeInstruction(Opcode.exitScope));
    _scopeStack.removeLast();
  }

  @override
  void visitBlock(Block node) {
    /// **Estratégia para Blocos:**
    ///
    /// Blocos criam novo escopo para variáveis locais:
    ///
    /// 1. Entra em novo escopo (`enterScope`)
    /// 2. Executa todos os statements do bloco
    /// 3. Sai do escopo (`exitScope`) - variáveis locais são descartadas
    ///
    /// **Exemplo:**
    /// Código: `{ int x = 10; int y = 20; }`
    /// Bytecode:
    /// ```
    /// enterScope          // Novo escopo
    /// pushInt(10)         // Declara x
    /// storeVar("x")
    /// pushInt(20)         // Declara y
    /// storeVar("y")
    /// exitScope           // Sai do escopo (x e y não são mais acessíveis)
    /// ```
    ///
    /// **Escopo Aninhado:**
    /// Código: `int x = 0; { int x = 10; } // x externo ainda é 0`
    /// Bytecode:
    /// ```
    /// pushInt(0)          // x global = 0
    /// storeVar("x")
    /// enterScope          // Novo escopo (x local)
    /// pushInt(10)         // x local = 10
    /// storeVar("x")
    /// exitScope           // Sai do escopo (x local descartado)
    /// // x global ainda é 0
    /// ```

    // Entra em novo escopo: variáveis declaradas aqui são locais ao bloco
    _scopeStack.add(ScopeFrame());
    program.add(BytecodeInstruction(Opcode.enterScope));

    // Executa todos os statements do bloco
    for (final stmt in node.statements) {
      stmt.accept(this);
    }

    // Sai do escopo: variáveis locais são descartadas
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
      _errors.add(
        SemanticError(
          'Callee deve ser um identificador',
          linha: node.linha,
          coluna: node.coluna,
        ),
      );
      return;
    }

    final funcName = callee.name;
    final symbol = symbolTable.lookup(funcName);
    if (symbol == null) {
      _errors.add(
        SemanticError(
          'Chamada para função não declarada "$funcName"',
          simbolo: funcName,
          linha: node.linha,
          coluna: node.coluna,
        ),
      );
      return;
    }

    // Avalia argumentos (em ordem)
    for (final arg in node.args) {
      arg.accept(this);
    }

    // Chama função
    program.add(
      BytecodeInstruction(Opcode.call, {
        'name': funcName,
        'argCount': node.args.length,
      }),
    );
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
    /// **Estratégia para Literais:**
    ///
    /// Literais são valores constantes que são empilhados diretamente:
    ///
    /// **Exemplos:**
    /// - `10` → `pushInt(10)`
    /// - `3.14` → `pushDouble(3.14)`
    /// - `true` → `pushBool(true)`
    /// - `"Hello"` → `pushString("Hello")` (aspas removidas)
    ///
    /// **Exemplo de uso:**
    /// Código: `int x = 10;`
    /// Bytecode:
    /// ```
    /// pushInt(10)      // Empilha literal 10
    /// storeVar("x")    // Armazena em x
    /// ```

    switch (node.kind) {
      case 'int':
        // Empilha literal inteiro
        program.add(
          BytecodeInstruction(Opcode.pushInt, int.tryParse(node.lexeme) ?? 0),
        );
        break;
      case 'double':
        // Empilha literal decimal
        program.add(
          BytecodeInstruction(
            Opcode.pushDouble,
            double.tryParse(node.lexeme) ?? 0.0,
          ),
        );
        break;
      case 'bool':
        // Empilha literal booleano (converte "true"/"false" para bool)
        program.add(
          BytecodeInstruction(Opcode.pushBool, node.lexeme == 'true'),
        );
        break;
      case 'string':
        // Remove aspas do início e fim da string
        final value = node.lexeme.length >= 2
            ? node.lexeme.substring(1, node.lexeme.length - 1)
            : node.lexeme;
        program.add(BytecodeInstruction(Opcode.pushString, value));
        break;
      default:
        // Tipo desconhecido: empilha null
        program.add(BytecodeInstruction(Opcode.pushNull));
    }
  }

  @override
  void visitIdentifier(Identifier node) {
    /// **Estratégia para Identificadores:**
    ///
    /// Identificadores carregam o valor da variável na pilha:
    ///
    /// 1. Verifica se variável existe (tratamento de erro)
    /// 2. Se existe, carrega valor com `loadVar`
    /// 3. Se não existe, reporta erro e empilha null (para continuar geração)
    ///
    /// **Exemplo:**
    /// Código: `x + 10` (assumindo que x = 5)
    /// Bytecode:
    /// ```
    /// loadVar("x")     // Carrega valor de x (5) na pilha
    /// pushInt(10)      // Empilha 10
    /// add              // 5 + 10 = 15
    /// ```

    // Verifica se a variável existe (tratamento de erro semântico)
    final symbol = symbolTable.lookup(node.name);
    if (symbol == null) {
      _errors.add(
        SemanticError(
          'Uso de variável não declarada "${node.name}"',
          simbolo: node.name,
          linha: node.linha,
          coluna: node.coluna,
        ),
      );
      // Carrega valor padrão (null) para permitir continuar a geração
      program.add(BytecodeInstruction(Opcode.pushNull));
      return;
    }

    // Carrega valor da variável na pilha
    program.add(BytecodeInstruction(Opcode.loadVar, node.name));
  }

  @override
  void visitBinary(Binary node) {
    /// **Estratégia para Operações Binárias:**
    ///
    /// Usa pilha para avaliar expressões binárias:
    ///
    /// 1. Avalia operando esquerdo (resultado na pilha)
    /// 2. Avalia operando direito (resultado na pilha)
    /// 3. Aplica operação (consome dois valores, empilha resultado)
    ///
    /// **Ordem na pilha:** [esquerdo, direito] → [resultado]
    ///
    /// **Exemplo - Aritmética:**
    /// Código: `a + b`
    /// Bytecode:
    /// ```
    /// loadVar("a")     // Empilha a
    /// loadVar("b")     // Empilha b
    /// add              // Consome a e b, empilha (a + b)
    /// ```
    ///
    /// **Exemplo - Comparação:**
    /// Código: `x > 10`
    /// Bytecode:
    /// ```
    /// loadVar("x")     // Empilha x
    /// pushInt(10)      // Empilha 10
    /// gt               // Consome x e 10, empilha (x > 10) como bool
    /// ```
    ///
    /// **Exemplo - Lógico:**
    /// Código: `a && b`
    /// Bytecode:
    /// ```
    /// loadVar("a")     // Empilha a
    /// loadVar("b")     // Empilha b
    /// and              // Consome a e b, empilha (a && b) como bool
    /// ```
    ///
    /// **Atribuições Compostas (x += 5):**
    /// 1. Carrega valor atual de x
    /// 2. Avalia expressão à direita (5)
    /// 3. Aplica operação (+)
    /// 4. Armazena resultado em x
    ///
    /// Bytecode para `x += 5`:
    /// ```
    /// loadVar("x")     // Carrega valor atual
    /// pushInt(5)       // Empilha 5
    /// add              // x + 5
    /// storeVar("x")    // x = x + 5
    /// ```

    final op = node.operator;

    // Tratamento especial para atribuição simples (=)
    if (op == '=') {
      // Atribuição simples: avalia expressão e armazena
      if (node.left is Identifier) {
        final id = node.left as Identifier;
        final symbol = symbolTable.lookup(id.name);
        if (symbol == null) {
          _errors.add(
            SemanticError(
              'Atribuição para variável não declarada "${id.name}"',
              simbolo: id.name,
              linha: node.linha,
              coluna: node.coluna,
            ),
          );
          return;
        }
        // Avalia expressão do lado direito (resultado na pilha)
        node.right.accept(this);
        // Armazena valor na variável (valor permanece na pilha para atribuições encadeadas)
        program.add(BytecodeInstruction(Opcode.storeVar, id.name));
      } else {
        // Atribuição complexa não suportada no momento
        _errors.add(
          SemanticError(
            'Lado esquerdo de atribuição deve ser identificador',
            linha: node.linha,
            coluna: node.coluna,
          ),
        );
      }
      return;
    }

    // Operadores de atribuição composta (+=, -=, *=, /=)
    if (op == '+=' || op == '-=' || op == '*=' || op == '/=') {
      if (node.left is Identifier) {
        final id = node.left as Identifier;
        final symbol = symbolTable.lookup(id.name);
        if (symbol == null) {
          _errors.add(
            SemanticError(
              'Atribuição para variável não declarada "${id.name}"',
              simbolo: id.name,
              linha: node.linha,
              coluna: node.coluna,
            ),
          );
          return;
        }

        // Carrega valor atual da variável (primeiro operando)
        program.add(BytecodeInstruction(Opcode.loadVar, id.name));
        // Avalia expressão à direita (segundo operando)
        node.right.accept(this);

        // Aplica operação correspondente (remove '=' do operador)
        final baseOp = op.substring(0, op.length - 1);
        _emitArithmeticOp(baseOp);

        // Armazena resultado de volta na variável
        program.add(BytecodeInstruction(Opcode.storeVar, id.name));
      } else {
        _errors.add(
          SemanticError(
            'Lado esquerdo de atribuição deve ser identificador',
            linha: node.linha,
            coluna: node.coluna,
          ),
        );
      }
      return;
    }

    // Operações binárias normais: avalia ambos operandos e aplica operação
    // Ordem: esquerdo primeiro, depois direito (pilha: [esquerdo, direito])
    node.left.accept(this);
    node.right.accept(this);

    // Operadores aritméticos: consomem dois valores, empilham resultado
    if (op == '+' || op == '-' || op == '*' || op == '/' || op == '%') {
      _emitArithmeticOp(op);
    }
    // Operadores lógicos: consomem dois valores booleanos, empilham resultado booleano
    else if (op == '&&') {
      program.add(BytecodeInstruction(Opcode.and));
    } else if (op == '||') {
      program.add(BytecodeInstruction(Opcode.or));
    }
    // Operadores de comparação: consomem dois valores, empilham resultado booleano
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
    /// **Estratégia para Operadores Unários:**
    ///
    /// **Incremento/Decremento (++/--):**
    ///
    /// Diferença entre prefixo e postfix:
    /// - **Prefixo (++i)**: incrementa primeiro, retorna novo valor
    /// - **Postfix (i++)**: retorna valor atual, depois incrementa
    ///
    /// **Exemplo 1 - Prefixo (++i):**
    /// Código: `++i` (em expressão `x = ++i`)
    /// Bytecode:
    /// ```
    /// loadVar("i")     // Carrega valor atual (ex: 5)
    /// pushInt(1)       // Empilha 1
    /// add              // i + 1 = 6
    /// storeVar("i")    // i = 6
    /// // Valor 6 está na pilha (retornado)
    /// ```
    /// Resultado: i = 6, expressão retorna 6
    ///
    /// **Exemplo 2 - Postfix (i++):**
    /// Código: `i++` (em expressão `x = i++`)
    /// Bytecode:
    /// ```
    /// loadVar("i")     // Carrega valor atual (ex: 5) - será retornado
    /// loadVar("i")     // Carrega novamente para incrementar
    /// pushInt(1)       // Empilha 1
    /// add              // i + 1 = 6
    /// storeVar("i")    // i = 6
    /// // Valor 5 (antigo) ainda está na pilha (retornado)
    /// ```
    /// Resultado: i = 6, expressão retorna 5 (valor antigo)
    ///
    /// **Operadores Unários Normais:**
    ///
    /// **Negação (-):**
    /// Código: `-x`
    /// Bytecode:
    /// ```
    /// loadVar("x")     // Carrega x
    /// pushInt(0)       // Empilha 0
    /// pushDouble(0.0)  // Empilha 0.0 (para compatibilidade)
    /// sub              // 0 - x = -x
    /// ```
    ///
    /// **Negação Lógica (!):**
    /// Código: `!x`
    /// Bytecode:
    /// ```
    /// loadVar("x")     // Carrega x (booleano)
    /// not              // !x
    /// ```

    final op = node.operator;

    // Tratamento especial para incremento/decremento
    final isPostfix = op == '++post' || op == '--post';
    final isPrefix = op == '++' || op == '--';

    if (isPrefix || isPostfix) {
      if (node.operand is Identifier) {
        final id = node.operand as Identifier;
        final symbol = symbolTable.lookup(id.name);
        if (symbol == null) {
          _errors.add(
            SemanticError(
              'Operador $op aplicado a variável não declarada "${id.name}"',
              simbolo: id.name,
              linha: node.linha,
              coluna: node.coluna,
            ),
          );
          return;
        }

        // Verifica se tipo é numérico (int ou double)
        if (symbol.type != 'int' && symbol.type != 'double') {
          _errors.add(
            SemanticError(
              'Operador $op só pode ser aplicado a tipos numéricos',
              simbolo: id.name,
              linha: node.linha,
              coluna: node.coluna,
            ),
          );
          return;
        }

        final baseOp = op.startsWith('++') ? '++' : '--';

        if (isPostfix) {
          // POSTFIX (i++, i--): retorna valor atual, depois incrementa
          // Estratégia: carrega valor duas vezes (uma para retornar, outra para incrementar)
          // 1. Carrega valor atual (será retornado - fica no fundo da pilha)
          program.add(BytecodeInstruction(Opcode.loadVar, id.name));

          // 2. Carrega novamente para incrementar (sobrescreve na pilha)
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
          // Estratégia: calcular valor novo, armazenar, depois carregar para retornar
          // 1. Carrega valor atual
          program.add(BytecodeInstruction(Opcode.loadVar, id.name));

          // 2. Empilha 1 para incremento/decremento
          if (symbol.type == 'int') {
            program.add(BytecodeInstruction(Opcode.pushInt, 1));
          } else {
            program.add(BytecodeInstruction(Opcode.pushDouble, 1.0));
          }

          // 3. Aplica incremento/decremento (resultado na pilha)
          if (baseOp == '++') {
            program.add(BytecodeInstruction(Opcode.add));
          } else {
            program.add(BytecodeInstruction(Opcode.sub));
          }

          // 4. Armazena novo valor (consome valor da pilha)
          program.add(BytecodeInstruction(Opcode.storeVar, id.name));

          // 5. Carrega o valor armazenado para retornar
          program.add(BytecodeInstruction(Opcode.loadVar, id.name));
        }
      } else {
        _errors.add(
          SemanticError(
            'Operador $op só pode ser aplicado a identificadores',
            linha: node.linha,
            coluna: node.coluna,
          ),
        );
      }
      return;
    }

    // Operadores unários normais: avalia operando primeiro
    node.operand.accept(this);

    if (op == '-') {
      // Negação numérica: calcula 0 - valor
      program.add(BytecodeInstruction(Opcode.pushInt, 0));
      program.add(BytecodeInstruction(Opcode.pushDouble, 0.0));
      program.add(BytecodeInstruction(Opcode.sub));
    } else if (op == '+') {
      // Unário + não faz nada, valor já está na pilha
    } else if (op == '!') {
      // Negação lógica: inverte valor booleano
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
