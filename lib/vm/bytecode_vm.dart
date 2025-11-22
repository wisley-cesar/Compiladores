import 'bytecode.dart';

/// Erro de tempo de execução da VM.
class VMRuntimeError implements Exception {
  final String message;
  final int ip;
  final Opcode opcode;

  VMRuntimeError(this.message, this.ip, this.opcode);

  @override
  String toString() =>
      'VMRuntimeError (ip=$ip, opcode=${opcode.name}): $message';
}

/// Resultado de execução: pilha final e variáveis globais.
class VMResult {
  final List<dynamic> stack;
  final Map<String, dynamic> globals;

  VMResult({required this.stack, required this.globals});
}

/// Máquina virtual simples baseada em pilha.
class VirtualMachine {
  final BytecodeProgram program;
  final List<dynamic> _stack = [];
  final List<Map<String, dynamic>> _scopes;
  int _ip = 0; // instruction pointer
  bool _halted = false;

  VirtualMachine(this.program, {Map<String, dynamic>? initialGlobals})
    : _scopes = [initialGlobals ?? {}];

  /// Executa até `halt` ou até atingir [maxSteps] (protege contra loop infinito).
  VMResult run({int maxSteps = 100000, bool trace = false}) {
    var steps = 0;
    while (!_halted && _ip >= 0 && _ip < program.instructions.length) {
      if (steps++ > maxSteps) {
        throw VMRuntimeError(
          'Limite de passos excedido ($maxSteps)',
          _ip,
          program.instructions[_ip].opcode,
        );
      }
      final inst = program.instructions[_ip];
      if (trace) {
        // ignore: avoid_print
        print(
          '[$_ip] ${inst.toString()}  stack=$_stack  scope=${_scopes.last}',
        );
      }
      final jumped = _execute(inst);
      if (!jumped) _ip++;
    }
    return VMResult(
      stack: List.unmodifiable(_stack),
      globals: Map.unmodifiable(_scopes.first),
    );
  }

  // ============================================================
  // Execução de instruções
  // ============================================================

