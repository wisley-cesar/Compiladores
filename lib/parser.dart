import 'package:compilador/token_stream.dart';
import 'package:compilador/token.dart';
import 'ast/program.dart';
import 'ast/var_decl.dart';
import 'ast/literal.dart';
import 'ast/identifier.dart';
import 'ast/expr.dart';
import 'ast/binary.dart';
import 'ast/unary.dart';

class Parser {
  final TokenStream tokens;

  Parser(this.tokens);

  Program parseProgram() {
    final stmts = <dynamic>[];
    while (!tokens.isAtEnd) {
      final s = parseStatement();
      if (s != null) stmts.add(s);
      else break;
    }
    return Program(List.unmodifiable(stmts.cast()));
  }

  dynamic parseStatement() {
    final t = tokens.peek();
    if (t.tipo == TokenType.palavraReservada && t.lexema == 'uids') {
      return parseVarDecl();
    }

    // For now, skip unknown tokens to avoid infinite loops
    if (t.tipo == TokenType.eof) return null;
    tokens.next();
    return null;
  }

  VarDecl parseVarDecl() {
    final kw = tokens.expect(TokenType.palavraReservada);
    if (kw.lexema != 'uids') {
      throw StateError('Esperado palavra reservada uids, mas achado ${kw.lexema}');
    }

    final id = tokens.expect(TokenType.identificador);
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
      throw StateError('Esperado ";" após declaração na linha ${semi.linha}, coluna ${semi.coluna}');
    }

    return VarDecl(kw.lexema, id.lexema, init);
  }

  /// Entry point with lowest precedence
  Expr parseExpression() => _parseAdditive();

  Expr _parseAdditive() {
    var node = _parseMultiplicative();
    while (true) {
      final t = tokens.peek();
      if (t.tipo == TokenType.operador && (t.lexema == '+' || t.lexema == '-')) {
        final op = tokens.next().lexema;
        final right = _parseMultiplicative();
        node = Binary(node, op, right);
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
        final op = tokens.next().lexema;
        final right = _parseUnary();
        node = Binary(node, op, right);
      } else {
        break;
      }
    }
    return node;
  }

  Expr _parseUnary() {
    final t = tokens.peek();
    if (t.tipo == TokenType.operador && (t.lexema == '+' || t.lexema == '-')) {
      final op = tokens.next().lexema;
      final operand = _parseUnary();
      return Unary(op, operand);
    }
    return _parsePrimary();
  }

  Expr _parsePrimary() {
    final t = tokens.peek();
    if (t.tipo == TokenType.numero) {
      final tok = tokens.next();
      final lex = tok.lexema;
      final kind = _numberKind(lex);
      return Literal(lex, kind);
    }
    if (t.tipo == TokenType.string) {
      final tok = tokens.next();
      return Literal(tok.lexema, 'string');
    }
    if (t.tipo == TokenType.booleano) {
      final tok = tokens.next();
      return Literal(tok.lexema, 'bool');
    }
    if (t.tipo == TokenType.identificador) {
      final tok = tokens.next();
      return Identifier(tok.lexema);
    }
    if (t.tipo == TokenType.simbolo && t.lexema == '(') {
      tokens.next();
      final e = parseExpression();
      final close = tokens.peek();
      if (close.tipo == TokenType.simbolo && close.lexema == ')') {
        tokens.next();
        return e;
      } else {
        throw StateError('Parêntese ")" esperado na linha ${close.linha}, coluna ${close.coluna}');
      }
    }

    // fallback
    tokens.next();
    return Literal('null', 'dynamic');
  }

  String _numberKind(String lex) {
    final l = lex.toLowerCase();
    if (l.contains('.') || l.contains('e')) return 'double';
    return 'int';
  }
}
