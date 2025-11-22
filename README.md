# Compilador - Analisador Léxico

Este projeto implementa um analisador léxico (lexer) para uma linguagem de programação simples, desenvolvido em Dart como parte de um projeto acadêmico de compiladores.

## 📋 Visão Geral

O analisador léxico é a primeira fase de um compilador, responsável por converter o código-fonte em uma sequência de tokens. Este projeto implementa um **Autômato Finito Determinístico (AFD)** para reconhecimento eficiente de tokens.

## 🎯 Funcionalidades

### ✅ Tokens Reconhecidos

- **Palavras Reservadas**: `if`, `else`, `while`, `for`, `int`, `float`, `string`, `bool`, `return`, `void`, etc.
- **Identificadores**: Nomes de variáveis, funções (ex: `variavel`, `_variavel`, `var123`)
- **Literais Numéricos**: Inteiros (`123`), decimais (`3.14`), notação científica (`1.23e5`)
- **Strings Literais**: Entre aspas duplas com escape sequences (`"Hello\\n"`)
- **Literais Booleanos**: `true`, `false`
- **Operadores**: `+`, `-`, `*`, `/`, `=`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `&&`, `||`, etc.
- **Símbolos Especiais**: `(`, `)`, `{`, `}`, `[`, `]`, `;`, `,`, `.`, `:`

### ✅ Tratamento de Comentários

- **Comentários de linha**: `// comentário`
- **Comentários de bloco**: `/* comentário */`

### ✅ Tratamento de Erros Léxicos

- Detecção de strings não fechadas
- Caracteres inválidos
- Números malformados
- Relatório detalhado de erros com posição (linha/coluna)

### ✅ Recursos Avançados

- **Rastreamento de posição**: Linha e coluna para cada token
- **Estatísticas**: Contadores por tipo de token
- **Relatórios detalhados**: Análise completa do código
- **Testes abrangentes**: Cobertura completa de funcionalidades

## 🏗️ Arquitetura

### Estrutura do Projeto

```
compilador/
├── lib/
│   ├── lexer.dart              # Analisador léxico principal
│   ├── token.dart              # Definições de tokens
│   ├── error_handler.dart      # Tratamento de erros léxicos
│   ├── token_recognizer.dart   # Reconhecedores de tokens específicos
│   ├── ambiguity_detector.dart # Detecção de ambiguidades sintáticas
│   └── statistics.dart         # Estatísticas e relatórios
├── bin/
│   └── main.dart               # Programa principal
├── test/
│   ├── compilador_test.dart
│   └── ambiguidade_test.dart
├── pubspec.yaml
└── README.md                   # Esta documentação
```

### Arquitetura Modular

O projeto foi refatorado para seguir o princípio de **Separação de Responsabilidades**, dividindo o lexer em módulos especializados:

#### 🔧 **Módulos Principais**

1. **`Lexer`** - Orquestrador principal
   - Coordena todos os módulos
   - Implementa o AFD (Autômato Finito Determinístico)
   - Gerencia o fluxo de análise

2. **`TokenRecognizer`** - Reconhecimento de tokens
   - Strings literais com escape sequences
   - Números (inteiros, decimais, notação científica)
   - Identificadores e palavras reservadas
   - Operadores e símbolos
   - Comentários (linha e bloco)

3. **`ErrorHandler`** - Tratamento de erros
   - Coleta e organiza erros léxicos
   - Fornece estatísticas de erros
   - Mantém lista de erros para relatórios

4. **`Statistics`** - Estatísticas e relatórios
   - Contadores de tokens por tipo
   - Percentuais de distribuição
   - Relatórios detalhados
   - Métricas de análise

### Classes Principais

#### `TokenType` (Enum)
Define todos os tipos de tokens reconhecidos:
- `palavraReservada`, `identificador`, `numero`, `string`, `booleano`
- `operador`, `simbolo`, `comentario`, `erro`, `eof`

#### `Token` (Classe)
Representa um token com:
- Tipo do token
- Lexema (texto reconhecido)
- Posição (linha e coluna)
- Métodos auxiliares para classificação

