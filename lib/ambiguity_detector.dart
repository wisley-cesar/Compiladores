
/// Classe responsável pela detecção de ambiguidades sintáticas
class AmbiguityDetector {
  final String codigo;
  int pos = 0;
  int linha = 1;
  int coluna = 1;

  AmbiguityDetector(this.codigo);

  /// Detecta ambiguidades sintáticas básicas no nível léxico
  void detectarAmbiguidades(String char, Function(String) adicionarErro) {
    // Detectar parênteses extras consecutivos
    if (char == ')' && pos + 1 < codigo.length && codigo[pos + 1] == ')') {
      adicionarErro('Parêntese extra detectado - possível ambiguidade sintática');
    }
    
    // Detectar chaves extras consecutivas
    if (char == '}' && pos + 1 < codigo.length && codigo[pos + 1] == '}') {
      adicionarErro('Chave extra detectada - possível ambiguidade sintática');
    }
    
    // Detectar colchetes extras consecutivos
    if (char == ']' && pos + 1 < codigo.length && codigo[pos + 1] == ']') {
      adicionarErro('Colchete extra detectado - possível ambiguidade sintática');
    }
    
    // Detectar ponto e vírgula duplo
    if (char == ';' && pos + 1 < codigo.length && codigo[pos + 1] == ';') {
      adicionarErro('Ponto e vírgula duplo detectado - possível ambiguidade sintática');
    }
    
    // Detectar padrões problemáticos específicos
    _detectarPadroesProblematicos(char, adicionarErro);
  }

  /// Detecta padrões problemáticos específicos que indicam ambiguidade
  void _detectarPadroesProblematicos(String char, Function(String) adicionarErro) {
    // Padrão: )){ - parêntese extra seguido de chave
    if (char == ')' && pos + 2 < codigo.length) {
      if (codigo[pos + 1] == ')' && codigo[pos + 2] == '{') {
        adicionarErro('Parêntese extra antes de chave - possível ambiguidade sintática');
      }
    }
    
    // Padrão: }} - chaves extras
    if (char == '}' && pos + 1 < codigo.length && codigo[pos + 1] == '}') {
      adicionarErro('Chave extra detectada - possível ambiguidade sintática');
    }
    
    // Detectar padrões específicos problemáticos
    _detectarPadroesEspecificos(char, adicionarErro);
  }

  /// Detecta padrões específicos problemáticos
  void _detectarPadroesEspecificos(String char, Function(String) adicionarErro) {
    // Padrão: x>5) - operador sem espaços (opcional, pode ser removido se não for necessário)
    if (char == '>' && pos > 0 && pos + 1 < codigo.length) {
      final anterior = codigo[pos - 1];
      final proximo = codigo[pos + 1];
      
      // Se não há espaços ao redor do operador e há parêntese depois
      if (anterior != ' ' && proximo != ' ' && proximo == ')') {
        adicionarErro('Falta espaço adequado ao redor do operador - possível ambiguidade');
      }
    }
    
    // Detectar operadores ambíguos como +++ ou ---
    if ((char == '+' || char == '-') && pos + 2 < codigo.length) {
      final proximo1 = codigo[pos + 1];
      final proximo2 = codigo[pos + 2];
      
      // Padrão: +++ ou --- (três operadores consecutivos)
      if (proximo1 == char && proximo2 == char) {
        adicionarErro('Operador ambíguo detectado: $char$char$char - possível ambiguidade sintática');
      }
    }
  }

  /// Atualiza a posição atual do detector
  void atualizarPosicao(int novaPos, int novaLinha, int novaColuna) {
    pos = novaPos;
    linha = novaLinha;
    coluna = novaColuna;
  }
}
