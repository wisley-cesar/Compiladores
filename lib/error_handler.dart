
/// Classe responsável pelo tratamento de erros léxicos
class ErrorHandler {
  final List<String> erros = [];
  int linha = 1;
  int coluna = 1;

  /// Adiciona um erro léxico à lista de erros
  void adicionarErro(String mensagem, int linha, int coluna, String codigo, int pos) {
    erros.add('Erro léxico na linha $linha, coluna $coluna: $mensagem');
  }

  /// Verifica se há erros léxicos
  bool get temErros => erros.isNotEmpty;

  /// Retorna a lista de erros encontrados
  List<String> get listaErros => List.unmodifiable(erros);

  /// Limpa a lista de erros
  void limparErros() {
    erros.clear();
  }

  /// Retorna estatísticas de erros
  Map<String, dynamic> getEstatisticasErros() {
    return {
      'totalErros': erros.length,
      'temErros': temErros,
      'erros': List.from(erros),
    };
  }
}
