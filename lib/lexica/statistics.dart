import 'token.dart';
import 'lex_error.dart';

/// Classe responsável pelas estatísticas e relatórios do lexer
class Statistics {
  final List<Token> tokens;
  final List<LexError> erros;
  final int linhasProcessadas;

  Statistics(this.tokens, this.erros, this.linhasProcessadas);

  /// Retorna estatísticas do lexer
  Map<String, dynamic> getEstatisticas() {
    final contadores = <TokenType, int>{};
    for (final token in tokens) {
      contadores[token.tipo] = (contadores[token.tipo] ?? 0) + 1;
    }

    return {
      'totalTokens': tokens.length,
      'totalErros': erros.length,
      'contadores': contadores,
      'linhasProcessadas': linhasProcessadas,
    };
  }

  /// Imprime relatório detalhado da análise léxica
  void imprimirRelatorio() {
    print('=== RELATÓRIO DE ANÁLISE LÉXICA ===');
    print('Total de tokens: ${tokens.length}');
    print('Total de erros: ${erros.length}');
    print('Linhas processadas: $linhasProcessadas');
    print('');

    if (erros.isNotEmpty) {
      print('ERROS ENCONTRADOS:');
      for (final erro in erros) {
        print('  - ${erro.toString()}');
      }
      print('');
    }

    print('TOKENS RECONHECIDOS:');
    for (final token in tokens) {
      print('  ${token.toReadableString()}');
    }
  }

  /// Retorna estatísticas de erros
  Map<String, dynamic> getEstatisticasErros() {
    return {
      'totalErros': erros.length,
      'temErros': erros.isNotEmpty,
      'erros': erros.map((e) => e.toString()).toList(),
    };
  }

  /// Retorna estatísticas de tokens por tipo
  Map<TokenType, int> getContadoresTokens() {
    final contadores = <TokenType, int>{};
    for (final token in tokens) {
      contadores[token.tipo] = (contadores[token.tipo] ?? 0) + 1;
    }
    return contadores;
  }

  /// Retorna percentual de tokens por tipo
  Map<TokenType, double> getPercentuaisTokens() {
    final contadores = getContadoresTokens();
    final total = tokens.length;
    final percentuais = <TokenType, double>{};

    for (final entry in contadores.entries) {
      percentuais[entry.key] = (entry.value / total) * 100;
    }

    return percentuais;
  }
}
