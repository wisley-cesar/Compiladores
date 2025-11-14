import 'package:compilador/token_stream.dart';
import 'package:compilador/token.dart';
import 'package:compilador/ast/ast.dart';
import 'package:compilador/parse_error.dart';
import 'package:compilador/error_context.dart';

class Parser {
  final TokenStream tokens;
  final String src;
  final List<ParseError> errors = [];

  /// [src] é opcional para compatibilidade; se fornecido, será usado para
  /// preencher o campo `contexto` nos erros.
  Parser(this.tokens, [this.src = '']);

  Program parseProgram() {
    final stmts = <Stmt>[];
    // First, parse zero or more declarations
    while (!tokens.isAtEnd) {
      // If next token starts a declaration (type keyword), parse declaration
      final t = tokens.peek();
      if (_isTypeKeyword(t)) {
        final d = parseDeclaration();
        if (d != null) stmts.add(d);
        continue;
      }
      // Otherwise parse commands/statements until EOF
      final s = parseCommand();
      if (s != null) stmts.add(s);
      // if s is null, parser recovered and we continue
      if (tokens.isAtEnd) break;
    }
    return Program(List.unmodifiable(stmts));
  }

  // --- Declarations -------------------------------------------------
  bool _isTypeKeyword(Token t) {
    return t.tipo == TokenType.palavraReservada &&
        (t.lexema == 'int' ||
            t.lexema == 'float' ||
            t.lexema == 'bool' ||
            t.lexema == 'string' ||
            t.lexema == 'uids');
  }

