class SemanticError {
  final String mensagem;
  final String? simbolo;
  final int? linha;
  final int? coluna;
  final String? contexto;
  final bool isWarning;

  SemanticError(
    this.mensagem, {
    this.simbolo,
    this.linha,
    this.coluna,
    this.contexto,
    this.isWarning = false,
  });

  @override
  String toString() {
    final pos = (linha != null && coluna != null)
        ? ' (linha: $linha, coluna: $coluna)'
        : '';
    final prefix = isWarning ? 'SemanticWarning' : 'SemanticError';
    return '$prefix: $mensagem${simbolo != null ? ' ("$simbolo")' : ''}$pos' +
        (contexto != null ? '\nContexto: "$contexto"' : '');
  }

  /// Serializa o erro semântico para um mapa (útil para exportar/JSON)
  Map<String, dynamic> toJson() {
    return {
      'mensagem': mensagem,
      'simbolo': simbolo,
      'linha': linha,
      'coluna': coluna,
      'contexto': contexto,
      'isWarning': isWarning,
    };
  }
}
