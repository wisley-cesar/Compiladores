/// Tabela de símbolos simples com UID interno
/// Esta é uma implementação inicial: adicione escopos aninhados quando for necessário.

class Symbol {
  final int id; // UID interno
  final String name; // nome do símbolo (lexema)
  String?
  type; // tipo inferido ou declarado (ex: 'int', 'string', or null/unknown)
  final bool isMutable; // exemplo: true se variável mutável

  Symbol(this.id, this.name, {this.type, this.isMutable = true});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'isMutable': isMutable,
  };
}

class SymbolTable {
  /// Pilha de escopos. Cada escopo é um mapa nome -> Symbol.
  final List<Map<String, Symbol>> _scopes = [{}];
  int _nextId = 1;

  /// Entra em um novo escopo (por exemplo, ao entrar em uma função ou bloco).
  void enterScope() {
    _scopes.add({});
  }

  /// Sai do escopo atual. Se for o escopo global, mantém-o.
  void exitScope() {
    if (_scopes.length > 1) _scopes.removeLast();
  }

  /// Adiciona um símbolo ao escopo atual. Se já existir no escopo atual,
  /// lança StateError (redeclaração).
  Symbol add(String name, {String? type, bool isMutable = true}) {
    final current = _scopes.last;
    if (current.containsKey(name)) {
      throw StateError('Redeclaração do símbolo "$name" no mesmo escopo');
    }
    final s = Symbol(_nextId++, name, type: type, isMutable: isMutable);
    current[name] = s;
    return s;
  }

  /// Procura um símbolo pelo nome, navegando pelos escopos do mais interno
  /// para o mais externo. Retorna null se não encontrado.
  Symbol? lookup(String name) {
    for (var i = _scopes.length - 1; i >= 0; i--) {
      final scope = _scopes[i];
      if (scope.containsKey(name)) return scope[name];
    }
    return null;
  }

  /// Retorna o símbolo no escopo atual (sem procurar em escopos externos).
  Symbol? currentScopeLookup(String name) {
    return _scopes.last[name];
  }

  /// Retorna todos os símbolos visíveis (do escopo global apenas para simplicidade).
  List<Symbol> get allSymbols => List.unmodifiable(_scopes.first.values);

  /// Limpa a tabela e reseta para um único escopo global vazio.
  void clear() {
    _scopes.clear();
    _scopes.add({});
    _nextId = 1;
  }
}
