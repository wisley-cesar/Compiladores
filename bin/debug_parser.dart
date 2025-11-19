import 'package:compilador/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/parser.dart';
import 'package:compilador/semantic_analyzer.dart';

void main() {
  final src = 'uids a = 10;\nint b;\nfloat c = 1.5;\n';
  final lexer = Lexer(src);
  final tokens = lexer.analisar();
  print('Tokens:');
  for (var t in tokens) print(t);
  final stream = TokenStream(tokens);
  final parser = Parser(stream);
  final program = parser.parseProgram();
  print('Programa statements: ${program.statements.length}');
  final analyzer = SemanticAnalyzer();
  final table = analyzer.analyze(program);
  print('Symbols count: ${table.allSymbols.length}');
  for (var s in table.allSymbols) print(s.toJson());
  print('Parser errors: ${parser.errors.length}');
  print('Analyzer errors: ${analyzer.errors.length}');
}
