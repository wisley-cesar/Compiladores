/// Definições de instruções de bytecode para a máquina virtual
library bytecode;

/// Tipos de valores no bytecode
enum BytecodeValueType {
  int,
  double,
  bool,
  string,
  nullType,
}

/// Representa um valor no bytecode
class BytecodeValue {
  final BytecodeValueType type;
  final dynamic value;

  BytecodeValue(this.type, this.value);

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'value': value,
      };
}

/// Opcodes (códigos de operação) suportados
enum Opcode {
  // Stack operations
  pushInt,
  pushDouble,
  pushBool,
  pushString,
  pushNull,
  pop,

  // Variable operations
  loadVar, // Carrega variável na pilha (argumento: nome da variável)
  storeVar, // Armazena valor do topo da pilha em variável (argumento: nome)
  declareVar, // Declara nova variável no escopo atual (argumento: nome)

  // Arithmetic operations
  add,
  sub,
  mul,
  div,
  mod,

  // Logical operations
  and,
  or,
  not,

  // Comparison operations
  eq,
  ne,
  lt,
  le,
  gt,
  ge,

  // Control flow
  jump, // Salto incondicional (argumento: endereço)
  jumpIfFalse, // Salta se topo da pilha for falso (argumento: endereço)
  jumpIfTrue, // Salta se topo da pilha for verdadeiro (argumento: endereço)

  // Assignment operations
  assign, // Atribuição simples
  assignAdd, // +=
  assignSub, // -=
  assignMul, // *=
  assignDiv, // /=

  // Increment/Decrement operations
  increment, // ++ (prefix ou postfix)
  decrement, // -- (prefix ou postfix)

  // Scope operations
  enterScope, // Entra em novo escopo
  exitScope, // Sai do escopo atual

  // Function operations
  call, // Chama função (argumento: nome da função, número de argumentos)
  return_, // Retorna da função

  // Special
  nop, // No operation
  halt, // Termina execução
}

/// Representa uma instrução de bytecode
class BytecodeInstruction {
  final Opcode opcode;
  final dynamic operand; // Pode ser String, int, BytecodeValue, etc.

  BytecodeInstruction(this.opcode, [this.operand]);

  Map<String, dynamic> toJson() => {
        'opcode': opcode.name,
        if (operand != null) 'operand': _operandToJson(operand),
      };

  dynamic _operandToJson(dynamic op) {
    if (op is BytecodeValue) return op.toJson();
    if (op is Map) return op;
    if (op is List) return op.map((e) => _operandToJson(e)).toList();
    return op;
  }

  @override
  String toString() {
    if (operand != null) {
      return '${opcode.name}($operand)';
    }
    return opcode.name;
  }
}

/// Programa completo de bytecode
class BytecodeProgram {
  final List<BytecodeInstruction> instructions;
  final Map<String, int> labels; // Nome do label -> índice da instrução

  BytecodeProgram({List<BytecodeInstruction>? instructions, Map<String, int>? labels})
      : instructions = instructions ?? [],
        labels = labels ?? {};

  void add(BytecodeInstruction instruction) {
    instructions.add(instruction);
  }

  void addLabel(String name) {
    labels[name] = instructions.length;
  }

  int get length => instructions.length;

  Map<String, dynamic> toJson() => {
        'instructions': instructions.map((i) => i.toJson()).toList(),
        'labels': labels,
      };

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var i = 0; i < instructions.length; i++) {
      final labelEntries = labels.entries.where((e) => e.value == i);
      for (final entry in labelEntries) {
        buffer.writeln('${entry.key}:');
      }
      buffer.writeln('  $i: ${instructions[i]}');
    }
    return buffer.toString();
  }
}

