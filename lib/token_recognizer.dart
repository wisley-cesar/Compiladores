import 'token.dart';

/// Classe responsável pelo reconhecimento de tokens específicos
class TokenRecognizer {
  final String codigo;
  int pos = 0;
  int linha = 1;
  int coluna = 1;
  final List<Token> tokens = [];

  /// Conjunto de palavras reservadas da linguagem
  static const palavrasReservadas = {
    'if', 'else', 'while', 'for', 'do', 'break', 'continue',
    'int', 'float', 'double', 'string', 'bool', 'char',
    'return', 'void', 'main', 'true', 'false', 'null',
    'class', 'public', 'private', 'static', 'final',
    'import', 'package', 'new', 'this', 'super'
  };

  /// Operadores unários e binários
  static const operadores = {
    '+', '-', '*', '/', '%', '=', '==', '!=', '<', '>', '<=', '>=',
    '&&', '||', '!', '++', '--', '+=', '-=', '*=', '/=',
    '&', '|', '^', '~', '<<', '>>', '>>>'
  };

  /// Símbolos especiais
  static const simbolos = {
    '(', ')', '{', '}', '[', ']', ';', ',', '.', ':', '?', '->'
  };

  TokenRecognizer(this.codigo);

  /// Adiciona um token à lista de tokens
  void adicionar(TokenType tipo, String lexema, [int? linhaToken, int? colunaToken]) {
    tokens.add(Token(tipo, lexema, linhaToken ?? linha, colunaToken ?? coluna));
  }

  void avancar() {
    pos++;
    coluna++;
  }

  String olharProximo() => pos + 1 < codigo.length ? codigo[pos + 1] : '';

  /// Lê uma string literal entre aspas duplas
  /// Trata strings com escape sequences básicas
  void lerString() {
    final inicio = pos;
    avancar(); // consome a primeira aspa
    
    while (pos < codigo.length && codigo[pos] != '"') {
      if (codigo[pos] == '\n') {
        return; // String não fechada - será tratada pelo error handler
      }
      
      // Tratar escape sequences básicas
      if (codigo[pos] == '\\' && pos + 1 < codigo.length) {
        pos++; // consome a barra
        final escapeChar = codigo[pos];
        switch (escapeChar) {
          case 'n': // \n
          case 't': // \t
          case 'r': // \r
          case '\\': // \\
          case '"': // \"
            pos++;
            break;
          default:
            pos++; // Escape inválido - será tratado pelo error handler
        }
      } else {
        pos++;
      }
    }
    
    if (pos >= codigo.length) {
      return; // String não fechada - será tratada pelo error handler
    }
    
    avancar(); // consome a aspa de fechamento
    final valor = codigo.substring(inicio, pos);
    adicionar(TokenType.string, valor);
  }

  /// Lê números inteiros e decimais
  /// Suporta notação científica básica
  void lerNumero() {
    final inicio = pos;
    
    // Parte inteira
    while (pos < codigo.length && _isDigit(codigo[pos])) {
      avancar();
    }
    
    // Ponto decimal
    if (pos < codigo.length && codigo[pos] == '.') {
      if (pos + 1 < codigo.length && _isDigit(codigo[pos + 1])) {
        avancar(); // consome o ponto
        while (pos < codigo.length && _isDigit(codigo[pos])) {
          avancar();
        }
      }
    }
    
    // Notação científica (e ou E)
    if (pos < codigo.length && (codigo[pos] == 'e' || codigo[pos] == 'E')) {
      avancar(); // consome e ou E
      if (pos < codigo.length && (codigo[pos] == '+' || codigo[pos] == '-')) {
        avancar(); // consome sinal do expoente
      }
      if (pos < codigo.length && _isDigit(codigo[pos])) {
        while (pos < codigo.length && _isDigit(codigo[pos])) {
          avancar();
        }
      } else {
        return; // Expoente inválido - será tratado pelo error handler
      }
    }
    
    final valor = codigo.substring(inicio, pos);
    
    // Validar formato do número
    if (valor.isEmpty) {
      return; // Número malformado - será tratado pelo error handler
    }
    
    adicionar(TokenType.numero, valor);
  }

  /// Lê identificadores e palavras reservadas
  /// Também reconhece literais booleanos (true, false)
  void lerIdentificadorOuPalavraReservada() {
    final inicio = pos;
    while (pos < codigo.length && _isLetterOrDigit(codigo[pos])) {
      avancar();
    }
    final valor = codigo.substring(inicio, pos);
    
    if (palavrasReservadas.contains(valor)) {
      // Verificar se é literal booleano
      if (valor == 'true' || valor == 'false') {
        adicionar(TokenType.booleano, valor);
      } else {
        adicionar(TokenType.palavraReservada, valor);
      }
    } else {
      adicionar(TokenType.identificador, valor);
    }
  }

  /// Lê operadores e símbolos, tratando operadores multi-caractere
  void lerOperadorOuSimbolo() {
    final char = codigo[pos];
    
    // Operadores de dois caracteres
    if (pos + 1 < codigo.length) {
      final doisChars = codigo.substring(pos, pos + 2);
      if (operadores.contains(doisChars)) {
        adicionar(TokenType.operador, doisChars);
        avancar();
        avancar();
        return;
      }
    }
    
    // Operadores e símbolos de um caractere
    if (operadores.contains(char)) {
      adicionar(TokenType.operador, char);
    } else if (simbolos.contains(char)) {
      adicionar(TokenType.simbolo, char);
    } else {
      return; // Operador inválido - será tratado pelo error handler
    }
    
    avancar();
  }

  /// Ignora comentários de linha (//)
  void ignorarComentarioLinha() {
    while (pos < codigo.length && codigo[pos] != '\n') {
      pos++;
    }
  }

  /// Ignora comentários de bloco (/* */)
  /// Retorna true se o comentário foi fechado corretamente
  bool ignorarComentarioBloco() {
    avancar(); // '/'
    avancar(); // '*'
    bool comentarioFechado = false;
    
    while (pos < codigo.length - 1) {
      if (codigo[pos] == '*' && codigo[pos + 1] == '/') {
        pos += 2;
        comentarioFechado = true;
        break;
      }
      if (codigo[pos] == '\n') {
        linha++;
        coluna = 1;
      }
      pos++;
    }
    
    return comentarioFechado;
  }

  // ===== Funções auxiliares para reconhecimento de caracteres =====
  
  /// Verifica se o caractere é um dígito
  bool _isDigit(String c) => RegExp(r'[0-9]').hasMatch(c);
  
  /// Verifica se o caractere é letra, dígito ou underscore
  bool _isLetterOrDigit(String c) => RegExp(r'[a-zA-Z0-9_]').hasMatch(c);
}
