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
    final base =
        '$prefix: $mensagem${simbolo != null ? ' ("$simbolo")' : ''}$pos';
    final ctx = contexto != null ? '\nContexto: "$contexto"' : '';
    return '$base$ctx';
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
