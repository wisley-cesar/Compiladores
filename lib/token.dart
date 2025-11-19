/// Enum que define todos os tipos de tokens reconhecidos pelo lexer
enum TokenType {
  // Palavras reservadas
  palavraReservada,

  // Identificadores (nomes de variáveis, funções, etc.)
  identificador,

  // Literais
  numero, // Números inteiros e decimais
  string, // Strings entre aspas duplas
  booleano, // true, false
  // Operadores
  operador, // +, -, *, /, =, ==, !=, <, >, <=, >=
  // Símbolos especiais
  simbolo, // (, ), {, }, [, ], ;, ,, .
  // Comentários (ignorados pelo parser)
  comentario,

  // Erros léxicos
  erro,

  // Fim de arquivo
  eof,
}

/// Classe que representa um token reconhecido pelo lexer
class Token {
  final TokenType tipo;
  final String lexema;
  final int linha;
  final int coluna;

  Token(this.tipo, this.lexema, this.linha, this.coluna);

  /// Verifica se o token é um operador
  bool get isOperador => tipo == TokenType.operador;

  /// Verifica se o token é uma palavra reservada
  bool get isPalavraReservada => tipo == TokenType.palavraReservada;

  /// Verifica se o token é um literal
  bool get isLiteral =>
      tipo == TokenType.numero ||
      tipo == TokenType.string ||
      tipo == TokenType.booleano;

  /// Verifica se o token é um identificador
  bool get isIdentificador => tipo == TokenType.identificador;

  @override
  String toString() {
    return '(${tipo.name.toUpperCase()}, "$lexema", linha: $linha, col: $coluna)';
  }

  /// Retorna uma representação mais legível do token
  String toReadableString() {
    switch (tipo) {
      case TokenType.palavraReservada:
        return 'Palavra reservada: $lexema';
      case TokenType.identificador:
        return 'Identificador: $lexema';
      case TokenType.numero:
        return 'Número: $lexema';
      case TokenType.string:
        return 'String: $lexema';
      case TokenType.booleano:
        return 'Booleano: $lexema';
      case TokenType.operador:
        return 'Operador: $lexema';
      case TokenType.simbolo:
        return 'Símbolo: $lexema';
      case TokenType.erro:
        return 'ERRO LÉXICO: $lexema';
      case TokenType.eof:
        return 'Fim de arquivo';
      default:
        return 'Token: $lexema';
    }
  }

  /// Serializa o token para um mapa (útil para exportar/JSON)
  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.name,
      'lexema': lexema,
      'linha': linha,
      'coluna': coluna,
    };
  }
}