#### `Lexer` (Classe Principal)
Implementa o analisador léxico com:
- **AFD**: Autômato finito determinístico para reconhecimento
- **Tratamento de erros**: Detecção e relatório de erros léxicos
- **Estatísticas**: Contadores e métricas de análise
- **Relatórios**: Saída formatada dos resultados

## 🚀 Como Usar

### Execução Básica

```bash
# Executar o programa principal
dart run bin/main.dart

# Executar testes (formato expandido para saída detalhada)
dart test -r expanded

# Análise estática
dart analyze
```

### Exportar tokens para arquivo

O CLI agora permite exportar os tokens reconhecidos para um arquivo JSON usando a flag `--tokens-out <file>`.

Exemplo:

```bash
# Analisar um arquivo e mostrar tokens em JSON na saída
dart run bin/main.dart examples/demo.src --dump-tokens-json

# Analisar e gravar tokens no arquivo `out/tokens.json`
dart run bin/main.dart examples/demo.src --tokens-out out/tokens.json
```

Se `--tokens-out` for usada, o programa criará o arquivo (com diretórios necessários) e gravará o JSON formatado dos tokens.


### Exemplo de Uso

```dart
import 'package:compilador/lexica/lexer.dart';

void main() {
  final codigo = '''
    int x = 10;
    float y = 3.14;
    String nome = "João";
    bool ativo = true;
    
    if (x > 5 && y < 10.0) {
        x = x + 1;
    }
  ''';

  final lexer = Lexer(codigo);
  final tokens = lexer.analisar();
  
  // Imprimir relatório detalhado
  lexer.imprimirRelatorio();
  
  // Verificar erros
  if (lexer.temErros) {
    for (final erro in lexer.listaErros) {
      print('❌ $erro');
    }
  }
}
```

### Exemplo mínimo — usar o Lexer com uma string (linha de comando)

```dart
import 'package:compilador/lexica/lexer.dart';

void main() {
  final codigo = 'uids x = (1 + 2) * 3;';
  final lexer = Lexer(codigo);
  final tokens = lexer.analisar();

  for (final t in tokens) {
    print(t.toString());
  }
}
```

Saída exemplo (lista de tokens):

```
(palavraReservada, "uids", linha: 1, col: 1)
(identificador, "x", linha: 1, col: 6)
(operador, "=", linha: 1, col: 8)
(simbolo, "(", linha: 1, col: 10)
(numero, "1", linha: 1, col: 11)
(operador, "+", linha: 1, col: 13)
(numero, "2", linha: 1, col: 15)
(simbolo, ")", linha: 1, col: 16)
(operador, "*", linha: 1, col: 18)
(numero, "3", linha: 1, col: 20)
(simbolo, ";", linha: 1, col: 21)
(eof, "EOF", linha: 1, col: 22)
```

### Exemplo: ler de um arquivo e imprimir tokens + symbol table (JSON)

```dart
import 'dart:io';
import 'dart:convert';
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/symbol_table.dart';

void main() {
  final path = 'examples/demo.src';
  final src = File(path).readAsStringSync();

  final lexer = Lexer(src);
  final tokens = lexer.analisar();

  for (final t in tokens) print(t);

  // Supondo que o fluxo de parsing/semântica já tenha sido executado
  // e que você tenha uma SymbolTable (aqui mostramos um exemplo simples):
  final table = SymbolTable();
  table.add('x', type: 'int');
  table.add('s', type: 'string');

  final jsonSymbols = jsonEncode(table.allSymbols.map((s) => s.toJson()).toList());
  print('\nSymbol Table (JSON):');
  print(jsonSymbols);
}
```

Exemplo de saída (JSON):

```json
[{"id":1,"name":"x","type":"int","isMutable":true},
 {"id":2,"name":"s","type":"string","isMutable":true}]
```

## Erros léxicos estruturados

O lexer também expõe erros léxicos em formato estruturado através do getter `lexer.listaErrosEstruturados`, que retorna uma `List<LexError>` com os campos:

