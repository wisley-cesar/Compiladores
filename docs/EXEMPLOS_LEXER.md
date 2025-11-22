# Exemplos de Entrada e Saída - Analisador Léxico

Este documento apresenta múltiplos exemplos práticos de como o analisador léxico processa diferentes tipos de código-fonte, mostrando a entrada (código) e a saída (lista de tokens gerados).

## 📋 Índice

1. [Exemplos Básicos](#exemplos-básicos)
2. [Palavras Reservadas](#palavras-reservadas)
3. [Identificadores](#identificadores)
4. [Literais Numéricos](#literais-numéricos)
5. [Strings Literais](#strings-literais)
6. [Operadores](#operadores)
7. [Símbolos Especiais](#símbolos-especiais)
8. [Comentários](#comentários)
9. [Tratamento de Erros](#tratamento-de-erros)
10. [Casos Complexos](#casos-complexos)

---

## Exemplos Básicos

### Exemplo 1: Declaração de Variável Simples

**Entrada:**
```dart
int x = 10;
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "int", linha: 1, col: 4)
(IDENTIFICADOR, "x", linha: 1, col: 6)
(OPERADOR, "=", linha: 1, col: 8)
(NUMERO, "10", linha: 1, col: 11)
(SIMBOLO, ";", linha: 1, col: 12)
(EOF, "EOF", linha: 1, col: 13)
```

### Exemplo 2: Múltiplas Declarações

**Entrada:**
```dart
int a = 5;
float b = 3.14;
string nome = "João";
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "int", linha: 1, col: 4)
(IDENTIFICADOR, "a", linha: 1, col: 6)
(OPERADOR, "=", linha: 1, col: 8)
(NUMERO, "5", linha: 1, col: 10)
(SIMBOLO, ";", linha: 1, col: 11)
(PALAVRARESERVADA, "float", linha: 2, col: 6)
(IDENTIFICADOR, "b", linha: 2, col: 8)
(OPERADOR, "=", linha: 2, col: 10)
(NUMERO, "3.14", linha: 2, col: 15)
(SIMBOLO, ";", linha: 2, col: 16)
(PALAVRARESERVADA, "string", linha: 3, col: 7)
(IDENTIFICADOR, "nome", linha: 3, col: 12)
(OPERADOR, "=", linha: 3, col: 14)
(STRING, "João", linha: 3, col: 20)
(SIMBOLO, ";", linha: 3, col: 21)
(EOF, "EOF", linha: 4, col: 1)
```

---

## Palavras Reservadas

### Exemplo 3: Palavras Reservadas Comuns

**Entrada:**
```dart
if else while for int float bool string return void
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "if", linha: 1, col: 3)
(PALAVRARESERVADA, "else", linha: 1, col: 8)
(PALAVRARESERVADA, "while", linha: 1, col: 14)
(PALAVRARESERVADA, "for", linha: 1, col: 18)
(PALAVRARESERVADA, "int", linha: 1, col: 22)
(PALAVRARESERVADA, "float", linha: 1, col: 27)
(PALAVRARESERVADA, "bool", linha: 1, col: 32)
(PALAVRARESERVADA, "string", linha: 1, col: 38)
(PALAVRARESERVADA, "return", linha: 1, col: 45)
(PALAVRARESERVADA, "void", linha: 1, col: 50)
(EOF, "EOF", linha: 1, col: 51)
```

**Observação:** O lexer diferencia palavras reservadas de identificadores. Se `if` fosse escrito como `If` (maiúscula), seria reconhecido como identificador, não como palavra reservada.

---

## Identificadores

### Exemplo 4: Identificadores Válidos

**Entrada:**
```dart
variavel _variavel var123 minha_variavel x1 y2z3
```

**Saída (tokens):**
```
(IDENTIFICADOR, "variavel", linha: 1, col: 9)
(IDENTIFICADOR, "_variavel", linha: 1, col: 19)
(IDENTIFICADOR, "var123", linha: 1, col: 26)
(IDENTIFICADOR, "minha_variavel", linha: 1, col: 41)
(IDENTIFICADOR, "x1", linha: 1, col: 44)
(IDENTIFICADOR, "y2z3", linha: 1, col: 49)
(EOF, "EOF", linha: 1, col: 50)
```

**Regra:** Identificadores seguem o padrão `[a-zA-Z_][a-zA-Z0-9_]*` (começam com letra ou underscore, seguidos de letras, dígitos ou underscores).

### Exemplo 5: Diferença entre Palavra Reservada e Identificador

**Entrada:**
```dart
if if_variavel If
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "if", linha: 1, col: 3)
(IDENTIFICADOR, "if_variavel", linha: 1, col: 15)
(IDENTIFICADOR, "If", linha: 1, col: 18)
(EOF, "EOF", linha: 1, col: 19)
```

**Observação:** `if` é palavra reservada, mas `if_variavel` e `If` são identificadores (case-sensitive).

---

## Literais Numéricos

### Exemplo 6: Números Inteiros

**Entrada:**
```dart
0 123 999 42
```

**Saída (tokens):**
```
(NUMERO, "0", linha: 1, col: 2)
(NUMERO, "123", linha: 1, col: 6)
(NUMERO, "999", linha: 1, col: 11)
(NUMERO, "42", linha: 1, col: 15)
(EOF, "EOF", linha: 1, col: 16)
```

### Exemplo 7: Números Decimais

**Entrada:**
```dart
3.14 0.5 .5 123. 0.0
```

**Saída (tokens):**
```
(NUMERO, "3.14", linha: 1, col: 5)
(NUMERO, "0.5", linha: 1, col: 9)
(NUMERO, ".5", linha: 1, col: 12)
(NUMERO, "123.", linha: 1, col: 17)
(NUMERO, "0.0", linha: 1, col: 22)
(EOF, "EOF", linha: 1, col: 24)
```

**Observação:** O lexer aceita números que começam com ponto (`.5`) ou terminam com ponto (`123.`).

### Exemplo 8: Notação Científica

**Entrada:**
```dart
1.23e5 1.23E5 1.23e+5 1.23e-5
```

**Saída (tokens):**
```
(NUMERO, "1.23e5", linha: 1, col: 7)
(NUMERO, "1.23E5", linha: 1, col: 14)
(NUMERO, "1.23e+5", linha: 1, col: 22)
(NUMERO, "1.23e-5", linha: 1, col: 30)
(EOF, "EOF", linha: 1, col: 32)
```

**Observação:** Suporta `e` ou `E` para expoente, com sinal opcional (`+` ou `-`).

---

## Strings Literais

### Exemplo 9: Strings Simples

**Entrada:**
```dart
"Hello" "World" "123"
```

**Saída (tokens):**
```
(STRING, "Hello", linha: 1, col: 8)
(STRING, "World", linha: 1, col: 16)
(STRING, "123", linha: 1, col: 24)
(EOF, "EOF", linha: 1, col: 25)
```

### Exemplo 10: Strings com Escape Sequences

**Entrada:**
```dart
"Hello\nWorld" "Tab\tHere" "Quote\"Test" "Backslash\\Test"
```

**Saída (tokens):**
```
(STRING, "Hello\nWorld", linha: 1, col: 14)
(STRING, "Tab\tHere", linha: 1, col: 25)
(STRING, "Quote\"Test", linha: 1, col: 38)
(STRING, "Backslash\\Test", linha: 1, col: 54)
(EOF, "EOF", linha: 1, col: 55)
```

**Escape sequences suportadas:**
- `\n` : nova linha
- `\t` : tabulação
- `\"` : aspas duplas
- `\\` : barra invertida
- `\r` : retorno de carro
- `\0` : caractere nulo

### Exemplo 11: String Vazia

**Entrada:**
```dart
""
```

**Saída (tokens):**
```
(STRING, "", linha: 1, col: 3)
(EOF, "EOF", linha: 1, col: 3)
```

---

## Operadores

### Exemplo 12: Operadores Aritméticos

**Entrada:**
```dart
+ - * / %
```

**Saída (tokens):**
```
(OPERADOR, "+", linha: 1, col: 2)
(OPERADOR, "-", linha: 1, col: 4)
(OPERADOR, "*", linha: 1, col: 6)
(OPERADOR, "/", linha: 1, col: 8)
(OPERADOR, "%", linha: 1, col: 10)
(EOF, "EOF", linha: 1, col: 10)
```

### Exemplo 13: Operadores de Comparação

**Entrada:**
```dart
== != < > <= >=
```

**Saída (tokens):**
```
(OPERADOR, "==", linha: 1, col: 3)
(OPERADOR, "!=", linha: 1, col: 6)
(OPERADOR, "<", linha: 1, col: 8)
(OPERADOR, ">", linha: 1, col: 10)
(OPERADOR, "<=", linha: 1, col: 13)
(OPERADOR, ">=", linha: 1, col: 16)
(EOF, "EOF", linha: 1, col: 16)
```

### Exemplo 14: Operadores Lógicos

**Entrada:**
```dart
&& || !
```

**Saída (tokens):**
```
(OPERADOR, "&&", linha: 1, col: 3)
(OPERADOR, "||", linha: 1, col: 6)
(OPERADOR, "!", linha: 1, col: 8)
(EOF, "EOF", linha: 1, col: 8)
```

### Exemplo 15: Greedy Matching (Priorização de Tokens Longos)

**Entrada:**
```dart
>>> >> > === == =
```

**Saída (tokens):**
```
(OPERADOR, ">>>", linha: 1, col: 4)
(OPERADOR, ">>", linha: 1, col: 7)
(OPERADOR, ">", linha: 1, col: 9)
(OPERADOR, "===", linha: 1, col: 13)
(OPERADOR, "==", linha: 1, col: 16)
(OPERADOR, "=", linha: 1, col: 18)
(EOF, "EOF", linha: 1, col: 18)
```

**Observação:** O lexer usa **greedy matching**, sempre reconhecendo o token mais longo possível. Por isso `>>>` é reconhecido antes de `>>` ou `>`.

---

## Símbolos Especiais

### Exemplo 16: Símbolos de Pontuação

**Entrada:**
```dart
( ) { } [ ] ; , . :
```

**Saída (tokens):**
```
(SIMBOLO, "(", linha: 1, col: 2)
(SIMBOLO, ")", linha: 1, col: 4)
(SIMBOLO, "{", linha: 1, col: 6)
(SIMBOLO, "}", linha: 1, col: 8)
(SIMBOLO, "[", linha: 1, col: 10)
(SIMBOLO, "]", linha: 1, col: 12)
(SIMBOLO, ";", linha: 1, col: 14)
(SIMBOLO, ",", linha: 1, col: 16)
(SIMBOLO, ".", linha: 1, col: 18)
(SIMBOLO, ":", linha: 1, col: 20)
(EOF, "EOF", linha: 1, col: 20)
```

---

## Comentários

### Exemplo 17: Comentário de Linha

**Entrada:**
```dart
int x = 10; // Este é um comentário
int y = 20;
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "int", linha: 1, col: 4)
(IDENTIFICADOR, "x", linha: 1, col: 6)
(OPERADOR, "=", linha: 1, col: 8)
(NUMERO, "10", linha: 1, col: 11)
(SIMBOLO, ";", linha: 1, col: 12)
(PALAVRARESERVADA, "int", linha: 2, col: 4)
(IDENTIFICADOR, "y", linha: 2, col: 6)
(OPERADOR, "=", linha: 2, col: 8)
(NUMERO, "20", linha: 2, col: 11)
(SIMBOLO, ";", linha: 2, col: 12)
(EOF, "EOF", linha: 3, col: 1)
```

**Observação:** O comentário `// Este é um comentário` é completamente ignorado e não gera tokens.

### Exemplo 18: Comentário de Bloco

**Entrada:**
```dart
int x = 10; /* Este é um comentário de bloco */
int y = 20;
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "int", linha: 1, col: 4)
(IDENTIFICADOR, "x", linha: 1, col: 6)
(OPERADOR, "=", linha: 1, col: 8)
(NUMERO, "10", linha: 1, col: 11)
(SIMBOLO, ";", linha: 1, col: 12)
(PALAVRARESERVADA, "int", linha: 2, col: 4)
(IDENTIFICADOR, "y", linha: 2, col: 6)
(OPERADOR, "=", linha: 2, col: 8)
(NUMERO, "20", linha: 2, col: 11)
(SIMBOLO, ";", linha: 2, col: 12)
(EOF, "EOF", linha: 3, col: 1)
```

### Exemplo 19: Comentário de Bloco Multilinha

**Entrada:**
```dart
int x = 10; /* Este é um
comentário de
múltiplas linhas */
int y = 20;
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "int", linha: 1, col: 4)
(IDENTIFICADOR, "x", linha: 1, col: 6)
(OPERADOR, "=", linha: 1, col: 8)
(NUMERO, "10", linha: 1, col: 11)
(SIMBOLO, ";", linha: 1, col: 12)
(PALAVRARESERVADA, "int", linha: 4, col: 4)
(IDENTIFICADOR, "y", linha: 4, col: 6)
(OPERADOR, "=", linha: 4, col: 8)
(NUMERO, "20", linha: 4, col: 11)
(SIMBOLO, ";", linha: 4, col: 12)
(EOF, "EOF", linha: 5, col: 1)
```

**Observação:** O comentário de bloco pode abranger múltiplas linhas e é completamente ignorado.

---

## Tratamento de Erros

### Exemplo 20: String Não Fechada

**Entrada:**
```dart
string nome = "João
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "string", linha: 1, col: 7)
(IDENTIFICADOR, "nome", linha: 1, col: 12)
(OPERADOR, "=", linha: 1, col: 14)
(EOF, "EOF", linha: 2, col: 1)
```

**Erro reportado:**
```
Erro léxico: String não fechada - quebra de linha dentro da string
Linha: 1, Coluna: 15
Contexto: string nome = "João
```

### Exemplo 21: Caractere Inválido

**Entrada:**
```dart
int x @ 10;
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "int", linha: 1, col: 4)
(IDENTIFICADOR, "x", linha: 1, col: 6)
(EOF, "EOF", linha: 1, col: 13)
```

**Erro reportado:**
```
Erro léxico: Caractere inválido: @
Linha: 1, Coluna: 8
Contexto: int x @ 10;
```

### Exemplo 22: Escape Sequence Inválida

**Entrada:**
```dart
string s = "Hello\kWorld";
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "string", linha: 1, col: 7)
(IDENTIFICADOR, "s", linha: 1, col: 9)
(OPERADOR, "=", linha: 1, col: 11)
(STRING, "HellokWorld", linha: 1, col: 25)
(SIMBOLO, ";", linha: 1, col: 26)
(EOF, "EOF", linha: 1, col: 27)
```

**Erro reportado:**
```
Erro léxico: Escape sequence inválida: \k. Escape sequences válidas: \n, \t, \", \\, \r, \0
Linha: 1, Coluna: 19
Contexto: string s = "Hello\kWorld";
```

**Observação:** O lexer reporta o erro mas continua processando, tratando `\k` como caractere literal.

### Exemplo 23: Comentário de Bloco Não Fechado

**Entrada:**
```dart
int x = 10; /* Comentário não fechado
int y = 20;
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "int", linha: 1, col: 4)
(IDENTIFICADOR, "x", linha: 1, col: 6)
(OPERADOR, "=", linha: 1, col: 8)
(NUMERO, "10", linha: 1, col: 11)
(SIMBOLO, ";", linha: 1, col: 12)
(PALAVRARESERVADA, "int", linha: 2, col: 4)
(IDENTIFICADOR, "y", linha: 2, col: 6)
(OPERADOR, "=", linha: 2, col: 8)
(NUMERO, "20", linha: 2, col: 11)
(SIMBOLO, ";", linha: 2, col: 12)
(EOF, "EOF", linha: 3, col: 1)
```

**Erro reportado:**
```
Erro léxico: Comentário de bloco não fechado - possível ambiguidade sintática
Linha: 1, Coluna: 15
Contexto: int x = 10; /* Comentário não fechado
```

---

## Casos Complexos

### Exemplo 24: Expressão Aritmética

**Entrada:**
```dart
int resultado = (a + b) * 2;
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "int", linha: 1, col: 4)
(IDENTIFICADOR, "resultado", linha: 1, col: 14)
(OPERADOR, "=", linha: 1, col: 16)
(SIMBOLO, "(", linha: 1, col: 18)
(IDENTIFICADOR, "a", linha: 1, col: 19)
(OPERADOR, "+", linha: 1, col: 21)
(IDENTIFICADOR, "b", linha: 1, col: 23)
(SIMBOLO, ")", linha: 1, col: 24)
(OPERADOR, "*", linha: 1, col: 26)
(NUMERO, "2", linha: 1, col: 28)
(SIMBOLO, ";", linha: 1, col: 29)
(EOF, "EOF", linha: 1, col: 30)
```

### Exemplo 25: Condicional com Operadores Lógicos

**Entrada:**
```dart
if (x > 0 && y < 10) {
    z = x + y;
}
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "if", linha: 1, col: 3)
(SIMBOLO, "(", linha: 1, col: 5)
(IDENTIFICADOR, "x", linha: 1, col: 6)
(OPERADOR, ">", linha: 1, col: 8)
(NUMERO, "0", linha: 1, col: 10)
(OPERADOR, "&&", linha: 1, col: 13)
(IDENTIFICADOR, "y", linha: 1, col: 16)
(OPERADOR, "<", linha: 1, col: 18)
(NUMERO, "10", linha: 1, col: 21)
(SIMBOLO, ")", linha: 1, col: 22)
(SIMBOLO, "{", linha: 1, col: 24)
(IDENTIFICADOR, "z", linha: 2, col: 5)
(OPERADOR, "=", linha: 2, col: 7)
(IDENTIFICADOR, "x", linha: 2, col: 9)
(OPERADOR, "+", linha: 2, col: 11)
(IDENTIFICADOR, "y", linha: 2, col: 13)
(SIMBOLO, ";", linha: 2, col: 14)
(SIMBOLO, "}", linha: 3, col: 1)
(EOF, "EOF", linha: 4, col: 1)
```

### Exemplo 26: Programa Completo

**Entrada:**
```dart
int x = 10;
float y = 3.14;
string nome = "João";
bool ativo = true;

if (x > 5 && y < 10.0) {
    x = x + 1;
}
```

**Saída (tokens):**
```
(PALAVRARESERVADA, "int", linha: 1, col: 4)
(IDENTIFICADOR, "x", linha: 1, col: 6)
(OPERADOR, "=", linha: 1, col: 8)
(NUMERO, "10", linha: 1, col: 11)
(SIMBOLO, ";", linha: 1, col: 12)
(PALAVRARESERVADA, "float", linha: 2, col: 6)
(IDENTIFICADOR, "y", linha: 2, col: 8)
(OPERADOR, "=", linha: 2, col: 10)
(NUMERO, "3.14", linha: 2, col: 15)
(SIMBOLO, ";", linha: 2, col: 16)
(PALAVRARESERVADA, "string", linha: 3, col: 7)
(IDENTIFICADOR, "nome", linha: 3, col: 12)
(OPERADOR, "=", linha: 3, col: 14)
(STRING, "João", linha: 3, col: 20)
(SIMBOLO, ";", linha: 3, col: 21)
(PALAVRARESERVADA, "bool", linha: 4, col: 5)
(IDENTIFICADOR, "ativo", linha: 4, col: 11)
(OPERADOR, "=", linha: 4, col: 13)
(BOOLEANO, "true", linha: 4, col: 17)
(SIMBOLO, ";", linha: 4, col: 18)
(PALAVRARESERVADA, "if", linha: 6, col: 3)
(SIMBOLO, "(", linha: 6, col: 5)
(IDENTIFICADOR, "x", linha: 6, col: 6)
(OPERADOR, ">", linha: 6, col: 8)
(NUMERO, "5", linha: 6, col: 10)
(OPERADOR, "&&", linha: 6, col: 13)
(IDENTIFICADOR, "y", linha: 6, col: 16)
(OPERADOR, "<", linha: 6, col: 18)
(NUMERO, "10.0", linha: 6, col: 23)
(SIMBOLO, ")", linha: 6, col: 24)
(SIMBOLO, "{", linha: 6, col: 26)
(IDENTIFICADOR, "x", linha: 7, col: 5)
(OPERADOR, "=", linha: 7, col: 7)
(IDENTIFICADOR, "x", linha: 7, col: 9)
(OPERADOR, "+", linha: 7, col: 11)
(NUMERO, "1", linha: 7, col: 13)
(SIMBOLO, ";", linha: 7, col: 14)
(SIMBOLO, "}", linha: 8, col: 1)
(EOF, "EOF", linha: 9, col: 1)
```

---

## 📝 Notas Importantes

1. **Posição dos Tokens**: Cada token inclui sua posição (linha e coluna) no código-fonte original, facilitando a localização de erros.

2. **Greedy Matching**: O lexer sempre reconhece o token mais longo possível. Por exemplo, `>>>` é reconhecido antes de `>>` ou `>`.

3. **Case Sensitivity**: Palavras reservadas são case-sensitive. `if` é palavra reservada, mas `If` ou `IF` são identificadores.

4. **Espaços e Comentários**: Espaços em branco, tabulações e comentários são completamente ignorados e não geram tokens.

5. **Recuperação de Erros**: Quando um erro léxico é detectado, o lexer reporta o erro mas continua processando o restante do código.

6. **Token EOF**: Sempre é adicionado ao final da lista de tokens para marcar o término da análise.

---

## 🔧 Como Testar

Para testar os exemplos acima, você pode usar o programa principal:

```bash
# Criar arquivo de teste
echo 'int x = 10;' > teste.src

# Executar lexer
dart run bin/main.dart teste.src
```

Ou usar diretamente no código Dart:

```dart
import 'package:compilador/lexica/lexer.dart';

void main() {
  final codigo = 'int x = 10;';
  final lexer = Lexer(codigo);
  final tokens = lexer.analisar();
  
  for (final token in tokens) {
    print(token);
  }
}
```

