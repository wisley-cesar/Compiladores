/// Representa um erro de parsing/sintaxe com posição opcional
class ParseError {
  final String mensagem;
  final int? linha;
  final int? coluna;

  ParseError(this.mensagem, {this.linha, this.coluna});

  @override
  String toString() {
    if (linha != null && coluna != null) {
      return 'ParseError: $mensagem (linha: $linha, coluna: $coluna)';
    }
    return 'ParseError: $mensagem';
  }

  Map<String, dynamic> toJson() => {
        'mensagem': mensagem,
        'linha': linha,
        'coluna': coluna,
      };
}