  VarDecl? parseDeclaration() {
    Token kw;
    try {
      kw = tokens.expect(TokenType.palavraReservada);
    } on StateError catch (_) {
      final t = tokens.peek();
      errors.add(
        ParseError(
          'Esperado tipo de declaração, encontrado ${t.lexema}',
          linha: t.linha,
          coluna: t.coluna,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      _synchronize();
      return null;
    }

    // esperar identificador
    Token id;
    try {
      id = tokens.expect(TokenType.identificador);
    } on StateError catch (_) {
      final t = tokens.peek();
      errors.add(
        ParseError(
          'Esperado identificador após tipo "${kw.lexema}" mas encontrado ${t.tipo} "${t.lexema}"',
          linha: t.linha,
          coluna: t.coluna,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      _synchronize();
      return null;
    }

    // opcional inicializador: '=' Expression
    Expr? init;
    final next = tokens.peek();
    if (next.tipo == TokenType.operador && next.lexema == '=') {
      tokens.next();
      init = parseExpression();
    }

    // ponto e vírgula obrigatório
    final semi = tokens.peek();
    if (semi.tipo == TokenType.simbolo && semi.lexema == ';') {
      tokens.next();
    } else {
      errors.add(
        ParseError(
          'Esperado ";" após declaração na linha ${semi.linha}, coluna ${semi.coluna}',
          linha: semi.linha,
          coluna: semi.coluna,
          contexto: extractLineContext(src, semi.linha),
        ),
      );
      _synchronize();
      return null;
    }

    return VarDecl(kw.lexema, id.lexema, init, kw.linha, kw.coluna);
  }

  // --- Commands / Statements ----------------------------------------
  Stmt? parseCommand() {
    final t = tokens.peek();
    // empty statement
    if (t.tipo == TokenType.simbolo && t.lexema == ';') {
      tokens.next();
      return null;
    }

    if (t.tipo == TokenType.palavraReservada) {
      if (t.lexema == 'if') return parseIf();
      if (t.lexema == 'while') return parseWhile();
      // a palavra reservada pode iniciar um declaration; handle in parseProgram
    }

    if (t.tipo == TokenType.simbolo && t.lexema == '{') return parseBlock();

    // assignment: IDENT '=' Expression ';'
    if (t.tipo == TokenType.identificador &&
        tokens.peek(1).tipo == TokenType.operador &&
        tokens.peek(1).lexema == '=') {
      return parseAssignment();
    }

    // Unknown token at statement start: consume and report
    if (t.tipo == TokenType.eof) return null;
    errors.add(
      ParseError(
        'Token inesperado no início de comando: ${t.lexema}',
        linha: t.linha,
        coluna: t.coluna,
        contexto: extractLineContext(src, t.linha),
      ),
    );
    tokens.next();
    _synchronize();
    return null;
  }

  Assign? parseAssignment() {
    Token idTok;
    try {
      idTok = tokens.expect(TokenType.identificador);
    } on StateError catch (_) {
      final t = tokens.peek();
      errors.add(
        ParseError(
          'Esperado identificador para atribuição, encontrado ${t.lexema}',
          linha: t.linha,
          coluna: t.coluna,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      _synchronize();
      return null;
    }

    try {
      tokens.expect(TokenType.operador, '=');
    } on StateError catch (_) {
      final t = tokens.peek();
      errors.add(
        ParseError(
          'Esperado "=" após identificador na atribuição, encontrado ${t.lexema}',
          linha: t.linha,
          coluna: t.coluna,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      _synchronize();
      return null;
    }

    final value = parseExpression();

    final semi = tokens.peek();
    if (semi.tipo == TokenType.simbolo && semi.lexema == ';') {
      tokens.next();
    } else {
      errors.add(
        ParseError(
          'Esperado ";" após atribuição na linha ${semi.linha}, coluna ${semi.coluna}',
          linha: semi.linha,
          coluna: semi.coluna,
          contexto: extractLineContext(src, semi.linha),
        ),
      );
      _synchronize();
      return null;
    }

    return Assign(
      Identifier(idTok.lexema, idTok.linha, idTok.coluna),
      value,
      idTok.linha,
      idTok.coluna,
    );
  }

  IfStmt? parseIf() {
    final kw = tokens.next(); // consume 'if'
    // '(' Expression ')'
    try {
      tokens.expect(TokenType.simbolo, '(');
    } on StateError catch (_) {
      final t = tokens.peek();
      errors.add(
        ParseError(
          'Esperado "(" após "if" na linha ${t.linha}, coluna ${t.coluna}',
          linha: t.linha,
          coluna: t.coluna,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      _synchronize();
      return null;
    }

    final condition = parseExpression();

    if (!(tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ')')) {
      final t = tokens.peek();
      errors.add(
        ParseError(
          'Esperado ")" após condição do if na linha ${t.linha}, coluna ${t.coluna}',
          linha: t.linha,
          coluna: t.coluna,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      _synchronize();
      return null;
    }
    tokens.next(); // consume ')'

    final thenBranch = parseCommand();
    Stmt? elseBranch;
    if (tokens.peek().tipo == TokenType.palavraReservada &&
        tokens.peek().lexema == 'else') {
      tokens.next();
      elseBranch = parseCommand();
    }

    if (thenBranch == null) {
      errors.add(
        ParseError(
          'Bloco "then" do if ausente ou inválido na linha ${kw.linha}, coluna ${kw.coluna}',
          linha: kw.linha,
          coluna: kw.coluna,
          contexto: extractLineContext(src, kw.linha),
        ),
      );
      return null;
    }

    return IfStmt(condition, thenBranch, elseBranch, kw.linha, kw.coluna);
  }

  WhileStmt? parseWhile() {
    final kw = tokens.next();
    try {
      tokens.expect(TokenType.simbolo, '(');
    } on StateError catch (_) {
      final t = tokens.peek();
      errors.add(
        ParseError(
          'Esperado "(" após "while" na linha ${t.linha}, coluna ${t.coluna}',
          linha: t.linha,
          coluna: t.coluna,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      _synchronize();
      return null;
    }
    final condition = parseExpression();
    if (!(tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ')')) {
      final t = tokens.peek();
      errors.add(
        ParseError(
          'Esperado ")" após condição do while na linha ${t.linha}, coluna ${t.coluna}',
          linha: t.linha,
          coluna: t.coluna,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      _synchronize();
      return null;
    }
    tokens.next(); // consume ')'

    final body = parseCommand();
    if (body == null) {
      errors.add(
        ParseError(
          'Corpo do while ausente ou inválido na linha ${kw.linha}, coluna ${kw.coluna}',
          linha: kw.linha,
          coluna: kw.coluna,
          contexto: extractLineContext(src, kw.linha),
        ),
      );
      return null;
    }
    return WhileStmt(condition, body, kw.linha, kw.coluna);
  }

  Block? parseBlock() {
    final open = tokens.next(); // consume '{'
    final stmts = <Stmt>[];
    while (!tokens.isAtEnd &&
        !(tokens.peek().tipo == TokenType.simbolo &&
            tokens.peek().lexema == '}')) {
      final s = parseCommand();
      if (s != null) stmts.add(s);
    }
    if (tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == '}') {
      tokens.next();
      return Block(List.unmodifiable(stmts), open.linha, open.coluna);
    } else {
      final t = tokens.peek();
      errors.add(
        ParseError(
          'Bloco não fechado: esperado "}" antes da linha ${t.linha}, coluna ${t.coluna}',
          linha: t.linha,
          coluna: t.coluna,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      _synchronize();
      return Block(List.unmodifiable(stmts), open.linha, open.coluna);
    }
  }

  VarDecl? parseVarDecl() {
    final kw = tokens.expect(TokenType.palavraReservada);
    if (kw.lexema != 'uids') {
      throw StateError(
        'Esperado palavra reservada uids, mas achado ${kw.lexema}',
      );
    }
    Token id;
    try {
      id = tokens.expect(TokenType.identificador);
    } on StateError catch (_) {
      // registrar erro de parsing mais amigável: identificador esperado após 'uids'
      final t = tokens.peek();
      final msg =
          'Esperado identificador após "uids" mas encontrado ${t.tipo} "${t.lexema}" na linha ${t.linha}, coluna ${t.coluna}';
      errors.add(
        ParseError(
          msg,
          linha: t.linha,
          coluna: t.coluna,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      // Tentar detectar erro consequente: falta de ponto-e-vírgula
      // Escaneia lookahead sem consumir tokens
      bool foundSemi = false;
      Token nextTok = tokens.peek();
      for (var off = 0; off < 1000; off++) {
        final t = tokens.peek(off);
        nextTok = t;
        if (t.tipo == TokenType.simbolo && t.lexema == ';') {
          foundSemi = true;
          break;
        }
        if (t.tipo == TokenType.palavraReservada || t.tipo == TokenType.eof) {
          break;
        }
      }
      if (!foundSemi) {
        final msg2 = nextTok.tipo == TokenType.eof
            ? 'Esperado ";" antes do fim de arquivo após declaração de variável'
            : 'Esperado ";" antes de "${nextTok.lexema}" na linha ${nextTok.linha}, coluna ${nextTok.coluna}';
        errors.add(
          ParseError(
            msg2,
            linha: nextTok.linha,
            coluna: nextTok.coluna,
            contexto: extractLineContext(src, nextTok.linha),
          ),
        );
      }

      _synchronize();
      // retornar null para indicar declaração inválida
      return null;
    }
    Expr? init;
    final next = tokens.peek();
    if (next.tipo == TokenType.operador && next.lexema == '=') {
      tokens.next(); // consume '='
      init = parseExpression();
    }

    // esperar ponto e vírgula
    final semi = tokens.peek();
    if (semi.tipo == TokenType.simbolo && semi.lexema == ';') {
      tokens.next();
    } else {
      // registrar erro, sincronizar e continuar
      final msg =
          'Esperado ";" após declaração na linha ${semi.linha}, coluna ${semi.coluna}';
      errors.add(
        ParseError(
          msg,
          linha: semi.linha,
          coluna: semi.coluna,
          contexto: extractLineContext(src, semi.linha),
        ),
      );
      _synchronize();
      return null;
    }

    return VarDecl(kw.lexema, id.lexema, init, kw.linha, kw.coluna);
  }

  /// Entry point with lowest precedence
  Expr parseExpression() => _parseLogicalOr();

  Expr _parseLogicalOr() {
    var node = _parseLogicalAnd();
    while (true) {
      final t = tokens.peek();
      if (t.tipo == TokenType.operador && t.lexema == '||') {
        final opTok = tokens.next();
        final right = _parseLogicalAnd();
        node = Binary(node, '||', right, opTok.linha, opTok.coluna);
      } else {
        break;
      }
    }
    return node;
  }

  Expr _parseLogicalAnd() {
    var node = _parseEquality();
    while (true) {
      final t = tokens.peek();
      if (t.tipo == TokenType.operador && t.lexema == '&&') {
        final opTok = tokens.next();
        final right = _parseEquality();
        node = Binary(node, '&&', right, opTok.linha, opTok.coluna);
      } else {
        break;
      }
    }
    return node;
  }

  Expr _parseEquality() {
    var node = _parseRelational();
    while (true) {
      final t = tokens.peek();
      if (t.tipo == TokenType.operador &&
          (t.lexema == '==' || t.lexema == '!=')) {
        final opTok = tokens.next();
        final right = _parseRelational();
        node = Binary(node, opTok.lexema, right, opTok.linha, opTok.coluna);
      } else {
        break;
      }
    }
    return node;
  }

  Expr _parseRelational() {
    var node = _parseAdditive();
    while (true) {
      final t = tokens.peek();
      if (t.tipo == TokenType.operador &&
          (t.lexema == '<' ||
              t.lexema == '>' ||
              t.lexema == '<=' ||
              t.lexema == '>=')) {
        final opTok = tokens.next();
        final right = _parseAdditive();
        node = Binary(node, opTok.lexema, right, opTok.linha, opTok.coluna);
      } else {
        break;
      }
    }
    return node;
  }

  Expr _parseAdditive() {
    var node = _parseMultiplicative();
    while (true) {
      final t = tokens.peek();
      if (t.tipo == TokenType.operador &&
          (t.lexema == '+' || t.lexema == '-')) {
        final opTok = tokens.next();
        final right = _parseMultiplicative();
        node = Binary(node, opTok.lexema, right, opTok.linha, opTok.coluna);
      } else {
        break;
      }
    }
    return node;
  }

  Expr _parseMultiplicative() {
    var node = _parseUnary();
    while (true) {
      final t = tokens.peek();
      if (t.tipo == TokenType.operador &&
          (t.lexema == '*' || t.lexema == '/')) {
        final opTok = tokens.next();
        final right = _parseUnary();
        node = Binary(node, opTok.lexema, right, opTok.linha, opTok.coluna);
      } else {
        break;
      }
    }
    return node;
  }

  Expr _parseUnary() {
    final t = tokens.peek();
    if (t.tipo == TokenType.operador &&
        (t.lexema == '+' || t.lexema == '-' || t.lexema == '!')) {
      final opTok = tokens.next();
      final op = opTok.lexema;
      final operand = _parseUnary();
      return Unary(op, operand, opTok.linha, opTok.coluna);
    }
    return _parsePrimary();
  }

  Expr _parsePrimary() {
    final t = tokens.peek();
    if (t.tipo == TokenType.numero) {
      final tok = tokens.next();
      final lex = tok.lexema;
      final kind = _numberKind(lex);
      return Literal(lex, kind, tok.linha, tok.coluna);
    }
    if (t.tipo == TokenType.string) {
      final tok = tokens.next();
      return Literal(tok.lexema, 'string', tok.linha, tok.coluna);
    }
    if (t.tipo == TokenType.booleano) {
      final tok = tokens.next();
      return Literal(tok.lexema, 'bool', tok.linha, tok.coluna);
    }
    if (t.tipo == TokenType.identificador) {
      final tok = tokens.next();
      return Identifier(tok.lexema, tok.linha, tok.coluna);
    }
    if (t.tipo == TokenType.simbolo && t.lexema == '(') {
      tokens.next();
      final e = parseExpression();
      final close = tokens.peek();
      if (close.tipo == TokenType.simbolo && close.lexema == ')') {
        tokens.next();
        return e;
      } else {
        // registrar erro de parsing e sincronizar
        final msg =
            'Parêntese ")" esperado na linha ${close.linha}, coluna ${close.coluna}';
        errors.add(
          ParseError(
            msg,
            linha: close.linha,
            coluna: close.coluna,
            contexto: extractLineContext(src, close.linha),
          ),
        );
        _synchronize();
        return e;
      }
    }

    // fallback
    final tok = tokens.next();
    return Literal('null', 'dynamic', tok.linha, tok.coluna);
  }

  String _numberKind(String lex) {
    final l = lex.toLowerCase();
    if (l.contains('.') || l.contains('e')) return 'double';
    return 'int';
  }

  /// Avança até encontrar um ponto-e-vírgula ou EOF para recuperar o fluxo
  void _synchronize() {
    while (!tokens.isAtEnd) {
      final t = tokens.peek();
      // Stop when we find a semicolon (end of statement)
      if (t.tipo == TokenType.simbolo && t.lexema == ';') {
        tokens.next();
        return;
      }
      // Additionally, stop at the beginning of a new declaration/statement
      // represented by a reserved word like 'uids', 'int', etc., so that
      // recovery returns control to the parser at a sensible boundary.
      if (t.tipo == TokenType.palavraReservada) {
        return; // don't consume - allow outer loop to handle the token
      }
      tokens.next();
    }
  }
}
