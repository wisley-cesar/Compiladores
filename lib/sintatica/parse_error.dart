import 'package:compilador/lexica/token.dart';

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
    // Normaliza o campo `esperado` removendo aspas e escapes
    String normalize(String s) {
      var out = s.trim();
      // Remove pares de aspas externos se existirem
      if ((out.startsWith('"') && out.endsWith('"')) ||
          (out.startsWith("'") && out.endsWith("'"))) {
        out = out.substring(1, out.length - 1);
      }
      // Remove sequências de escape comuns e aspas residuais
      out = out.replaceAll(r'\"', '"');
      out = out.replaceAll('"', '');
      out = out.replaceAll('\\', '');
      return out;
    }

    final esperadoNorm = normalize(esperado);

    return ParseError(
      'Esperado $esperadoNorm, encontrado ${recebido.lexema}',
      esperado: esperadoNorm,
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
