/// Tabela de símbolos simples com UID interno
/// Esta é uma implementação inicial: adicione escopos aninhados quando for necessário.

class Symbol {
  final int id;            // UID interno
  final String name;       // nome do símbolo (lexema)
  String? type;            // tipo inferido ou declarado (ex: 'int', 'string', or null/unknown)
  final bool isMutable;    // exemplo: true se variável mutável

  Symbol(this.id, this.name, {this.type, this.isMutable = true});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'isMutable': isMutable,
  };
}

class SymbolTable {
  final Map<String, Symbol> _symbols = {};
  int _nextId = 1;

  /// Adiciona um símbolo e retorna o objeto criado. Se já existe, retorna o existente.
  Symbol add(String name, {String? type, bool isMutable = true}) {
    if (_symbols.containsKey(name)) return _symbols[name]!;
    final s = Symbol(_nextId++, name, type: type, isMutable: isMutable);
    _symbols[name] = s;
    return s;
  }

  Symbol? lookup(String name) => _symbols[name];

  List<Symbol> get allSymbols => List.unmodifiable(_symbols.values);

  void clear() {
    _symbols.clear();
    _nextId = 1;
  }
}
