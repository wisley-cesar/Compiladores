import 'package:compilador/token.dart';

/// Representa um erro de parsing/sintaxe com posição opcional.
///
/// As mensagens são padronizadas e podem conter, opcionalmente,
/// o token esperado e o token recebido para facilitar verificação em testes.
class ParseError {
  final String mensagem;
  final String? esperado;
  final String? recebido;
  final int? linha;
  final int? coluna;
  final String? contexto;

  ParseError(
    this.mensagem, {
    this.esperado,
    this.recebido,
    this.linha,
    this.coluna,
    this.contexto,
  });

  /// Construtor auxiliar para erros do tipo "Esperado X, encontrado Y".
  factory ParseError.expected(
    String esperado,
    Token recebido, {
    String? contexto,
  }) {
    return ParseError(
      'Esperado $esperado, encontrado ${recebido.lexema}',
      esperado: esperado,
      recebido: recebido.toReadableString(),
      linha: recebido.linha,
      coluna: recebido.coluna,
      contexto: contexto,
    );
  }

  /// Construtor auxiliar para erros de token inesperado.
  factory ParseError.unexpected(Token recebido, {String? contexto}) {
    return ParseError(
      'Token inesperado: ${recebido.lexema}',
      recebido: recebido.toReadableString(),
      linha: recebido.linha,
      coluna: recebido.coluna,
      contexto: contexto,
    );
  }

  @override
  String toString() {
    final buf = StringBuffer();
    buf.write('ParseError: $mensagem');
    if (esperado != null || recebido != null) {
      buf.write(' | ');
      if (esperado != null) buf.write('Esperado: $esperado');
      if (esperado != null && recebido != null) buf.write(' - ');
      if (recebido != null) buf.write('Recebido: $recebido');
    }
    if (linha != null && coluna != null) {
      buf.write(' (linha: $linha, coluna: $coluna)');
    }
    if (contexto != null) {
      buf.write('\nContexto: "$contexto"');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
    'mensagem': mensagem,
    'esperado': esperado,
    'recebido': recebido,
    'linha': linha,
    'coluna': coluna,
    'contexto': contexto,
  };
}
