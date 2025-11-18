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
        // detect function declaration: type IDENT '('
        if ((tokens.peek(1).tipo == TokenType.identificador ||
                tokens.peek(1).tipo == TokenType.palavraReservada) &&
            tokens.peek(2).tipo == TokenType.simbolo &&
            tokens.peek(2).lexema == '(') {
          final f = parseFunctionDecl();
          if (f != null) stmts.add(f);
          continue;
        }
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
        ParseError.expected(
          'tipo (int|float|bool|string|uids)',
          t,
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
        ParseError.expected(
          'identificador',
          t,
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
        ParseError.expected(
          ';',
          semi,
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

    // Allow declarations anywhere (e.g., inside blocks) by detecting
    // type keywords at statement start and parsing a VarDecl.
    if (_isTypeKeyword(t)) {
      return parseDeclaration();
    }

    if (t.tipo == TokenType.palavraReservada) {
      if (t.lexema == 'if') return parseIf();
      if (t.lexema == 'while') return parseWhile();
      if (t.lexema == 'for') return parseFor();
      if (t.lexema == 'return') return parseReturn();
      // function declarations may start with modifiers or a return type
      if (t.lexema == 'public' || t.lexema == 'static' || _isTypeKeyword(t)) {
        // try to parse a function declaration if looks like one
        // We peek ahead to see identifier and '('
        if (tokens.peek(1).tipo == TokenType.identificador &&
            tokens.peek(2).tipo == TokenType.simbolo &&
            tokens.peek(2).lexema == '(') {
          return parseFunctionDecl();
        }
      }
    }

    if (t.tipo == TokenType.simbolo && t.lexema == '{') return parseBlock();

    // assignment: IDENT '=' Expression ';'
    if (t.tipo == TokenType.identificador &&
        tokens.peek(1).tipo == TokenType.operador &&
        tokens.peek(1).lexema == '=') {
      return parseAssignment();
    }

    // expression statement (function calls, bare expressions):
    // allow starting tokens that can begin an expression
    if (t.tipo == TokenType.identificador ||
        t.tipo == TokenType.numero ||
        t.tipo == TokenType.string ||
        t.tipo == TokenType.booleano ||
        (t.tipo == TokenType.simbolo && t.lexema == '(') ||
        (t.tipo == TokenType.operador &&
            (t.lexema == '+' || t.lexema == '-' || t.lexema == '!'))) {
      final expr = parseExpression();
      final semi = tokens.peek();
      if (semi.tipo == TokenType.simbolo && semi.lexema == ';') {
        tokens.next();
        return ExprStmt(expr, t.linha, t.coluna);
      } else {
        errors.add(
          ParseError.expected(
            ';',
            semi,
            contexto: extractLineContext(src, semi.linha),
          ),
        );
        _synchronize();
        return null;
      }
    }

    // Unknown token at statement start: consume and report
    if (t.tipo == TokenType.eof) return null;
    errors.add(
      ParseError.unexpected(t, contexto: extractLineContext(src, t.linha)),
    );
    tokens.next();
    _synchronize();
    return null;
  }

  ForStmt? parseFor() {
    final kw = tokens.next(); // consume 'for'
    // expect '('
    try {
      tokens.expect(TokenType.simbolo, '(');
    } on StateError catch (_) {
      final t = tokens.peek();
      errors.add(
        ParseError.expected('(', t, contexto: extractLineContext(src, t.linha)),
      );
      _synchronize();
      return null;
    }

    // forInit ::= varDecl | exprStmt | empty
    Stmt? init;
    if (_isTypeKeyword(tokens.peek())) {
      init = parseDeclaration();
    } else if (!(tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ';')) {
      // if looks like an assignment statement, parse as such
      if (tokens.peek().tipo == TokenType.identificador &&
          tokens.peek(1).tipo == TokenType.operador &&
          tokens.peek(1).lexema == '=') {
        init = parseAssignment();
      } else {
        // parse expression statement and wrap in ExprStmt
        final expr = parseExpression();
        if (tokens.peek().tipo == TokenType.simbolo &&
            tokens.peek().lexema == ';') {
          tokens.next();
        }
        init = ExprStmt(expr, 0, 0);
      }
    } else {
      // empty init
    }

    // condition
    Expr? condition;
    if (!(tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ';')) {
      condition = parseExpression();
    }
    // expect ';'
    if (tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ';') {
      tokens.next();
    } else {
      final t = tokens.peek();
      errors.add(
        ParseError.expected(';', t, contexto: extractLineContext(src, t.linha)),
      );
      _synchronize();
      return null;
    }

    // update expression
    Expr? update;
    if (!(tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ')')) {
      update = parseExpression();
    }

    // expect ')'
    if (!(tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ')')) {
      final t = tokens.peek();
      errors.add(
        ParseError.expected(')', t, contexto: extractLineContext(src, t.linha)),
      );
      _synchronize();
      return null;
    }
    tokens.next();

    final body = parseCommand();
    if (body == null) {
      errors.add(
        ParseError(
          'Corpo do for ausente ou inválido na linha ${kw.linha}, coluna ${kw.coluna}',
          linha: kw.linha,
          coluna: kw.coluna,
          contexto: extractLineContext(src, kw.linha),
        ),
      );
      return null;
    }

    return ForStmt(init, condition, update, body, kw.linha, kw.coluna);
  }

  ReturnStmt? parseReturn() {
    final kw = tokens.next(); // consume 'return'
    Expr? value;
    if (!(tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ';')) {
      value = parseExpression();
    }
    // expect ';'
    final semi = tokens.peek();
    if (semi.tipo == TokenType.simbolo && semi.lexema == ';') {
      tokens.next();
    } else {
      errors.add(
        ParseError.expected(
          ';',
          semi,
          contexto: extractLineContext(src, semi.linha),
        ),
      );
      _synchronize();
      return null;
    }

    return ReturnStmt(value, kw.linha, kw.coluna);
  }

  FunctionDecl? parseFunctionDecl() {
    // optional modifiers
    final modifiers = <String>[];
    while (tokens.peek().tipo == TokenType.palavraReservada &&
        (tokens.peek().lexema == 'public' ||
            tokens.peek().lexema == 'static')) {
      modifiers.add(tokens.next().lexema);
    }

    // return type
    String returnType = 'void';
    if (_isTypeKeyword(tokens.peek())) {
      returnType = tokens.next().lexema;
    }

    // function name
    Token nameTok = tokens.peek();
    // Function name must be an identifier; reserved words are not allowed
    if (nameTok.tipo == TokenType.identificador) {
      tokens.next();
    } else {
      final t = tokens.peek();
      errors.add(
        ParseError.expected(
          'identificador',
          t,
          contexto: extractLineContext(src, t.linha),
        ),
      );
      _synchronize();
      return null;
    }

    // params
    try {
      tokens.expect(TokenType.simbolo, '(');
    } on StateError catch (_) {
      final t = tokens.peek();
      errors.add(
        ParseError.expected('(', t, contexto: extractLineContext(src, t.linha)),
      );
      _synchronize();
      return null;
    }

    final params = <Param>[];
    if (!(tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ')')) {
      // parse first param
      while (true) {
        if (!_isTypeKeyword(tokens.peek())) {
          final t = tokens.peek();
          errors.add(
            ParseError.expected(
              'tipo',
              t,
              contexto: extractLineContext(src, t.linha),
            ),
          );
          _synchronize();
          return null;
        }
        final ptype = tokens.next().lexema;
        Token pname;
        try {
          pname = tokens.expect(TokenType.identificador);
        } on StateError catch (_) {
          final t = tokens.peek();
          errors.add(
            ParseError.expected(
              'identificador',
              t,
              contexto: extractLineContext(src, t.linha),
            ),
          );
          _synchronize();
          return null;
        }
        params.add(Param(ptype, pname.lexema));
        if (tokens.peek().tipo == TokenType.simbolo &&
            tokens.peek().lexema == ',') {
          tokens.next();
          continue;
        }
        break;
      }
    }

    // expect ')'
    if (tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ')') {
      tokens.next();
    } else {
      final t = tokens.peek();
      errors.add(
        ParseError.expected(')', t, contexto: extractLineContext(src, t.linha)),
      );
      _synchronize();
      return null;
    }

    // body must be a block
    final body = parseBlock();
    if (body == null) return null;

    return FunctionDecl(
      modifiers,
      returnType,
      nameTok.lexema,
      params,
      body,
      nameTok.linha,
      nameTok.coluna,
    );
  }

  Assign? parseAssignment() {
    Token idTok;
    try {
      idTok = tokens.expect(TokenType.identificador);
    } on StateError catch (_) {
      final t = tokens.peek();
      errors.add(
        ParseError.expected(
          'identificador',
          t,
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
        ParseError.expected(
          '"="',
          t,
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
        ParseError.expected(
          ';',
          semi,
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
        ParseError.expected('(', t, contexto: extractLineContext(src, t.linha)),
      );
      _synchronize();
      return null;
    }

    final condition = parseExpression();

    if (!(tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ')')) {
      final t = tokens.peek();
      errors.add(
        ParseError.expected(')', t, contexto: extractLineContext(src, t.linha)),
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
        ParseError.expected('(', t, contexto: extractLineContext(src, t.linha)),
      );
      _synchronize();
      return null;
    }
    final condition = parseExpression();
    if (!(tokens.peek().tipo == TokenType.simbolo &&
        tokens.peek().lexema == ')')) {
      final t = tokens.peek();
      errors.add(
        ParseError.expected(')', t, contexto: extractLineContext(src, t.linha)),
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
        ParseError.expected(
          '"}"',
          t,
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
      errors.add(
        ParseError.expected(
          'identificador',
          t,
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
        if (nextTok.tipo == TokenType.eof) {
          errors.add(
            ParseError(
              'Esperado ";" antes do fim de arquivo após declaração de variável',
              linha: nextTok.linha,
              coluna: nextTok.coluna,
              contexto: extractLineContext(src, nextTok.linha),
            ),
          );
        } else {
          errors.add(
            ParseError.expected(
              ';',
              nextTok,
              contexto: extractLineContext(src, nextTok.linha),
            ),
          );
        }
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
      errors.add(
        ParseError.expected(
          ';',
          semi,
          contexto: extractLineContext(src, semi.linha),
        ),
      );
      _synchronize();
      return null;
    }

    return VarDecl(kw.lexema, id.lexema, init, kw.linha, kw.coluna);
  }

  /// Entry point with lowest precedence (including assignment)
  Expr parseExpression() => _parseAssignment();

  Expr _parseAssignment() {
    var left = _parseLogicalOr();
    final t = tokens.peek();
    if (t.tipo == TokenType.operador && t.lexema == '=') {
      final opTok = tokens.next();
      final right = _parseAssignment();
      return Binary(left, '=', right, opTok.linha, opTok.coluna);
    }
    return left;
  }

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
      // function call: IDENT '(' argList ')'
      if (tokens.peek().tipo == TokenType.simbolo &&
          tokens.peek().lexema == '(') {
        tokens.next(); // consume '('
        final args = <Expr>[];
        if (!(tokens.peek().tipo == TokenType.simbolo &&
            tokens.peek().lexema == ')')) {
          while (true) {
            args.add(parseExpression());
            if (tokens.peek().tipo == TokenType.simbolo &&
                tokens.peek().lexema == ',') {
              tokens.next();
              continue;
            }
            break;
          }
        }
        // expect ')'
        if (tokens.peek().tipo == TokenType.simbolo &&
            tokens.peek().lexema == ')') {
          tokens.next();
        } else {
          final close = tokens.peek();
          errors.add(
            ParseError.expected(
              ')',
              close,
              contexto: extractLineContext(src, close.linha),
            ),
          );
          _synchronize();
          return Identifier(tok.lexema, tok.linha, tok.coluna);
        }
        return Call(
          Identifier(tok.lexema, tok.linha, tok.coluna),
          args,
          tok.linha,
          tok.coluna,
        );
      }
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

      // Stop when we find a semicolon (end of statement) and consume it
      if (t.tipo == TokenType.simbolo && t.lexema == ';') {
        tokens.next();
        return;
      }

      // Also stop (and do not consume) at common statement/block boundaries
      // so that the outer parsing loop can resume from a sensible token.
      if (t.tipo == TokenType.simbolo &&
          (t.lexema == '}' || t.lexema == ')' || t.lexema == '{')) {
        return;
      }

      // If we encounter an 'else' keyword it's a good resync point (belongs
      // to the surrounding 'if'). For any other reserved word, also stop
      // so the parser can start a new declaration/statement.
      if (t.tipo == TokenType.palavraReservada) {
        // do not consume the reserved word; return control to caller
        return;
      }

      // otherwise advance and keep searching
      tokens.next();
    }
  }
}
