class SemanticError {
  final String mensagem;
  final String? simbolo;
  final int? linha;
  final int? coluna;

  SemanticError(this.mensagem, {this.simbolo, this.linha, this.coluna});

  @override
  String toString() {
    final pos = (linha != null && coluna != null) ? ' (linha: $linha, coluna: $coluna)' : '';
    return 'SemanticError: $mensagem${simbolo != null ? ' ("$simbolo")' : ''}$pos';
  }

  /// Serializa o erro semântico para um mapa (útil para exportar/JSON)
  Map<String, dynamic> toJson() {
    return {
      'mensagem': mensagem,
      'simbolo': simbolo,
      'linha': linha,
      'coluna': coluna,
    };
  }

}
