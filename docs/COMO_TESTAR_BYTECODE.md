# Como Testar a Implementação de Bytecode

Este guia mostra diferentes formas de testar a geração de bytecode no seu computador.

## Opção 1: Script de Teste Automático (Mais Rápido)

Execute o script de teste que já criamos:

```bash
cd Compiladores
dart pub run tools/test_increment.dart
```

Este comando executa automaticamente todos os testes dos operadores incrementais e mostra:
- O código fonte
- O bytecode gerado (formato legível)
- O JSON completo
- Resultados de sucesso ou erro

## Opção 2: Usar o Main.dart com Arquivo de Exemplo

### Passo 1: Criar um arquivo de teste

Crie um arquivo `.src` com código exemplo. Por exemplo:

**arquivo: `examples/meu_teste.src`**
```dart
int i = 5;
i++;
int j = i * 2;
```

### Passo 2: Executar o compilador

```bash
cd Compiladores
dart run bin/main.dart examples/meu_teste.src --dump-ast-json
```

Isso mostra a AST, mas ainda não mostra o bytecode. Para ver o bytecode, precisamos modificar o main.dart ou criar um script específico.

## Opção 3: Script Simples para Testar Bytecode

Crie um arquivo de teste simples e execute diretamente:

**arquivo: `test_bytecode.dart`** (na raiz do projeto)
```dart
import 'dart:io';
import 'dart:convert';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/vm/bytecode_generator.dart';

void main() {
  print('=== TESTE DE GERAÇÃO DE BYTECODE ===\n');
  
  // Seu código aqui
  final src = '''
int x = 10;
int y = 20;
int soma = x + y;
x++;
++y;
''';
  
  print('Código fonte:');
  print(src);
  print('\n' + '='*50 + '\n');
  
  // Análise léxica
  final lexer = Lexer(src);
  final tokens = lexer.analisar();
  
  if (lexer.listaErrosEstruturados.isNotEmpty) {
    print('ERROS LÉXICOS:');
    for (final e in lexer.listaErrosEstruturados) {
      print('  - $e');
    }
    return;
  }
  
  // Análise sintática
  final stream = TokenStream(tokens);
  final parser = Parser(stream, src);
  final program = parser.parseProgram();
  
  if (parser.errors.isNotEmpty) {
    print('ERROS DE PARSE:');
    for (final e in parser.errors) {
      print('  - $e');
    }
    return;
  }
  
  // Análise semântica
  final analyzer = SemanticAnalyzer(null, src);
  final symbolTable = analyzer.analyze(program);
  
  if (analyzer.errors.where((e) => !e.isWarning).isNotEmpty) {
    print('ERROS SEMÂNTICOS:');
    for (final e in analyzer.errors.where((e) => !e.isWarning)) {
      print('  - $e');
    }
  }
  
  // Geração de bytecode
  final generator = BytecodeGenerator(symbolTable);
  final bytecode = generator.generate(program);
  
  if (generator.errors.isNotEmpty) {
    print('ERROS DE GERAÇÃO:');
    for (final e in generator.errors) {
      print('  - $e');
    }
  }
  
  print('=== BYTECODE GERADO ===\n');
  print(bytecode.toString());
  
  print('\n=== JSON ===\n');
  print(JsonEncoder.withIndent('  ').convert(bytecode.toJson()));
}
```

Execute:
```bash
cd Compiladores
dart run test_bytecode.dart
```

## Opção 4: Testes Unitários

Execute os testes unitários criados:

```bash
cd Compiladores
dart test test/bytecode_increment_test.dart
```

## Opção 5: Integrar Bytecode no Main.dart (Recomendado)

Para sempre ver o bytecode ao compilar, podemos adicionar uma flag ao main.dart.

### Modificar bin/main.dart

Adicione após a análise semântica:

```dart
// ... código existente ...

final analyzer = SemanticAnalyzer(null, src);
final symbolTable = analyzer.analyze(program);

// ... código existente ...

// Adicionar geração de bytecode se solicitado
final dumpBytecode = args.contains('--dump-bytecode');
if (dumpBytecode) {
  final generator = BytecodeGenerator(symbolTable);
  final bytecode = generator.generate(program);
  
  print('\n=== BYTECODE ===');
  print(bytecode.toString());
  
  if (args.contains('--dump-bytecode-json')) {
    print('\n=== BYTECODE (JSON) ===');
    print(JsonEncoder.withIndent('  ').convert(bytecode.toJson()));
  }
  
  if (generator.errors.isNotEmpty) {
    print('\n=== BYTECODE ERRORS ===');
    for (final e in generator.errors) {
      print(e);
    }
  }
}
```

Depois execute:
```bash
dart run bin/main.dart examples/meu_teste.src --dump-bytecode
```

## Exemplos Prontos para Testar

### Exemplo 1: Operações Aritméticas

```dart
int a = 10;
int b = 5;
int soma = a + b;
int produto = a * b;
int divisao = a / b;
```

### Exemplo 2: Operadores Incrementais

```dart
int i = 0;
i++;      // i agora é 1
++i;      // i agora é 2
int j = i++;
int k = ++i;
```

### Exemplo 3: Condicionais

```dart
int x = 10;
if (x > 5) {
  x = x + 1;
} else {
  x = x - 1;
}
```

### Exemplo 4: Loops

```dart
int soma = 0;
for (int i = 0; i < 10; i++) {
  soma = soma + i;
}
```

### Exemplo 5: Operadores Lógicos

```dart
bool a = true;
bool b = false;
bool resultado = a && b;
bool resultado2 = a || b;
```

## Comandos Rápidos

```bash
# Testar operadores incrementais
dart pub run tools/test_increment.dart

# Testar com arquivo personalizado (se main.dart for modificado)
dart run bin/main.dart examples/meu_teste.src --dump-bytecode

# Executar testes unitários
dart test test/bytecode_increment_test.dart

# Executar todos os testes
dart test
```

## Interpretando o Bytecode

Cada linha do bytecode representa uma instrução:

- `pushInt(5)` - Empilha o inteiro 5
- `loadVar("x")` - Carrega variável x para a pilha
- `storeVar("x")` - Armazena valor do topo da pilha em x
- `add`, `sub`, `mul`, `div` - Operações aritméticas
- `jumpIfFalse(label)` - Salta se falso
- `enterScope`, `exitScope` - Gerenciamento de escopo
- `halt` - Termina execução

## Dicas

1. **Para testar rapidamente**: Use `tools/test_increment.dart`
2. **Para testar código customizado**: Crie um arquivo `.src` e use o script simples
3. **Para debugar**: Adicione `--dump-bytecode-json` para ver o formato JSON completo
4. **Para validar**: Execute os testes unitários que verificam automaticamente

## Solução de Problemas

**Erro: "The language version 3.10 specified..."**
- A versão do SDK foi ajustada no `pubspec.yaml` para `^3.9.0`
- Execute `dart pub get` novamente

**Erro: "Package not found"**
- Execute `dart pub get` na pasta `Compiladores`

**Bytecode não aparece**
- Verifique se passou a flag `--dump-bytecode`
- Verifique se há erros de parse/semântica (eles impedem a geração)

