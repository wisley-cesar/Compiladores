import 'package:compilador/lexica/token.dart';

/// Adaptador simples que converte a lista de tokens do Lexer em um stream
/// com suporte a lookahead e consumo.
class TokenStream {
  final List<Token> _tokens;
  int _pos = 0;

  TokenStream(this._tokens);

  Token peek([int offset = 0]) {
    final idx = _pos + offset;
    if (idx < 0) return _tokens.first;
    if (idx >= _tokens.length) return _tokens.last;
    return _tokens[idx];
  }

  Token next() {
    final t = peek(0);
    if (_pos < _tokens.length - 1) _pos++;
    return t;
  }

  bool match(TokenType tipo, [String? lexema]) {
    final t = peek();
    if (t.tipo != tipo) return false;
    if (lexema != null && t.lexema != lexema) return false;
    _pos++;
    return true;
  }

  /// Consome e retorna o token esperado; lança StateError se não corresponder.
  Token expect(TokenType tipo, [String? lexema]) {
    final t = peek();
    if (t.tipo != tipo || (lexema != null && t.lexema != lexema)) {
      throw StateError(
        'Token inesperado: esperado $tipo ${lexema ?? ''} mas achado ${t.tipo} "${t.lexema}" na linha ${t.linha}, coluna ${t.coluna}',
      );
    }
    _pos++;
    return t;
  }

  bool get isAtEnd => peek().tipo == TokenType.eof;
}