- `mensagem` (String): descrição curta do erro.
- `linha` (int): linha onde o erro ocorreu (1-based).
- `coluna` (int): coluna onde o erro ocorreu (1-based).
- `contexto` (String): trecho do código ao redor da posição do erro (com novas linhas substituídas por `\u21B5` para legibilidade).

Exemplo de uso:

```dart
final lexer = Lexer('int x = @ 42;');
final tokens = lexer.analisar();
if (lexer.temErros) {
  for (final err in lexer.listaErrosEstruturados) {
    print('Erro: ${err.mensagem} (linha: ${err.linha}, coluna: ${err.coluna})');
    print('Contexto: ' + err.contexto);
  }
}
```

Essa representação facilita relatórios, testes e integração com ferramentas que consumam erros estruturados (por exemplo, formatadores de IDE).


## 📊 Exemplo de Saída

```
=== RELATÓRIO DE ANÁLISE LÉXICA ===
Total de tokens: 25
Total de erros: 0
Linhas processadas: 6

TOKENS RECONHECIDOS:
  Palavra reservada: int
  Identificador: x
  Operador: =
  Número: 10
  Símbolo: ;
  Palavra reservada: float
  Identificador: y
  Operador: =
  Número: 3.14
  Símbolo: ;
  ...

=== ESTATÍSTICAS ===
Total de tokens: 25
Total de erros: 0
Linhas processadas: 6

Contadores por tipo:
  TokenType.palavraReservada: 4
  TokenType.identificador: 6
  TokenType.operador: 8
  TokenType.numero: 3
  TokenType.simbolo: 4
```

## 🧪 Testes

O projeto inclui testes abrangentes que cobrem:

- **Reconhecimento de tokens**: Todos os tipos de tokens
- **Comentários**: Linha e bloco
- **Tratamento de erros**: Strings não fechadas, caracteres inválidos
- **Posição dos tokens**: Rastreamento correto de linha/coluna
- **Estatísticas**: Validação de métricas

Execute os testes com:
```bash
dart test
```

## 🔧 Implementação Técnica

### Autômato Finito Determinístico (AFD)

O lexer implementa um AFD para reconhecimento eficiente de tokens:

1. **Estados**: Caracteres, dígitos, letras, símbolos
2. **Transições**: Baseadas no caractere atual
3. **Estados finais**: Tokens reconhecidos
4. **Tratamento de erros**: Estados de erro

### Algoritmo Principal

```dart
while (pos < codigo.length) {
  final char = codigo[pos];
  
  if (char == ' ' || char == '\t') {
    avancar(); // Ignorar espaços
  } else if (char == '\n') {
    linha++; coluna = 1; // Nova linha
  } else if (char == '/' && proximo == '/') {
    ignorarComentarioLinha();
  } else if (char == '"') {
    lerString();
  } else if (_isDigit(char)) {
    lerNumero();
  } else if (_isLetter(char)) {
    lerIdentificadorOuPalavraReservada();
  } else if (_isOperadorOuSimbolo(char)) {
    lerOperadorOuSimbolo();
  } else {
    adicionarErro('Caractere inválido');
  }
}
```

## 📈 Critérios de Avaliação

### ✅ Corretude (40%)
- ✅ Reconhece todos os tipos de tokens corretamente
- ✅ Trata comentários adequadamente
- ✅ Detecta e reporta erros léxicos
- ✅ Mantém posição correta dos tokens

### ✅ Abrangência (20%)
- ✅ Palavras reservadas completas
- ✅ Operadores unários e binários
- ✅ Números inteiros, decimais e científicos
- ✅ Strings com escape sequences
- ✅ Símbolos especiais

### ✅ Tratamento de Erros (15%)
- ✅ Strings não fechadas
- ✅ Caracteres inválidos
- ✅ Números malformados
- ✅ Relatório detalhado com posição

### ✅ Clareza do Código (10%)
- ✅ Código bem documentado
- ✅ Estrutura modular
- ✅ Nomes descritivos
- ✅ Separação de responsabilidades

### ✅ Documentação (15%)
- ✅ README completo
- ✅ Comentários no código
- ✅ Exemplos de uso
- ✅ Explicação da implementação

