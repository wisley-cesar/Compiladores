import 'token.dart';
import 'lexical_definitions.dart';
import 'error_handler.dart';

/// Classe responsável pelo reconhecimento de tokens específicos
class TokenRecognizer {
  final String codigo;
  final ErrorHandler? errorHandler;
  int pos = 0;
  int linha = 1;
  int coluna = 1;
  final List<Token> tokens = [];

  /// Usa definições centralizadas
  static const palavrasReservadas = palavrasReservadasSet;
  static const operadores = operadoresSet;
  static const simbolos = simbolosSet;

  TokenRecognizer(this.codigo, [this.errorHandler]);

  /// Adiciona um token à lista de tokens
  void adicionar(
    TokenType tipo,
    String lexema, [
    int? linhaToken,
    int? colunaToken,
  ]) {
    tokens.add(Token(tipo, lexema, linhaToken ?? linha, colunaToken ?? coluna));
  }

  void avancar() {
    if (pos >= codigo.length) return;
    if (codigo[pos] == '\n') {
      pos++;
      linha++;
      coluna = 1;
    } else {
      pos++;
      coluna++;
    }
  }

  String olharProximo() => pos + 1 < codigo.length ? codigo[pos + 1] : '';

  /// Lê uma string literal entre aspas duplas
  /// Trata strings com escape sequences básicas
  /// 
  /// Escape sequences suportadas:
  /// - \n : nova linha
  /// - \t : tabulação
  /// - \" : aspas duplas
  /// - \\ : barra invertida
  /// - \r : retorno de carro
  /// - \0 : caractere nulo
  /// 
  /// Qualquer outro escape sequence será tratado como erro léxico.
  void lerString() {
    final startLinha = linha;
    final startColuna = coluna;
    final start = pos; // índice da aspa de abertura
    avancar(); // consome a primeira aspa

    while (pos < codigo.length && codigo[pos] != '"') {
      if (codigo[pos] == '\n') {
        // String não fechada: reportar erro e retornar mantendo pos onde está
        errorHandler?.adicionarErro(
          'String não fechada - quebra de linha dentro da string',
          startLinha,
          startColuna,
          codigo,
          start,
        );
        return;
      }

      // Tratar escape sequences
      if (codigo[pos] == '\\' && pos + 1 < codigo.length) {
        final escapePos = pos;
        avancar(); // consome a barra invertida
        
        // Valida o caractere após a barra invertida
        final escapeChar = pos < codigo.length ? codigo[pos] : '';
        const escapeSequencesValidas = ['n', 't', '"', '\\', 'r', '0'];
        
        if (!escapeSequencesValidas.contains(escapeChar)) {
          // Escape sequence inválida
          errorHandler?.adicionarErro(
            'Escape sequence inválida: \\$escapeChar. Escape sequences válidas: \\n, \\t, \\", \\\\, \\r, \\0',
            linha,
            coluna,
            codigo,
            escapePos,
          );
          // Continua processamento, tratando como caractere literal
        }
        
        // Consome o caractere escapado
        if (pos < codigo.length) {
          avancar();
        }
      } else {
        avancar();
      }
    }

    if (pos >= codigo.length) {
      // EOF sem fechar string
      errorHandler?.adicionarErro(
        'String não fechada - fim de arquivo inesperado',
        startLinha,
        startColuna,
        codigo,
        start,
      );
      return;
    }

    // consome a aspa de fechamento
    avancar();
    // extrai o conteúdo entre aspas (sem as aspas)
    final valor = codigo.substring(start + 1, pos - 1);
    adicionar(TokenType.string, valor, startLinha, startColuna);
  }

  /// Lê números inteiros e decimais (com ou sem parte inteira) e notação científica
  /// 
  /// Formatos aceitos:
  /// - Inteiros: `123`, `0`, `42`
  /// - Decimais com parte inteira: `1.5`, `123.456`
  /// - Decimais sem parte inteira: `.5`, `.123` (aceito)
  /// - Decimais sem parte fracionária: `5.` (não aceito - gera erro)
  /// - Notação científica: `1.23e5`, `1.23e+5`, `1.23e-5`, `.5e10`
  /// 
  /// Validações:
  /// - Pelo menos um dígito deve ser consumido
  /// - Expoente deve ser seguido de dígitos (opcionalmente precedido de + ou -)
  /// - Números malformados geram erro léxico
  void lerNumero() {
    final startLinha = linha;
    final startColuna = coluna;
    final inicio = pos;

    bool consumiuDigito = false;

    void consumirDigitos() {
      while (pos < codigo.length && _isDigit(codigo[pos])) {
        avancar();
        consumiuDigito = true;
      }
    }

    // Aceita números começando com dígito ou com ponto (ex: .5)
    if (_isDigit(codigo[pos])) {
      consumirDigitos();
    } else if (codigo[pos] == '.') {
      avancar(); // consome o ponto inicial
      if (pos < codigo.length && _isDigit(codigo[pos])) {
        consumiuDigito = true;
        consumirDigitos();
      } else {
        // Ponto sem dígito após - erro
        errorHandler?.adicionarErro(
          'Número malformado - ponto sem dígitos',
          startLinha,
          startColuna,
          codigo,
          inicio,
        );
        return;
      }
    }

    // Parte fracionária opcional
    if (pos < codigo.length && codigo[pos] == '.') {
      final look = pos + 1;
      if (look < codigo.length && _isDigit(codigo[look])) {
        avancar(); // consome '.'
        consumirDigitos();
      }
    }

    // Notação científica
    if (pos < codigo.length && (codigo[pos] == 'e' || codigo[pos] == 'E')) {
      final savedPos = pos;
      final savedLinha = linha;
      final savedColuna = coluna;
      int look = pos + 1;
      if (look < codigo.length &&
          (codigo[look] == '+' || codigo[look] == '-')) {
        look++;
      }
      if (look < codigo.length && _isDigit(codigo[look])) {
        avancar(); // e/E
        if (pos < codigo.length && (codigo[pos] == '+' || codigo[pos] == '-')) {
          avancar();
        }
        consumirDigitos();
      } else {
        errorHandler?.adicionarErro(
          'Expoente inválido em número - deve ser seguido de dígitos',
          startLinha,
          startColuna,
          codigo,
          savedPos,
        );
        pos = savedPos;
        linha = savedLinha;
        coluna = savedColuna;
      }
    }

    final valor = codigo.substring(inicio, pos);

    // Validação final: deve ter consumido pelo menos um dígito
    if (!consumiuDigito || valor == '.' || valor.isEmpty) {
      errorHandler?.adicionarErro(
        'Número malformado - formato inválido',
        startLinha,
        startColuna,
        codigo,
        inicio,
      );
      return;
    }

    adicionar(TokenType.numero, valor, startLinha, startColuna);
  }

