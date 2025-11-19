/// Representação estruturada de um erro léxico
class LexError {
  final String mensagem;
  final int linha;
  final int coluna;
  final String contexto; // trecho do código ao redor

  LexError(this.mensagem, this.linha, this.coluna, this.contexto);

  @override
  String toString() =>
      'Erro léxico na linha $linha, coluna $coluna: $mensagem\nContexto: "$contexto"';

  /// Serializa o erro para um mapa (útil para exportar/JSON)
  Map<String, dynamic> toJson() {
    return {
      'mensagem': mensagem,
      'linha': linha,
      'coluna': coluna,
      'contexto': contexto,
    };
  }
}