## 🎓 Aspectos Conceituais

### Descrição dos Tokens

O analisador reconhece as seguintes classes de tokens:

1. **Palavras Reservadas**: Elementos da linguagem com significado especial
2. **Identificadores**: Nomes definidos pelo programador
3. **Literais**: Valores constantes (números, strings, booleanos)
4. **Operadores**: Símbolos para operações
5. **Símbolos**: Delimitadores e pontuação

### Abordagem de Implementação

- **AFD**: Autômato finito determinístico para reconhecimento eficiente
- **Lookahead**: Análise de caracteres à frente para operadores multi-caractere
- **Estado**: Rastreamento de posição e contexto
- **Recuperação de erros**: Continuação da análise após erros

### Exemplos de Entrada e Saída

**Entrada:**
```c
int x = 10;
float y = 3.14;
String nome = "João";
bool ativo = true;

if (x > 5 && y < 10.0) {
    x = x + 1;
}
```

**Saída:**
```
(PALAVRARESERVADA, "int", linha: 1, col: 4)
(IDENTIFICADOR, "x", linha: 1, col: 6)
(OPERADOR, "=", linha: 1, col: 7)
(NUMERO, "10", linha: 1, col: 11)
(SIMBOLO, ";", linha: 1, col: 11)
...
```

### Discussão sobre Erros Léxicos

O analisador trata os seguintes tipos de erros:

1. **Strings não fechadas**: Detecta quando uma string não é fechada adequadamente
2. **Caracteres inválidos**: Identifica símbolos não reconhecidos
3. **Números malformados**: Detecta formatos numéricos inválidos
4. **Sequências de escape inválidas**: Valida escape sequences em strings

## 🚀 Próximos Passos

Para completar o compilador, os próximos passos seriam:

1. **Analisador Sintático (Parser)**: Análise da estrutura gramatical
2. **Analisador Semântico**: Verificação de tipos e contexto
3. **Gerador de Código**: Produção de código intermediário ou final
4. **Otimizações**: Melhorias de performance

## 📝 Licença

Este projeto foi desenvolvido como parte de um trabalho acadêmico de compiladores.

---

**Desenvolvido com ❤️ em Dart para fins educacionais**

## 🧭 Descrição do Autômato Léxico (AFD)

O lexer implementa uma máquina de estados (AFD-like) para reconhecer tokens. Abaixo está uma visão simplificada dos estados principais e transições.

Estados principais:

- start: estado inicial; decide o próximo estado com base no caractere atual
- inNumber: reconhecendo dígitos e ponto decimal; também lida com expoentes (e/E)
- inIdentifier: reconhecendo letras, dígitos e underscore para identificadores e palavras reservadas
- inString: dentro de uma string entre aspas; processa escapes e detecta fim de string
- inCommentLine: ignorando até o fim da linha
- inCommentBlock: ignorando até encontrar */ ou EOF (erro se EOF antes de fechar)
- operatorLookahead: tenta reconhecer operadores de 3/2/1 caracteres (prioriza maior)

Diagrama simplificado (ASCII):

```
            +-------+
            | start |
            +---+---+
                |
    digits -> inNumber <- '.'? <- digits
      |         |\
      |         | \__ 'e'/'E' -> exponent handling
      |         v
    letters -> inIdentifier
      |                 \
      v                  '--> reserved/identifier (emit token)
    '"' -> inString -> (escape sequences) -> '"' emit string
    '/' -> (next=='/') inCommentLine -> consume until '\n'
           (next=='*') inCommentBlock -> consume until '*/' or error
    operator chars -> operatorLookahead -> emit operator token
```

Notas:

- O estado operatorLookahead tenta reconhecer primeiro seqüências de 3 caracteres, depois 2 e por fim 1.
- Strings e comentários atualizam contadores de linha/coluna para manter posições corretas.
- Números validam formato (ponto decimal e expoente); expoente inválido gera erro léxico e consumo seguro para recuperação.

Esta seção pode ser expandida com um diagrama PlantUML ou um AFD formal para documentação acadêmica.