import 'package:compilador/token_stream.dart';
import 'package:compilador/token.dart';
import 'package:compilador/ast/ast.dart';
import 'package:compilador/parse_error.dart';

class Parser {
  final TokenStream tokens;
  final List<ParseError> errors = [];

  Parser(this.tokens);

  Program parseProgram() {
    final stmts = <Stmt>[];
    while (!tokens.isAtEnd) {
      final s = parseStatement();
      if (s != null) stmts.add(s);
      // if s is null, just continue scanning to find next statement/token
      // do not break — this lets the parser skip unsupported tokens and
      // continue detecting further declarations (and syntax errors)
    }
    return Program(List.unmodifiable(stmts));
  }

  Stmt? parseStatement() {
    final t = tokens.peek();
    if (t.tipo == TokenType.palavraReservada && t.lexema == 'uids') {
      return parseVarDecl();
    }

    // For now, skip unknown tokens to avoid infinite loops
    if (t.tipo == TokenType.eof) return null;
    tokens.next();
    return null;
  }

  VarDecl? parseVarDecl() {
    final kw = tokens.expect(TokenType.palavraReservada);
    if (kw.lexema != 'uids') {
      throw StateError('Esperado palavra reservada uids, mas achado ${kw.lexema}');
    }
    Token id;
    try {
      id = tokens.expect(TokenType.identificador);
    } on StateError catch (e) {
      // registrar erro de parsing e sincronizar até ponto-e-vírgula
      final regex = RegExp(r'linha\s*([0-9]+),\s*coluna\s*([0-9]+)');
      final m = regex.firstMatch(e.message);
      int? linha;
      int? coluna;
      if (m != null) {
        linha = int.tryParse(m.group(1)!);
        coluna = int.tryParse(m.group(2)!);
      }
      errors.add(ParseError(e.message, linha: linha, coluna: coluna));
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
      final msg = 'Esperado ";" após declaração na linha ${semi.linha}, coluna ${semi.coluna}';
      errors.add(ParseError(msg, linha: semi.linha, coluna: semi.coluna));
      _synchronize();
      return null;
    }

    return VarDecl(kw.lexema, id.lexema, init, kw.linha, kw.coluna);
  }

  /// Entry point with lowest precedence
  Expr parseExpression() => _parseAdditive();

  Expr _parseAdditive() {
    var node = _parseMultiplicative();
    while (true) {
      final t = tokens.peek();
      if (t.tipo == TokenType.operador && (t.lexema == '+' || t.lexema == '-')) {
        final opTok = tokens.next();
        final op = opTok.lexema;
        final right = _parseMultiplicative();
        node = Binary(node, op, right, opTok.linha, opTok.coluna);
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
      if (t.tipo == TokenType.operador && (t.lexema == '*' || t.lexema == '/')) {
        final opTok = tokens.next();
        final op = opTok.lexema;
        final right = _parseUnary();
        node = Binary(node, op, right, opTok.linha, opTok.coluna);
      } else {
        break;
      }
    }
    return node;
  }

  Expr _parseUnary() {
    final t = tokens.peek();
    if (t.tipo == TokenType.operador && (t.lexema == '+' || t.lexema == '-')) {
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
        final msg = 'Parêntese ")" esperado na linha ${close.linha}, coluna ${close.coluna}';
        errors.add(ParseError(msg, linha: close.linha, coluna: close.coluna));
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