  bool _execute(BytecodeInstruction inst) {
    switch (inst.opcode) {
      // Pilha ---------------------------------------------------
      case Opcode.pushInt:
      case Opcode.pushDouble:
      case Opcode.pushBool:
      case Opcode.pushString:
        _stack.add(inst.operand);
        return false;
      case Opcode.pushNull:
        _stack.add(null);
        return false;
      case Opcode.pop:
        _pop();
        return false;

      // Variáveis -----------------------------------------------
      case Opcode.loadVar:
        final name = inst.operand as String;
        _stack.add(_getVar(name));
        return false;
      case Opcode.storeVar:
        final name = inst.operand as String;
        final value = _pop();
        _setVar(name, value);
        return false;
      case Opcode.declareVar:
        final name = inst.operand as String;
        _scopes.last[name] = null;
        return false;

      // Aritmética ----------------------------------------------
      case Opcode.add:
        _binaryNum((a, b) => a + b);
        return false;
      case Opcode.sub:
        _binaryNum((a, b) => a - b);
        return false;
      case Opcode.mul:
        _binaryNum((a, b) => a * b);
        return false;
      case Opcode.div:
        _binaryNum((a, b) {
          if (b == 0) {
            throw VMRuntimeError('Divisão por zero', _ip, inst.opcode);
          }
          return a / b;
        });
        return false;
      case Opcode.mod:
        _binaryNum((a, b) {
          if (b == 0) {
            throw VMRuntimeError('Módulo por zero', _ip, inst.opcode);
          }
          return a % b;
        });
        return false;

      // Lógicos -------------------------------------------------
      case Opcode.and:
        _binaryBool((a, b) => a && b);
        return false;
      case Opcode.or:
        _binaryBool((a, b) => a || b);
        return false;
      case Opcode.not:
        final v = _popBool();
        _stack.add(!v);
        return false;

      // Comparação ----------------------------------------------
      case Opcode.eq:
        _binary((a, b) => a == b);
        return false;
      case Opcode.ne:
        _binary((a, b) => a != b);
        return false;
      case Opcode.lt:
        _binaryNumCompare((a, b) => a < b);
        return false;
      case Opcode.le:
        _binaryNumCompare((a, b) => a <= b);
        return false;
      case Opcode.gt:
        _binaryNumCompare((a, b) => a > b);
        return false;
      case Opcode.ge:
        _binaryNumCompare((a, b) => a >= b);
        return false;

      // Fluxo de controle ---------------------------------------
      case Opcode.jump:
        _ip = _resolveJump(inst.operand);
        return true;
      case Opcode.jumpIfFalse:
        final condFalse = !_popBoolish();
        if (condFalse) {
          _ip = _resolveJump(inst.operand);
          return true;
        }
        return false;
      case Opcode.jumpIfTrue:
        final condTrue = _popBoolish();
        if (condTrue) {
          _ip = _resolveJump(inst.operand);
          return true;
        }
        return false;

      // Atribuição composta -------------------------------------
      case Opcode.assign:
        final name = inst.operand as String;
        final value = _pop();
        _setVar(name, value);
        _stack.add(value);
        return false;
      case Opcode.assignAdd:
        _assignCompound(inst, (a, b) => a + b);
        return false;
      case Opcode.assignSub:
        _assignCompound(inst, (a, b) => a - b);
        return false;
      case Opcode.assignMul:
        _assignCompound(inst, (a, b) => a * b);
        return false;
      case Opcode.assignDiv:
        _assignCompound(inst, (a, b) {
          if (b == 0) {
            throw VMRuntimeError('Divisão por zero', _ip, inst.opcode);
          }
          return a / b;
        });
        return false;

      // ++/-- ---------------------------------------------------
      case Opcode.increment:
        _incDec(inst, delta: 1);
        return false;
      case Opcode.decrement:
        _incDec(inst, delta: -1);
        return false;

      // Escopo --------------------------------------------------
      case Opcode.enterScope:
        _scopes.add({});
        return false;
      case Opcode.exitScope:
        if (_scopes.length == 1) {
          throw VMRuntimeError(
            'Tentativa de sair do escopo global',
            _ip,
            inst.opcode,
          );
        }
        _scopes.removeLast();
        return false;

      // Funções -------------------------------------------------
      case Opcode.call:
        throw VMRuntimeError(
          'Opcode call não suportado na VM básica',
          _ip,
          inst.opcode,
        );
      case Opcode.return_:
        _halted = true;
        return false;

      // Outros --------------------------------------------------
      case Opcode.nop:
        return false;
      case Opcode.halt:
        _halted = true;
        return false;
      // Nota: Todos os opcodes estão cobertos acima, mas mantemos default
      // para casos futuros onde novos opcodes possam ser adicionados
      // ignore: unreachable_switch_default
      default:
        throw VMRuntimeError(
          'Opcode não implementado: ${inst.opcode}',
          _ip,
          inst.opcode,
        );
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  dynamic _pop() {
    if (_stack.isEmpty) {
      throw VMRuntimeError(
        'Pilha vazia',
        _ip,
        program.instructions[_ip].opcode,
      );
    }
    return _stack.removeLast();
  }

  num _popNum() {
    final v = _pop();
    if (v is num) return v;
    throw VMRuntimeError(
      'Esperado número, encontrado $v',
      _ip,
      program.instructions[_ip].opcode,
    );
  }

  bool _popBool() {
    final v = _pop();
    if (v is bool) return v;
    throw VMRuntimeError(
      'Esperado bool, encontrado $v',
      _ip,
      program.instructions[_ip].opcode,
    );
  }

  bool _popBoolish() {
    final v = _pop();
    if (v is bool) return v;
    if (v is num) return v != 0;
    return v != null;
  }

  void _binaryNum(num Function(num, num) op) {
    final right = _popNum();
    final left = _popNum();
    _stack.add(op(left, right));
  }

  void _binaryBool(bool Function(bool, bool) op) {
    final right = _popBool();
    final left = _popBool();
    _stack.add(op(left, right));
  }

  void _binaryNumCompare(bool Function(num, num) op) {
    final right = _popNum();
    final left = _popNum();
    _stack.add(op(left, right));
  }

  void _binary(dynamic Function(dynamic, dynamic) op) {
    final right = _pop();
    final left = _pop();
    _stack.add(op(left, right));
  }

  int _resolveJump(dynamic operand) {
    if (operand is int) return operand;
    if (operand is String) {
      final idx = program.labels[operand];
      if (idx == null) {
        throw VMRuntimeError(
          'Label não encontrado: $operand',
          _ip,
          program.instructions[_ip].opcode,
        );
      }
      return idx;
    }
    throw VMRuntimeError(
      'Operando de jump inválido: $operand',
      _ip,
      program.instructions[_ip].opcode,
    );
  }

  dynamic _getVar(String name) {
    for (var i = _scopes.length - 1; i >= 0; i--) {
      final scope = _scopes[i];
      if (scope.containsKey(name)) return scope[name];
    }
    throw VMRuntimeError(
      'Variável "$name" não declarada',
      _ip,
      program.instructions[_ip].opcode,
    );
  }

  void _setVar(String name, dynamic value) {
    for (var i = _scopes.length - 1; i >= 0; i--) {
      final scope = _scopes[i];
      if (scope.containsKey(name)) {
        scope[name] = value;
        return;
      }
    }
    // Se não existir, cria no escopo atual.
    _scopes.last[name] = value;
  }

  void _assignCompound(
    BytecodeInstruction inst,
    dynamic Function(dynamic, dynamic) op,
  ) {
    final name = inst.operand as String;
    final rhs = _pop();
    final current = _getVar(name);
    if (current is! num || rhs is! num) {
      throw VMRuntimeError(
        'Atribuição composta requer números',
        _ip,
        inst.opcode,
      );
    }
    final result = op(current, rhs);
    _setVar(name, result);
    _stack.add(result);
  }

  void _incDec(BytecodeInstruction inst, {required num delta}) {
    final name = inst.operand as String;
    final current = _getVar(name);
    if (current is! num) {
      throw VMRuntimeError(
        'Incremento/Decremento requer variável numérica',
        _ip,
        inst.opcode,
      );
    }
    final result = current + delta;
    _setVar(name, result);
    _stack.add(result);
  }
}