  /// Lê identificadores e palavras reservadas
  /// Também reconhece literais booleanos (true, false)
  void lerIdentificadorOuPalavraReservada() {
    final startLinha = linha;
    final startColuna = coluna;
    final inicio = pos;
    while (pos < codigo.length && _isLetterOrDigit(codigo[pos])) {
      avancar();
    }
    final valor = codigo.substring(inicio, pos);

    if (palavrasReservadas.contains(valor)) {
      // Verificar se é literal booleano
      if (valor == 'true' || valor == 'false') {
        adicionar(TokenType.booleano, valor, startLinha, startColuna);
      } else {
        adicionar(TokenType.palavraReservada, valor, startLinha, startColuna);
      }
    } else {
      adicionar(TokenType.identificador, valor, startLinha, startColuna);
    }
  }

  /// Lê operadores e símbolos, tratando operadores multi-caractere
  void lerOperadorOuSimbolo() {
    final startLinha = linha;
    final startColuna = coluna;
    // tentar operadores/símbolos de 3, 2 e 1 caracteres (priorizar maior)
    if (pos + 2 < codigo.length) {
      final tres = codigo.substring(pos, pos + 3);
      if (operadores.contains(tres) || simbolos.contains(tres)) {
        if (operadores.contains(tres)) {
          adicionar(TokenType.operador, tres, startLinha, startColuna);
        } else {
          adicionar(TokenType.simbolo, tres, startLinha, startColuna);
        }
        avancar();
        avancar();
        avancar();
        return;
      }
    }

    if (pos + 1 < codigo.length) {
      final doisChars = codigo.substring(pos, pos + 2);
      if (operadores.contains(doisChars) || simbolos.contains(doisChars)) {
        if (operadores.contains(doisChars)) {
          adicionar(TokenType.operador, doisChars, startLinha, startColuna);
        } else {
          adicionar(TokenType.simbolo, doisChars, startLinha, startColuna);
        }
        avancar();
        avancar();
        return;
      }
    }

    final char = codigo[pos];
    if (operadores.contains(char)) {
      adicionar(TokenType.operador, char, startLinha, startColuna);
      avancar();
      return;
    } else if (simbolos.contains(char)) {
      adicionar(TokenType.simbolo, char, startLinha, startColuna);
      avancar();
      return;
    } else {
      // operador inválido - reportar
      errorHandler?.adicionarErro(
        'Operador inválido: $char',
        linha,
        coluna,
        codigo,
        pos,
      );
      avancar();
      return;
    }
  }

  /// Ignora comentários de linha (//)
  void ignorarComentarioLinha() {
    // assumir pos apontando para a primeira '/' do '//'
    // consumir '//' primeiro
    if (pos < codigo.length && codigo[pos] == '/') avancar();
    if (pos < codigo.length && codigo[pos] == '/') avancar();
    while (pos < codigo.length && codigo[pos] != '\n') {
      avancar();
    }
    // não consumir a quebra de linha aqui; o chamador/avancar tratará do '\n'
  }

  /// Ignora comentários de bloco (/* */)
  /// Retorna true se o comentário foi fechado corretamente
  bool ignorarComentarioBloco() {
    // assumir pos apontando para a primeira '/' do '/*'
    if (pos < codigo.length && codigo[pos] == '/') avancar();
    if (pos < codigo.length && codigo[pos] == '*') avancar();
    bool comentarioFechado = false;

    while (pos < codigo.length - 1) {
      if (codigo[pos] == '*' && codigo[pos + 1] == '/') {
        avancar();
        avancar();
        comentarioFechado = true;
        break;
      }
      avancar();
    }

    return comentarioFechado;
  }

  // ===== Funções auxiliares para reconhecimento de caracteres =====

  /// Verifica se o caractere é um dígito
  bool _isDigit(String c) => RegExp(r'[0-9]').hasMatch(c);

  /// Verifica se o caractere é letra, dígito ou underscore
  bool _isLetterOrDigit(String c) => RegExp(r'[a-zA-Z0-9_]').hasMatch(c);
}
