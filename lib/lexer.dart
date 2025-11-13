import 'dart:io';

import 'token.dart';
import 'lex_error.dart';
import 'error_handler.dart';
import 'token_recognizer.dart';
import 'ambiguity_detector.dart';
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
  late final AmbiguityDetector _ambiguityDetector;

  /// Operadores unários e binários
  static const operadores = OPERADORES;
  static const simbolos = SIMBOLOS;

  Lexer(this.codigo) {
    _errorHandler = ErrorHandler();
    _tokenRecognizer = TokenRecognizer(codigo, _errorHandler);
    _ambiguityDetector = AmbiguityDetector(codigo);
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
  List<Token> analisar() {
    while (pos < codigo.length) {
      final char = codigo[pos];

      // Ignorar espaços em branco e tabulações
      if (char == ' ' || char == '\t') {
        avancar();
        continue;
      }
      
      // Tratar quebras de linha
      if (char == '\n') {
        linha++;
        coluna = 1;
        pos++;
        continue;
      }
      
      // Comentários de linha (//)
      if (char == '/' && olharProximo() == '/') {
        _tokenRecognizer.pos = pos;
        _tokenRecognizer.linha = linha;
        _tokenRecognizer.coluna = coluna;
        _tokenRecognizer.ignorarComentarioLinha();
        pos = _tokenRecognizer.pos;
        continue;
      }
      
      // Comentários de bloco (/* */)
      if (char == '/' && olharProximo() == '*') {
        _tokenRecognizer.pos = pos;
        _tokenRecognizer.linha = linha;
        _tokenRecognizer.coluna = coluna;
        
        final comentarioFechado = _tokenRecognizer.ignorarComentarioBloco();
        if (!comentarioFechado) {
          _errorHandler.adicionarErro('Comentário de bloco não fechado - possível ambiguidade sintática', linha, coluna, codigo, pos);
        }
        
        pos = _tokenRecognizer.pos;
        linha = _tokenRecognizer.linha;
        coluna = _tokenRecognizer.coluna;
        continue;
      }
      
      // Strings literais
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
      if (_isDigit(char)) {
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
      if (_isOperadorOuSimbolo(char)) {
        _tokenRecognizer.pos = pos;
        _tokenRecognizer.linha = linha;
        _tokenRecognizer.coluna = coluna;
        
        _tokenRecognizer.lerOperadorOuSimbolo();
        
        // Detectar ambiguidades
        _ambiguityDetector.atualizarPosicao(pos, linha, coluna);
        _ambiguityDetector.detectarAmbiguidades(char, (mensagem) {
          _errorHandler.adicionarErro(mensagem, linha, coluna, codigo, pos);
        });
        
        // Adicionar tokens reconhecidos
        tokens.addAll(_tokenRecognizer.tokens);
        _tokenRecognizer.tokens.clear();
        
        pos = _tokenRecognizer.pos;
        linha = _tokenRecognizer.linha;
        coluna = _tokenRecognizer.coluna;
        continue;
      }
      
      // Caractere inválido - erro léxico
      _errorHandler.adicionarErro('Caractere inválido: $char', linha, coluna, codigo, pos);
      avancar();
    }

    // Adicionar token de fim de arquivo
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
  void adicionar(TokenType tipo, String lexema, [int? linhaToken, int? colunaToken]) {
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
