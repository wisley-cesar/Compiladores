/// Representa um erro de parsing/sintaxe com posição opcional
class ParseError {
  final String mensagem;
  final int? linha;
  final int? coluna;
  final String? contexto;

  ParseError(this.mensagem, {this.linha, this.coluna, this.contexto});

  @override
  String toString() {
    if (linha != null && coluna != null) {
      return 'ParseError: $mensagem (linha: $linha, coluna: $coluna)' + (contexto != null ? '\nContexto: "$contexto"' : '');
    }
    return 'ParseError: $mensagem';
  }

  Map<String, dynamic> toJson() => {
        'mensagem': mensagem,
        'linha': linha,
        'coluna': coluna,
        'contexto': contexto,
      };
}
