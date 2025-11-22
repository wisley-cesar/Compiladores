import 'dart:io';

import 'token.dart';
import 'lex_error.dart';
import 'error_handler.dart';
import 'token_recognizer.dart';
import 'statistics.dart';
import 'lexical_definitions.dart';

/// Analisador léxico (Lexer) que converte código-fonte em tokens
/// Implementa um autômato finito determinístico (AFD) para reconhecimento de tokens
class Lexer {
  final String codigo;
  int pos = 0;
  int linha = 1;
  int coluna = 1;
  final List<Token> tokens = [];

  // Componentes modulares
  late final ErrorHandler _errorHandler;
  late final TokenRecognizer _tokenRecognizer;

  /// Operadores unários e binários
  static const operadores = operadoresSet;
  static const simbolos = simbolosSet;

  Lexer(this.codigo) {
    _errorHandler = ErrorHandler();
    _tokenRecognizer = TokenRecognizer(codigo, _errorHandler);
  }

  /// Cria um Lexer lendo o conteúdo de um arquivo no caminho [path].
  /// Lança [IOException] se não for possível ler o arquivo.
  factory Lexer.fromFile(String path) {
    final file = File(path);
    final src = file.readAsStringSync();
    return Lexer(src);
  }

  /// Método principal que analisa o código-fonte e retorna lista de tokens
  /// Implementa um AFD (Autômato Finito Determinístico) para reconhecimento
  ///
  /// Exemplo de uso:
  /// ```dart
  /// final lexer = Lexer('int x = 10;');
  /// final tokens = lexer.analisar();
  /// // Retorna: [
  /// //   Token(TokenType.palavraReservada, "int", linha: 1, col: 4),
  /// //   Token(TokenType.identificador, "x", linha: 1, col: 6),
  /// //   Token(TokenType.operador, "=", linha: 1, col: 8),
  /// //   Token(TokenType.numero, "10", linha: 1, col: 11),
  /// //   Token(TokenType.simbolo, ";", linha: 1, col: 12),
  /// //   Token(TokenType.eof, "EOF", linha: 1, col: 13)
  /// // ]
  /// ```
  List<Token> analisar() {
    while (pos < codigo.length) {
      final char = codigo[pos];

      // Ignorar espaços em branco e tabulações
      // Exemplo: "int x" -> espaços são ignorados, não geram tokens
      if (char == ' ' || char == '\t') {
        avancar();
        continue;
      }

      // Tratar quebras de linha (Unix e Windows)
      // Exemplo: "int x\nint y" -> incrementa linha, reseta coluna
      // Suporta \n (Unix) e \r\n (Windows)
      if (char == '\n' || char == '\r') {
        linha++;
        coluna = 1;
        pos++;
        if (char == '\r' && pos < codigo.length && codigo[pos] == '\n') {
          pos++;
        }
        continue;
      }

      // Comentários de linha (//)
      // Exemplo: "int x; // comentário" -> tudo após // é ignorado até \n
      // Entrada: "int x; // este é um comentário"
      // Tokens gerados: [int, x, ;] (comentário ignorado)
      if (char == '/' && olharProximo() == '/') {
        _tokenRecognizer.pos = pos;
        _tokenRecognizer.linha = linha;
        _tokenRecognizer.coluna = coluna;
        _tokenRecognizer.ignorarComentarioLinha();
        pos = _tokenRecognizer.pos;
        continue;
      }

      // Comentários de bloco (/* */)
      // Exemplo: "int x; /* comentário */ int y;" -> comentário ignorado
      // Entrada: "int x; /* comentário\nmultilinha */ int y;"
      // Tokens gerados: [int, x, ;, int, y, ;]
      // Erro se não fechado: "int x; /* comentário" -> erro léxico
      if (char == '/' && olharProximo() == '*') {
        _tokenRecognizer.pos = pos;
        _tokenRecognizer.linha = linha;
        _tokenRecognizer.coluna = coluna;

        final comentarioFechado = _tokenRecognizer.ignorarComentarioBloco();
        if (!comentarioFechado) {
          _errorHandler.adicionarErro(
            'Comentário de bloco não fechado - possível ambiguidade sintática',
            linha,
            coluna,
            codigo,
            pos,
          );
        }

        pos = _tokenRecognizer.pos;
        linha = _tokenRecognizer.linha;
        coluna = _tokenRecognizer.coluna;
        continue;
      }

      // Strings literais
      // Exemplo: '"Hello"' -> Token(TokenType.string, "Hello", ...)
      // Exemplo: '"Hello\\nWorld"' -> Token(TokenType.string, "Hello\nWorld", ...)
      // Exemplo: '"String não fechada -> erro léxico
      // Escape sequences suportadas: \n, \t, \", \\, \r, \0
      if (char == '"') {
        _tokenRecognizer.pos = pos;
        _tokenRecognizer.linha = linha;
        _tokenRecognizer.coluna = coluna;

        _tokenRecognizer.lerString();
        // Se o recognizer não produziu um token de string, ele já reportou o erro.
        // Apenas adicionamos tokens reconhecidos quando existirem.
        tokens.addAll(_tokenRecognizer.tokens);
        _tokenRecognizer.tokens.clear();

        pos = _tokenRecognizer.pos;
        linha = _tokenRecognizer.linha;
        coluna = _tokenRecognizer.coluna;
        continue;
      }

      // Números (inteiros e decimais)
      // Exemplo: "123" -> Token(TokenType.numero, "123", ...)
      // Exemplo: "3.14" -> Token(TokenType.numero, "3.14", ...)
      // Exemplo: "1.23e5" -> Token(TokenType.numero, "1.23e5", ...)
      // Exemplo: ".5" -> Token(TokenType.numero, ".5", ...) (aceita ponto inicial)
      // Exemplo: "123." -> Token(TokenType.numero, "123.", ...) (aceita ponto final)
      if (_isDigit(char) || (char == '.' && _isDigit(olharProximo()))) {
        _tokenRecognizer.pos = pos;
        _tokenRecognizer.linha = linha;
        _tokenRecognizer.coluna = coluna;

        _tokenRecognizer.lerNumero();

        // Adicionar tokens reconhecidos
        tokens.addAll(_tokenRecognizer.tokens);
        _tokenRecognizer.tokens.clear();

        pos = _tokenRecognizer.pos;
        linha = _tokenRecognizer.linha;
        coluna = _tokenRecognizer.coluna;
        continue;
      }

      // Identificadores e palavras reservadas
      // Exemplo: "x" -> Token(TokenType.identificador, "x", ...)
      // Exemplo: "if" -> Token(TokenType.palavraReservada, "if", ...)
      // Exemplo: "var123" -> Token(TokenType.identificador, "var123", ...)
      // Exemplo: "_variavel" -> Token(TokenType.identificador, "_variavel", ...)
      // Regex: [a-zA-Z_][a-zA-Z0-9_]*
      if (_isLetter(char)) {
        _tokenRecognizer.pos = pos;
        _tokenRecognizer.linha = linha;
        _tokenRecognizer.coluna = coluna;

        _tokenRecognizer.lerIdentificadorOuPalavraReservada();

        // Adicionar tokens reconhecidos
        tokens.addAll(_tokenRecognizer.tokens);
        _tokenRecognizer.tokens.clear();

        pos = _tokenRecognizer.pos;
        linha = _tokenRecognizer.linha;
        coluna = _tokenRecognizer.coluna;
        continue;
      }

      // Operadores e símbolos
      // Exemplo: "+" -> Token(TokenType.operador, "+", ...)
      // Exemplo: "==" -> Token(TokenType.operador, "==", ...) (greedy matching)
      // Exemplo: ">>>" -> Token(TokenType.operador, ">>>", ...) (prioriza 3 chars)
      // Exemplo: "(" -> Token(TokenType.simbolo, "(", ...)
      // Greedy matching: sempre reconhece o token mais longo possível
      if (_isOperadorOuSimbolo(char)) {
        _tokenRecognizer.pos = pos;
        _tokenRecognizer.linha = linha;
        _tokenRecognizer.coluna = coluna;

        _tokenRecognizer.lerOperadorOuSimbolo();

        // Adicionar tokens reconhecidos
        tokens.addAll(_tokenRecognizer.tokens);
        _tokenRecognizer.tokens.clear();

        pos = _tokenRecognizer.pos;
        linha = _tokenRecognizer.linha;
        coluna = _tokenRecognizer.coluna;
        continue;
      }

      // Caractere inválido - erro léxico
      // Exemplo: "int x @ 10;" -> erro: "Caractere inválido: @" na linha 1, coluna 7
      _errorHandler.adicionarErro(
        'Caractere inválido: $char',
        linha,
        coluna,
        codigo,
        pos,
      );
      avancar();
    }

    // Adicionar token de fim de arquivo
    // Sempre adicionado ao final para marcar o término da análise
    adicionar(TokenType.eof, 'EOF', linha, coluna);
    return tokens;
  }

