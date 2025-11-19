/// Utilitários para extrair contexto (linha de código) a partir do texto-fonte
String extractLineContext(String src, int? linha) {
  if (linha == null) return '';
  final lines = src.split('\n');
  final idx = linha - 1;
  if (idx < 0 || idx >= lines.length) return '';
  return lines[idx];
}
