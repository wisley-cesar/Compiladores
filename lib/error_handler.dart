// Classe responsável pelo tratamento de erros léxicos
import 'lex_error.dart';

class ErrorHandler {
  final List<LexError> _erros = [];

  /// Adiciona um erro léxico à lista de erros como objeto `LexError`.
  /// Mantém compatibilidade retornando mensagens formatadas via `listaErros`.
  void adicionarErro(
    String mensagem,
    int linha,
    int coluna,
    String codigo,
    int pos,
  ) {
    final snippet = _extrairContexto(codigo, pos, 20);
    final lex = LexError(mensagem, linha, coluna, snippet);
    // Evitar duplicatas exatas de erro (mesma mensagem, posição e contexto)
    final exists = _erros.any(
      (e) =>
          e.mensagem == lex.mensagem &&
          e.linha == lex.linha &&
          e.coluna == lex.coluna &&
          e.contexto == lex.contexto,
    );
    if (!exists) {
      _erros.add(lex);
    }
  }

  /// Extrai um trecho do código ao redor da posição `pos` com `radius` caracteres
  /// antes e depois. Substitui quebras de linha por \u21B5 para manter a mensagem
  /// em uma linha legível.
  String _extrairContexto(String codigo, int pos, int radius) {
    if (pos < 0) pos = 0;
    final start = pos - radius >= 0 ? pos - radius : 0;
    final end = (pos + radius) < codigo.length ? pos + radius : codigo.length;
    var trecho = codigo.substring(start, end);
    trecho = trecho.replaceAll('\n', '\\u21B5');
    return trecho;
  }

  /// Verifica se há erros léxicos
  bool get temErros => _erros.isNotEmpty;

  /// Retorna a lista de erros formatada (compatível com API existente)
  List<String> get listaErros =>
      List.unmodifiable(_erros.map((e) => e.toString()).toList());

  /// Retorna a lista de erros estruturada
  List<LexError> get listaLexErrors => List.unmodifiable(_erros);

  /// Limpa a lista de erros
  void limparErros() {
    _erros.clear();
  }

  /// Retorna estatísticas de erros
  Map<String, dynamic> getEstatisticasErros() {
    return {
      'totalErros': _erros.length,
      'temErros': temErros,
      'erros': _erros.map((e) => e.toString()).toList(),
    };
  }
}
