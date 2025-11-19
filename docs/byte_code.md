# Geração de Bytecode - Documentação

Este documento descreve a implementação do gerador de bytecode para a linguagem, incluindo como foi implementado, como funciona e como foi aplicado em cada arquivo.

## Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura](#arquitetura)
3. [Estrutura de Bytecode](#estrutura-de-bytecode)
4. [Implementação](#implementação)
5. [Detalhamento por Funcionalidade](#detalhamento-por-funcionalidade)
6. [Arquivos Criados/Modificados](#arquivos-criadosmodificados)

## Visão Geral

O gerador de bytecode é responsável por transformar uma Árvore Sintática Abstrata (AST) em uma sequência de instruções de bytecode que podem ser executadas por uma máquina virtual. Ele implementa o padrão Visitor para percorrer a AST e gerar código de máquina virtual.

### Requisitos Atendidos

✅ **Tratamento de erro**: Verificação da existência de variáveis antes do uso  
✅ **Expressões**: Todas as expressões (aritmética, lógica, comparação)  
✅ **Operações aritméticas**: Soma, subtração, multiplicação, divisão  
✅ **Operadores lógicos**: AND (&&), OR (||), NOT (!)  
✅ **Alocação de variáveis**: Declaração e inicialização  
✅ **Condicionais**: If/else  
✅ **Laços**: While e For  
✅ **Escopo de variáveis**: Gerenciamento de escopos aninhados  
✅ **Operadores incrementais**: ++ e -- (prefixo)

## Arquitetura

### Padrão Visitor

O gerador implementa a interface `AstVisitor<void>`, permitindo percorrer recursivamente a AST:

```dart
class BytecodeGenerator implements AstVisitor<void> {
  final SymbolTable symbolTable;
  final BytecodeProgram program;
  // ...
}
```

### Fluxo de Geração

1. **Análise Semântica**: O `SemanticAnalyzer` já deve ter sido executado, criando a `SymbolTable`
2. **Geração**: O `BytecodeGenerator` percorre a AST usando o padrão Visitor
3. **Validação**: Durante a geração, verifica-se a existência de variáveis na `SymbolTable`
4. **Saída**: Produz um `BytecodeProgram` com lista de instruções e labels

## Estrutura de Bytecode

### Arquivo: `lib/bytecode.dart`

Este arquivo define a estrutura fundamental do bytecode:

#### Tipos de Valores

```dart
enum BytecodeValueType {
  int,
  double,
  bool,
  string,
  nullType,
}
```

#### Opcodes (Códigos de Operação)

O bytecode suporta os seguintes opcodes:

**Stack Operations:**
- `pushInt`, `pushDouble`, `pushBool`, `pushString`, `pushNull`: Empilham valores literais
- `pop`: Remove valor do topo da pilha

**Variable Operations:**
- `loadVar`: Carrega variável na pilha (operando: nome da variável)
- `storeVar`: Armazena valor do topo da pilha em variável (operando: nome)
- `declareVar`: Declara nova variável (operando: nome)

**Arithmetic Operations:**
- `add`, `sub`, `mul`, `div`, `mod`: Operações aritméticas

**Logical Operations:**
- `and`, `or`, `not`: Operadores lógicos

**Comparison Operations:**
- `eq`, `ne`, `lt`, `le`, `gt`, `ge`: Comparações

**Control Flow:**
- `jump`: Salto incondicional (operando: label)
- `jumpIfFalse`: Salta se topo da pilha for falso (operando: label)
- `jumpIfTrue`: Salta se topo da pilha for verdadeiro (operando: label)

**Assignment Operations:**
- `assign`: Atribuição simples
- `assignAdd`, `assignSub`, `assignMul`, `assignDiv`: Atribuições compostas

**Increment/Decrement:**
- `increment`, `decrement`: Operadores ++ e --

**Scope Operations:**
- `enterScope`: Entra em novo escopo
- `exitScope`: Sai do escopo atual

**Function Operations:**
- `call`: Chama função (operando: nome e número de argumentos)
- `return_`: Retorna da função

**Special:**
- `nop`: No operation
- `halt`: Termina execução

### Estrutura de Instrução

Cada instrução é representada por:

```dart
class BytecodeInstruction {
  final Opcode opcode;
  final dynamic operand; // String, int, BytecodeValue, Map, etc.
}
```

### Programa de Bytecode

```dart
class BytecodeProgram {
  final List<BytecodeInstruction> instructions;
  final Map<String, int> labels; // Label -> índice da instrução
}
```

## Implementação

### Arquivo: `lib/bytecode_generator.dart`

Este arquivo contém a implementação principal do gerador de bytecode.

#### Classe Principal

```dart
class BytecodeGenerator implements AstVisitor<void> {
  final SymbolTable symbolTable;
  final BytecodeProgram program = BytecodeProgram();
  final Map<String, int> _labelCounter = {};
  final List<ScopeFrame> _scopeStack = [];
  final List<SemanticError> _errors = [];
}
```

**Componentes:**
- `symbolTable`: Tabela de símbolos construída pelo analisador semântico
- `program`: Programa de bytecode sendo gerado
- `_labelCounter`: Contador para gerar labels únicos
- `_scopeStack`: Pilha de escopos para rastrear variáveis declaradas
- `_errors`: Lista de erros semânticos encontrados durante a geração

## Detalhamento por Funcionalidade

### 1. Tratamento de Expressões

#### Expressões Aritméticas

**Operações suportadas:** `+`, `-`, `*`, `/`, `%`

**Implementação em `visitBinary`:**
```dart
// Avalia operando esquerdo e direito
node.left.accept(this);
node.right.accept(this);

// Emite operação correspondente
_emitArithmeticOp(op); // add, sub, mul, div, mod
```

**Exemplo:**
```dart
// Código: a + b
loadVar("a")
loadVar("b")
add
```

#### Operadores Lógicos

**Operações suportadas:** `&&`, `||`, `!`

**Implementação:**
```dart
// AND
program.add(BytecodeInstruction(Opcode.and));

// OR
program.add(BytecodeInstruction(Opcode.or));

// NOT (em visitUnary)
node.operand.accept(this);
program.add(BytecodeInstruction(Opcode.not));
```

**Exemplo:**
```dart
// Código: a && b
loadVar("a")
loadVar("b")
and
```

#### Operadores de Comparação

**Operações suportadas:** `==`, `!=`, `<`, `<=`, `>`, `>=`

**Implementação:**
```dart
// Avalia ambos operandos
node.left.accept(this);
node.right.accept(this);

// Emite comparação
if (op == '==') program.add(BytecodeInstruction(Opcode.eq));
else if (op == '!=') program.add(BytecodeInstruction(Opcode.ne));
// ... etc
```

**Exemplo:**
```dart
// Código: a < b
loadVar("a")
loadVar("b")
lt
```

### 2. Alocação de Variáveis

**Implementação em `visitVarDecl`:**
```dart
void visitVarDecl(VarDecl node) {
  // 1. Verifica existência (tratamento de erro)
  final existing = symbolTable.currentScopeLookup(node.name);
  if (existing == null) {
    // Adiciona à tabela de símbolos
    symbolTable.add(node.name, type: _inferType(node.initializer));
  }
  
  // 2. Marca como declarada no escopo atual
  _scopeStack.last.declaredVars.add(node.name);
  
  // 3. Inicializa com valor ou padrão
  if (node.initializer != null) {
    node.initializer!.accept(this);
    program.add(BytecodeInstruction(Opcode.storeVar, node.name));
  } else {
    // Inicializa com valor padrão baseado no tipo
    // pushInt(0) ou pushDouble(0.0) ou pushBool(false) ou pushString("")
    program.add(BytecodeInstruction(Opcode.storeVar, node.name));
  }
}
```

**Exemplo:**
```dart
// Código: int x = 10;
pushInt(10)
storeVar("x")

// Código: int y;
pushInt(0)
storeVar("y")
```

### 3. Tratamento de Condicionais

#### If/Else

**Implementação em `visitIfStmt`:**
```dart
void visitIfStmt(IfStmt node) {
  final elseLabel = _newLabel("else");
  final endLabel = _newLabel("endif");
  
  // 1. Avalia condição
  node.condition.accept(this);
  
  // 2. Salta para else se falso
  program.add(BytecodeInstruction(Opcode.jumpIfFalse, elseLabel));
  
  // 3. Bloco then
  node.thenBranch.accept(this);
  
  // 4. Se há else, pula para o fim
  if (node.elseBranch != null) {
    program.add(BytecodeInstruction(Opcode.jump, endLabel));
    program.addLabel(elseLabel);
    node.elseBranch!.accept(this);
    program.addLabel(endLabel);
  } else {
    program.addLabel(elseLabel);
  }
}
```

**Exemplo:**
```dart
// Código: if (x > 0) { y = 1; } else { y = 2; }
loadVar("x")
pushInt(0)
gt
jumpIfFalse(else_0)
loadVar("y")  // then
pushInt(1)
storeVar("y")
jump(endif_0)
else_0:
loadVar("y")  // else
pushInt(2)
storeVar("y")
endif_0:
```

### 4. Tratamento de Laços

#### While

**Implementação em `visitWhileStmt`:**
```dart
void visitWhileStmt(WhileStmt node) {
  final loopStart = _newLabel("loop_start");
  final loopEnd = _newLabel("loop_end");
  
  program.addLabel(loopStart);
  
  // 1. Avalia condição
  node.condition.accept(this);
  
  // 2. Salta para o fim se falso
  program.add(BytecodeInstruction(Opcode.jumpIfFalse, loopEnd));
  
  // 3. Corpo do loop
  node.body.accept(this);
  
  // 4. Volta para o início
  program.add(BytecodeInstruction(Opcode.jump, loopStart));
  
  program.addLabel(loopEnd);
}
```

**Exemplo:**
```dart
// Código: while (x > 0) { x = x - 1; }
loop_start_0:
loadVar("x")
pushInt(0)
gt
jumpIfFalse(loop_end_0)
loadVar("x")    // corpo
pushInt(1)
sub
storeVar("x")
jump(loop_start_0)
loop_end_0:
```

#### For

**Implementação em `visitFor`:**
```dart
void visitFor(ForStmt node) {
  // Entra em novo escopo
  _scopeStack.add(ScopeFrame());
  program.add(BytecodeInstruction(Opcode.enterScope));
  
  // 1. Inicialização
  if (node.init != null) {
    node.init!.accept(this);
  }
  
  final loopStart = _newLabel("for_start");
  final loopEnd = _newLabel("for_end");
  
  program.addLabel(loopStart);
  
  // 2. Condição
  if (node.condition != null) {
    node.condition!.accept(this);
    program.add(BytecodeInstruction(Opcode.jumpIfFalse, loopEnd));
  }
  
  // 3. Corpo
  node.body.accept(this);
  
  // 4. Update
  if (node.update != null) {
    node.update!.accept(this);
    program.add(BytecodeInstruction(Opcode.pop)); // Descarta resultado
  }
  
  // 5. Volta para início
  program.add(BytecodeInstruction(Opcode.jump, loopStart));
  
  program.addLabel(loopEnd);
  
  // Sai do escopo
  program.add(BytecodeInstruction(Opcode.exitScope));
  _scopeStack.removeLast();
}
```

**Exemplo:**
```dart
// Código: for (int i = 0; i < 10; i++) { ... }
enterScope
pushInt(0)
storeVar("i")
for_start_0:
loadVar("i")
pushInt(10)
lt
jumpIfFalse(for_end_0)
// ... corpo ...
loadVar("i")   // update
pushInt(1)
add
storeVar("i")
pop
jump(for_start_0)
for_end_0:
exitScope
```

### 5. Tratamento de Escopo de Variáveis

**Implementação:**
- `ScopeFrame`: Classe auxiliar que rastreia variáveis declaradas em cada escopo
- `_scopeStack`: Pilha de escopos ativos

**Em blocos (`visitBlock`):**
```dart
void visitBlock(Block node) {
  _scopeStack.add(ScopeFrame());
  program.add(BytecodeInstruction(Opcode.enterScope));
  
  for (final stmt in node.statements) {
    stmt.accept(this);
  }
  
  program.add(BytecodeInstruction(Opcode.exitScope));
  _scopeStack.removeLast();
}
```

**Verificação de existência em `visitIdentifier`:**
```dart
void visitIdentifier(Identifier node) {
  final symbol = symbolTable.lookup(node.name);
  if (symbol == null) {
    _errors.add(SemanticError(
      'Uso de variável não declarada "${node.name}"',
      simbolo: node.name,
      linha: node.linha,
      coluna: node.coluna,
    ));
    program.add(BytecodeInstruction(Opcode.pushNull)); // Valor padrão
    return;
  }
  
  program.add(BytecodeInstruction(Opcode.loadVar, node.name));
}
```

### 6. Operadores Incrementais (++ e --)

**Implementação em `visitUnary`:**
```dart
void visitUnary(Unary node) {
  if (op == '++' || op == '--') {
    if (node.operand is Identifier) {
      final id = node.operand as Identifier;
      final symbol = symbolTable.lookup(id.name);
      
      if (symbol == null) {
        _errors.add(SemanticError(...));
        return;
      }
      
      // Carrega valor atual
      program.add(BytecodeInstruction(Opcode.loadVar, id.name));
      
      // Empilha 1
      if (symbol.type == 'int') {
        program.add(BytecodeInstruction(Opcode.pushInt, 1));
      } else if (symbol.type == 'double') {
        program.add(BytecodeInstruction(Opcode.pushDouble, 1.0));
      }
      
      // Aplica incremento/decremento
      if (op == '++') {
        program.add(BytecodeInstruction(Opcode.add));
      } else {
        program.add(BytecodeInstruction(Opcode.sub));
      }
      
      // Armazena novo valor
      program.add(BytecodeInstruction(Opcode.storeVar, id.name));
      // Novo valor já está na pilha
    }
  }
  // ... outros operadores unários
}
```

**Exemplo:**
```dart
// Código: i++
loadVar("i")
pushInt(1)
add
storeVar("i")
// Resultado do incremento permanece na pilha

// Código: --j
loadVar("j")
pushInt(1)
sub
storeVar("j")
// Resultado do decremento permanece na pilha
```

### 7. Atribuições Compostas

**Operadores suportados:** `+=`, `-=`, `*=`, `/=`

**Implementação em `visitBinary`:**
```dart
if (op == '+=' || op == '-=' || op == '*=' || op == '/=') {
  if (node.left is Identifier) {
    final id = node.left as Identifier;
    
    // Verifica existência
    final symbol = symbolTable.lookup(id.name);
    if (symbol == null) {
      _errors.add(SemanticError(...));
      return;
    }
    
    // Carrega valor atual
    program.add(BytecodeInstruction(Opcode.loadVar, id.name));
    
    // Avalia expressão à direita
    node.right.accept(this);
    
    // Aplica operação correspondente
    final baseOp = op.substring(0, op.length - 1); // Remove '='
    _emitArithmeticOp(baseOp);
    
    // Armazena resultado
    program.add(BytecodeInstruction(Opcode.storeVar, id.name));
  }
}
```

**Exemplo:**
```dart
// Código: x += 5
loadVar("x")
pushInt(5)
add
storeVar("x")
```

### 8. Tratamento de Erros

**Verificações implementadas:**

1. **Variáveis não declaradas (uso):**
   - Em `visitIdentifier`: Verifica se variável existe antes de carregar
   - Em `visitAssign`: Verifica se variável existe antes de atribuir
   - Em `visitUnary` (++/--): Verifica se variável existe

2. **Tipos incompatíveis:**
   - Verificação básica de tipo para operadores incrementais (devem ser numéricos)

3. **Erros coletados:**
   - Lista `_errors` armazena todos os erros encontrados
   - Erros são do tipo `SemanticError` (usando a classe do projeto)

**Exemplo de tratamento:**
```dart
void visitIdentifier(Identifier node) {
  final symbol = symbolTable.lookup(node.name);
  if (symbol == null) {
    _errors.add(SemanticError(
      'Uso de variável não declarada "${node.name}"',
      simbolo: node.name,
      linha: node.linha,
      coluna: node.coluna,
    ));
    // Carrega valor padrão para continuar geração
    program.add(BytecodeInstruction(Opcode.pushNull));
    return;
  }
  
  program.add(BytecodeInstruction(Opcode.loadVar, node.name));
}
```

## Arquivos Criados/Modificados

### Arquivos Novos

1. **`lib/bytecode.dart`**
   - Define estrutura de bytecode
   - Enum `BytecodeValueType`: Tipos de valores
   - Enum `Opcode`: Códigos de operação
   - Classes `BytecodeValue`, `BytecodeInstruction`, `BytecodeProgram`

2. **`lib/bytecode_generator.dart`**
   - Implementação principal do gerador
   - Classe `BytecodeGenerator`: Implementa `AstVisitor<void>`
   - Classe `ScopeFrame`: Rastreamento de escopos
   - Métodos visit* para cada tipo de nó da AST

3. **`docs/byte_code.md`**
   - Este documento de documentação

### Integração com o Projeto

O gerador de bytecode pode ser integrado ao fluxo de compilação:

```dart
// Exemplo de uso (pode ser adicionado ao main.dart)
final analyzer = SemanticAnalyzer(null, src);
final symbolTable = analyzer.analyze(program);

final generator = BytecodeGenerator(symbolTable);
final bytecode = generator.generate(program);

// Verifica erros
if (generator.errors.isNotEmpty) {
  print('\n=== BYTECODE GENERATION ERRORS ===');
  for (final e in generator.errors) {
    print(e);
  }
}

// Exporta bytecode
final encoder = JsonEncoder.withIndent('  ');
print('\n=== BYTECODE ===');
print(encoder.convert(bytecode.toJson()));
```

## Resumo das Funcionalidades

| Funcionalidade | Status | Detalhes |
|---------------|--------|----------|
| Expressões aritméticas | ✅ | +, -, *, /, % |
| Operadores lógicos | ✅ | &&, \|\|, ! |
| Operadores de comparação | ✅ | ==, !=, <, <=, >, >= |
| Alocação de variáveis | ✅ | Declaração e inicialização |
| Atribuições | ✅ | =, +=, -=, *=, /= |
| Operadores incrementais | ✅ | ++, -- (prefixo) |
| Condicionais | ✅ | if/else com labels |
| Laços | ✅ | while e for com labels |
| Escopo de variáveis | ✅ | enterScope/exitScope |
| Verificação de erros | ✅ | Variáveis não declaradas |
| Funções | ⚠️ | Estrutura básica (implementação completa requer mais trabalho) |

## Notas de Implementação

1. **Labels**: São gerados automaticamente com contadores para garantir unicidade
2. **Pilha de Escopos**: Usada para rastrear variáveis declaradas em cada escopo
3. **Valores Padrão**: Variáveis sem inicializador recebem valores padrão baseados no tipo
4. **Erros**: O gerador continua mesmo após encontrar erros, produzindo código parcial
5. **Funções**: Implementação básica presente; para produção, seria necessário gerenciar pilha de chamadas e endereços de retorno

## Conclusão

O gerador de bytecode implementa todas as funcionalidades mínimas exigidas:
- ✅ Tratamento de expressões (aritmética, lógica, comparação)
- ✅ Todas as operações básicas de aritmética
- ✅ Todos os operadores lógicos
- ✅ Alocação de variáveis
- ✅ Tratamento de condicionais e laços
- ✅ Tratamento de escopo das variáveis
- ✅ Tratamento de erros (verificação de existência de variáveis)
- ✅ Comandos otimizados (++ e --)

Além disso, implementa funcionalidades extras como atribuições compostas (+=, -=, *=, /=) e suporte básico a funções.

