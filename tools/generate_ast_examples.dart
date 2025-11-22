import 'dart:io';
import 'dart:convert';

import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/lexica/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/sintatica/ast/ast.dart';

void main(List<String> args) {
  final root = Directory('examples');
  if (!root.existsSync()) {
    print('Diretório examples/ não encontrado.');
    exit(1);
  }

  final outDir = Directory('examples/ast');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final files = root
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.src'))
      .toList();

  final encoder = JsonEncoder.withIndent('  ');

  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final src = f.readAsStringSync();
    print('Processando $name ...');
    final lexer = Lexer(src);
    final tokens = lexer.analisar();
    final stream = TokenStream(tokens);
    final parser = Parser(stream, src);
    final program = parser.parseProgram();
    final astJson = astToJson(program);
    final outPath = 'examples/ast/${name.replaceAll('.src', '.json')}';
    File(outPath).writeAsStringSync(encoder.convert(astJson));
    print('  -> $outPath gerado');
  }
}
