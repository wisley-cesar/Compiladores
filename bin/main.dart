import 'package:compilador/lexer.dart';
import 'package:compilador/token.dart';

/// Programa principal do compilador
/// Demonstra a análise léxica de código-fonte
void main() {
  // Código de exemplo para testar o lexer
  final codigo = '''
// Comentário de linha
int x = 10;
float y = 3.14;
String nome = "João";
bool ativo = true;


if (x>5){
}
if (x > 5 && y < 10.0) {
    x = x + 1;
    y *= 2.0;
}

/* Comentário de bloco
   com múltiplas linhas */
for (int i = 0; i < 10; i++) {
    print("Iteração: " + i);
}
  ''';

  print('=== COMPILADOR - ANÁLISE LÉXICA ===\n');
  print('Código de entrada:');
  print(codigo);
  print('\n' + '='*50 + '\n');

  // Criar e executar o lexer
  final lexer = Lexer(codigo);
  final tokens = lexer.analisar();

  // Imprimir relatório detalhado
  lexer.imprimirRelatorio();

  // Mostrar estatísticas
  print('\n=== ESTATÍSTICAS ===');
  final stats = lexer.getEstatisticas();
  print('Total de tokens: ${stats['totalTokens']}');
  print('Total de erros: ${stats['totalErros']}');
  print('Linhas processadas: ${stats['linhasProcessadas']}');
  
  print('\nContadores por tipo:');
  final contadores = stats['contadores'] as Map<dynamic, int>;
  contadores.forEach((tipo, count) {
    print('  ${tipo.toString()}: $count');
  });
}