  // ===== Funções auxiliares =====

  void avancar() {
    pos++;
    coluna++;
  }

  String olharProximo() => pos + 1 < codigo.length ? codigo[pos + 1] : '';

  /// Adiciona um token à lista de tokens
  void adicionar(
    TokenType tipo,
    String lexema, [
    int? linhaToken,
    int? colunaToken,
  ]) {
    tokens.add(Token(tipo, lexema, linhaToken ?? linha, colunaToken ?? coluna));
  }

  /// Verifica se há erros léxicos
  bool get temErros => _errorHandler.temErros;

  /// Retorna a lista de erros encontrados
  List<String> get listaErros => _errorHandler.listaErros;

  /// Retorna a lista de erros estruturados (LexError)
  List<LexError> get listaErrosEstruturados => _errorHandler.listaLexErrors;

  // ===== Funções auxiliares para reconhecimento de caracteres =====

  /// Verifica se o caractere é um dígito
  bool _isDigit(String c) => RegExp(r'[0-9]').hasMatch(c);

  /// Verifica se o caractere é uma letra ou underscore
  bool _isLetter(String c) => RegExp(r'[a-zA-Z_]').hasMatch(c);

  /// Verifica se o caractere é um operador ou símbolo válido
  bool _isOperadorOuSimbolo(String c) {
    return operadores.contains(c) || simbolos.contains(c);
  }

  /// Retorna estatísticas do lexer
  Map<String, dynamic> getEstatisticas() {
    final statistics = Statistics(tokens, _errorHandler.listaLexErrors, linha);
    return statistics.getEstatisticas();
  }

  /// Imprime relatório detalhado da análise léxica
  void imprimirRelatorio() {
    final statistics = Statistics(tokens, _errorHandler.listaLexErrors, linha);
    statistics.imprimirRelatorio();
  }
}
