# Exemplos de Código → Bytecode

Este documento apresenta múltiplos exemplos práticos de como o gerador de bytecode transforma código-fonte em instruções de bytecode, mostrando a entrada (código) e a saída (bytecode gerado).

## 📋 Índice

1. [Expressões Aritméticas](#expressões-aritméticas)
2. [Operadores Lógicos](#operadores-lógicos)
3. [Operadores de Comparação](#operadores-de-comparação)
4. [Declaração e Atribuição de Variáveis](#declaração-e-atribuição-de-variáveis)
5. [Atribuições Compostas](#atribuições-compostas)
6. [Operadores Incrementais](#operadores-incrementais)
7. [Condicionais (If/Else)](#condicionais-ifelse)
8. [Laços (While)](#laços-while)
9. [Laços (For)](#laços-for)
10. [Escopo de Variáveis](#escopo-de-variáveis)
11. [Casos Complexos](#casos-complexos)

---

## Expressões Aritméticas

### Exemplo 1: Soma Simples

**Código:**
```dart
int x = a + b;
```

**Bytecode:**
```
pushInt(0)          // Valor padrão temporário (será sobrescrito)
loadVar("a")        // Carrega valor de a
loadVar("b")        // Carrega valor de b
add                 // a + b (resultado na pilha)
storeVar("x")       // x = (a + b)
```

**Explicação:** Avalia `a` e `b`, aplica `add`, armazena resultado em `x`.

### Exemplo 2: Expressão com Precedência

**Código:**
```dart
int x = (a + b) * 2;
```

**Bytecode:**
```
loadVar("a")        // Carrega a
loadVar("b")        // Carrega b
add                 // (a + b) - resultado na pilha
pushInt(2)          // Empilha 2
mul                 // (a + b) * 2
storeVar("x")       // x = resultado
```

**Explicação:** Parênteses são resolvidos pelo parser, gerando bytecode na ordem correta.

### Exemplo 3: Múltiplas Operações

**Código:**
```dart
int x = a + b * c - d;
```

**Bytecode:**
```
loadVar("a")        // Carrega a
loadVar("b")        // Carrega b
loadVar("c")        // Carrega c
mul                 // b * c
add                 // a + (b * c)
loadVar("d")        // Carrega d
sub                 // (a + b * c) - d
storeVar("x")       // x = resultado
```

**Explicação:** Precedência é respeitada: multiplicação antes de adição/subtração.

### Exemplo 4: Divisão e Módulo

**Código:**
```dart
int x = a / b;
int y = a % b;
```

**Bytecode:**
```
loadVar("a")        // Carrega a
loadVar("b")        // Carrega b
div                 // a / b
storeVar("x")       // x = a / b
loadVar("a")        // Carrega a
loadVar("b")        // Carrega b
mod                 // a % b
storeVar("y")       // y = a % b
```

---

## Operadores Lógicos

### Exemplo 5: AND Lógico

**Código:**
```dart
bool resultado = a && b;
```

**Bytecode:**
```
loadVar("a")        // Carrega a (booleano)
loadVar("b")        // Carrega b (booleano)
and                 // a && b (resultado booleano)
storeVar("resultado")
```

### Exemplo 6: OR Lógico

**Código:**
```dart
bool resultado = a || b;
```

**Bytecode:**
```
loadVar("a")        // Carrega a
loadVar("b")        // Carrega b
or                  // a || b
storeVar("resultado")
```

### Exemplo 7: NOT Lógico

**Código:**
```dart
bool resultado = !a;
```

**Bytecode:**
```
loadVar("a")        // Carrega a
not                 // !a
storeVar("resultado")
```

### Exemplo 8: Expressão Lógica Complexa

**Código:**
```dart
bool resultado = a && b || c;
```

**Bytecode:**
```
loadVar("a")        // Carrega a
loadVar("b")        // Carrega b
and                 // a && b
loadVar("c")        // Carrega c
or                  // (a && b) || c
storeVar("resultado")
```

---

## Operadores de Comparação

### Exemplo 9: Comparações Básicas

**Código:**
```dart
bool x = a > b;
bool y = a < b;
bool z = a == b;
```

**Bytecode:**
```
loadVar("a")        // Carrega a
loadVar("b")        // Carrega b
gt                  // a > b (resultado booleano)
storeVar("x")
loadVar("a")        // Carrega a
loadVar("b")        // Carrega b
lt                  // a < b
storeVar("y")
loadVar("a")        // Carrega a
loadVar("b")        // Carrega b
eq                  // a == b
storeVar("z")
```

### Exemplo 10: Comparações com Literais

**Código:**
```dart
bool x = a >= 10;
bool y = b <= 5;
bool z = c != 0;
```

**Bytecode:**
```
loadVar("a")        // Carrega a
pushInt(10)         // Empilha 10
ge                  // a >= 10
storeVar("x")
loadVar("b")        // Carrega b
pushInt(5)          // Empilha 5
le                  // b <= 5
storeVar("y")
loadVar("c")        // Carrega c
pushInt(0)          // Empilha 0
ne                  // c != 0
storeVar("z")
```

---

## Declaração e Atribuição de Variáveis

### Exemplo 11: Declaração com Inicializador

**Código:**
```dart
int x = 10;
float y = 3.14;
bool ativo = true;
string nome = "João";
```

**Bytecode:**
```
pushInt(10)         // Empilha 10
storeVar("x")       // x = 10
pushDouble(3.14)    // Empilha 3.14
storeVar("y")       // y = 3.14
pushBool(true)      // Empilha true
storeVar("ativo")   // ativo = true
pushString("João")  // Empilha "João"
storeVar("nome")    // nome = "João"
```

### Exemplo 12: Declaração sem Inicializador

**Código:**
```dart
int x;
float y;
bool ativo;
string nome;
```

**Bytecode:**
```
pushInt(0)          // Valor padrão para int
storeVar("x")       // x = 0
pushDouble(0.0)     // Valor padrão para double
storeVar("y")       // y = 0.0
pushBool(false)     // Valor padrão para bool
storeVar("ativo")   // ativo = false
pushString("")      // Valor padrão para string
storeVar("nome")    // nome = ""
```

### Exemplo 13: Atribuição Simples

**Código:**
```dart
x = 10;
y = x + 5;
```

**Bytecode:**
```
pushInt(10)         // Empilha 10
storeVar("x")       // x = 10
loadVar("x")        // Carrega x
pushInt(5)          // Empilha 5
add                 // x + 5
storeVar("y")       // y = x + 5
```

---

## Atribuições Compostas

### Exemplo 14: Atribuição com Adição

**Código:**
```dart
x += 5;
```

**Bytecode:**
```
loadVar("x")        // Carrega valor atual de x
pushInt(5)          // Empilha 5
add                 // x + 5
storeVar("x")       // x = x + 5
```

**Equivalente a:** `x = x + 5;`

### Exemplo 15: Atribuição com Subtração

**Código:**
```dart
x -= 3;
```

**Bytecode:**
```
loadVar("x")        // Carrega x
pushInt(3)          // Empilha 3
sub                 // x - 3
storeVar("x")       // x = x - 3
```

### Exemplo 16: Atribuição com Multiplicação

**Código:**
```dart
x *= 2;
```

**Bytecode:**
```
loadVar("x")        // Carrega x
pushInt(2)          // Empilha 2
mul                 // x * 2
storeVar("x")       // x = x * 2
```

### Exemplo 17: Atribuição com Divisão

**Código:**
```dart
x /= 2;
```

**Bytecode:**
```
loadVar("x")        // Carrega x
pushInt(2)          // Empilha 2
div                 // x / 2
storeVar("x")       // x = x / 2
```

---

## Operadores Incrementais

### Exemplo 18: Incremento Prefixo

**Código:**
```dart
++i;
```

**Bytecode:**
```
loadVar("i")        // Carrega i (ex: 5)
pushInt(1)          // Empilha 1
add                 // i + 1 = 6
storeVar("i")       // i = 6
// Valor 6 está na pilha (retornado)
```

**Resultado:** `i` é incrementado para 6, expressão retorna 6.

### Exemplo 19: Incremento Postfix

**Código:**
```dart
i++;
```

**Bytecode:**
```
loadVar("i")        // Carrega i (ex: 5) - será retornado
loadVar("i")        // Carrega i novamente para incrementar
pushInt(1)          // Empilha 1
add                 // i + 1 = 6
storeVar("i")       // i = 6
// Valor 5 (antigo) ainda está na pilha (retornado)
```

**Resultado:** `i` é incrementado para 6, mas expressão retorna 5 (valor antigo).

### Exemplo 20: Decremento Prefixo

**Código:**
```dart
--j;
```

**Bytecode:**
```
loadVar("j")        // Carrega j
pushInt(1)          // Empilha 1
sub                 // j - 1
storeVar("j")       // j = j - 1
// Novo valor está na pilha
```

### Exemplo 21: Incremento em Atribuição

**Código:**
```dart
int x = ++i;
```

**Bytecode:**
```
loadVar("i")        // Carrega i
pushInt(1)          // Empilha 1
add                 // i + 1
storeVar("i")       // i = i + 1
storeVar("x")       // x = novo valor de i
```

**Resultado:** `i` é incrementado, `x` recebe o novo valor.

### Exemplo 22: Postfix em Atribuição

**Código:**
```dart
int x = i++;
```

**Bytecode:**
```
loadVar("i")        // Carrega i (será retornado)
loadVar("i")        // Carrega i para incrementar
pushInt(1)          // Empilha 1
add                 // i + 1
storeVar("i")       // i = i + 1
storeVar("x")       // x = valor antigo de i
```

**Resultado:** `i` é incrementado, mas `x` recebe o valor antigo.

---

## Condicionais (If/Else)

### Exemplo 23: If Simples

**Código:**
```dart
if (x > 0) {
    y = 1;
}
```

**Bytecode:**
```
loadVar("x")           // Carrega x
pushInt(0)             // Empilha 0
gt                     // x > 0
jumpIfFalse(else_0)    // Se falso, pula para else_0
pushInt(1)             // Bloco then: y = 1
storeVar("y")
else_0:                // Label do fim (sem else)
```

### Exemplo 24: If com Else

**Código:**
```dart
if (x > 0) {
    y = 1;
} else {
    y = 2;
}
```

**Bytecode:**
```
loadVar("x")           // Carrega x
pushInt(0)             // Empilha 0
gt                     // x > 0
jumpIfFalse(else_0)    // Se falso, pula para else_0
pushInt(1)             // Bloco then: y = 1
storeVar("y")
jump(endif_0)          // Pula para fim (evita executar else)
else_0:                // Label do else
pushInt(2)             // Bloco else: y = 2
storeVar("y")
endif_0:               // Label do fim
```

### Exemplo 25: If com Condição Complexa

**Código:**
```dart
if (x > 0 && y < 10) {
    z = x + y;
}
```

**Bytecode:**
```
loadVar("x")           // Carrega x
pushInt(0)             // Empilha 0
gt                     // x > 0
loadVar("y")           // Carrega y
pushInt(10)            // Empilha 10
lt                     // y < 10
and                    // (x > 0) && (y < 10)
jumpIfFalse(else_0)    // Se falso, pula
loadVar("x")           // Bloco then: z = x + y
loadVar("y")
add
storeVar("z")
else_0:                // Fim
```

---

## Laços (While)

### Exemplo 26: While Simples

**Código:**
```dart
while (x > 0) {
    x = x - 1;
}
```

**Bytecode:**
```
loop_start_0:          // Label de início
loadVar("x")           // Carrega x
pushInt(0)             // Empilha 0
gt                     // x > 0
jumpIfFalse(loop_end_0) // Se falso, sai do loop
loadVar("x")           // Corpo: x = x - 1
pushInt(1)
sub
storeVar("x")
jump(loop_start_0)     // Volta para início
loop_end_0:            // Label de fim
```

### Exemplo 27: While com Múltiplas Instruções

**Código:**
```dart
while (i < 10) {
    soma = soma + i;
    i = i + 1;
}
```

**Bytecode:**
```
loop_start_0:          // Início
loadVar("i")           // Condição: i < 10
pushInt(10)
lt
jumpIfFalse(loop_end_0)
loadVar("soma")        // Corpo: soma = soma + i
loadVar("i")
add
storeVar("soma")
loadVar("i")           // i = i + 1
pushInt(1)
add
storeVar("i")
jump(loop_start_0)     // Volta
loop_end_0:            // Fim
```

---

## Laços (For)

### Exemplo 28: For Básico

**Código:**
```dart
for (int i = 0; i < 10; i++) {
    x = x + i;
}
```

**Bytecode:**
```
enterScope             // Novo escopo para i
pushInt(0)             // Inicialização: i = 0
storeVar("i")
for_start_0:           // Início do loop
loadVar("i")           // Condição: i < 10
pushInt(10)
lt
jumpIfFalse(for_end_0) // Se falso, sai
loadVar("x")           // Corpo: x = x + i
loadVar("i")
add
storeVar("x")
for_continue_0:        // Update
loadVar("i")           // i++ (postfix)
loadVar("i")
pushInt(1)
add
storeVar("i")
pop                    // Descarta resultado
jump(for_start_0)      // Volta
for_end_0:             // Fim
exitScope              // Sai do escopo (i não é mais acessível)
```

### Exemplo 29: For sem Inicialização

**Código:**
```dart
for (; i < 10; i++) {
    x = x + 1;
}
```

**Bytecode:**
```
enterScope             // Novo escopo
for_start_0:           // Início (sem inicialização)
loadVar("i")           // Condição: i < 10
pushInt(10)
lt
jumpIfFalse(for_end_0)
loadVar("x")           // Corpo: x = x + 1
pushInt(1)
add
storeVar("x")
for_continue_0:        // Update: i++
loadVar("i")
loadVar("i")
pushInt(1)
add
storeVar("i")
pop
jump(for_start_0)
for_end_0:
exitScope
```

### Exemplo 30: For sem Condição

**Código:**
```dart
for (int i = 0; ; i++) {
    if (i >= 10) break;
    x = x + i;
}
```

**Bytecode:**
```
enterScope
pushInt(0)             // Inicialização: i = 0
storeVar("i")
for_start_0:           // Início (sem condição - loop infinito)
// ... código do corpo com break interno ...
for_continue_0:        // Update: i++
loadVar("i")
loadVar("i")
pushInt(1)
add
storeVar("i")
pop
jump(for_start_0)
for_end_0:
exitScope
```

---

## Escopo de Variáveis

### Exemplo 31: Bloco com Escopo Local

**Código:**
```dart
int x = 0;
{
    int x = 10;
    int y = 20;
}
// x externo ainda é 0
```

**Bytecode:**
```
pushInt(0)             // x global = 0
storeVar("x")
enterScope             // Novo escopo (bloco)
pushInt(10)            // x local = 10
storeVar("x")
pushInt(20)            // y local = 20
storeVar("y")
exitScope              // Sai do escopo (x local e y são descartados)
// x global ainda é 0
```

**Explicação:** Variáveis locais são descartadas ao sair do escopo.

### Exemplo 32: Escopo Aninhado

**Código:**
```dart
int x = 0;
{
    int y = 10;
    {
        int z = 20;
    }
    // z não é acessível aqui
}
// y e z não são acessíveis aqui
```

**Bytecode:**
```
pushInt(0)             // x global = 0
storeVar("x")
enterScope             // Escopo 1
pushInt(10)            // y = 10
storeVar("y")
enterScope             // Escopo 2 (aninhado)
pushInt(20)            // z = 20
storeVar("z")
exitScope              // Sai escopo 2 (z descartado)
exitScope              // Sai escopo 1 (y descartado)
```

---

## Casos Complexos

### Exemplo 33: Programa Completo

**Código:**
```dart
int soma = 0;
int i = 0;

while (i < 10) {
    if (i % 2 == 0) {
        soma = soma + i;
    }
    i = i + 1;
}
```

**Bytecode:**
```
pushInt(0)             // soma = 0
storeVar("soma")
pushInt(0)             // i = 0
storeVar("i")
loop_start_0:          // While: i < 10
loadVar("i")
pushInt(10)
lt
jumpIfFalse(loop_end_0)
loadVar("i")           // If: i % 2 == 0
pushInt(2)
mod
pushInt(0)
eq
jumpIfFalse(else_0)
loadVar("soma")        // Then: soma = soma + i
loadVar("i")
add
storeVar("soma")
else_0:                // Fim do if
loadVar("i")           // i = i + 1
pushInt(1)
add
storeVar("i")
jump(loop_start_0)     // Volta
loop_end_0:            // Fim do while
halt                   // Fim do programa
```

### Exemplo 34: For com Expressão Complexa

**Código:**
```dart
int soma = 0;
for (int i = 0; i < 10; i++) {
    soma = soma + i * 2;
}
```

**Bytecode:**
```
pushInt(0)             // soma = 0
storeVar("soma")
enterScope             // Escopo do for
pushInt(0)             // i = 0
storeVar("i")
for_start_0:           // Início
loadVar("i")           // Condição: i < 10
pushInt(10)
lt
jumpIfFalse(for_end_0)
loadVar("soma")        // Corpo: soma = soma + i * 2
loadVar("i")
pushInt(2)
mul                    // i * 2
add                    // soma + (i * 2)
storeVar("soma")
for_continue_0:        // Update: i++
loadVar("i")
loadVar("i")
pushInt(1)
add
storeVar("i")
pop
jump(for_start_0)
for_end_0:
exitScope
halt
```

### Exemplo 35: Expressão com Múltiplos Operadores

**Código:**
```dart
int resultado = (a + b) * (c - d) / 2;
```

**Bytecode:**
```
loadVar("a")           // Carrega a
loadVar("b")           // Carrega b
add                    // (a + b)
loadVar("c")           // Carrega c
loadVar("d")           // Carrega d
sub                    // (c - d)
mul                    // (a + b) * (c - d)
pushInt(2)             // Empilha 2
div                    // ((a + b) * (c - d)) / 2
storeVar("resultado")
```

---

## 📝 Notas Importantes

1. **Pilha de Valores**: O bytecode usa uma pilha para avaliar expressões. Valores são empilhados e operações consomem valores do topo da pilha.

2. **Ordem de Avaliação**: Operandos são avaliados da esquerda para a direita, mas operações seguem precedência (multiplicação antes de adição).

3. **Labels**: Labels são gerados automaticamente com contadores únicos para evitar conflitos em loops aninhados.

4. **Escopos**: `enterScope` e `exitScope` marcam início e fim de escopos. Variáveis locais são descartadas ao sair do escopo.

5. **Tratamento de Erros**: O gerador verifica se variáveis existem antes de usar, reportando erros semânticos.

6. **Prefixo vs Postfix**: 
   - `++i`: incrementa primeiro, retorna novo valor
   - `i++`: retorna valor atual, depois incrementa

---

## 🔧 Como Testar

Para testar os exemplos acima, você pode usar o programa principal:

```bash
# Criar arquivo de teste
echo 'int x = 10;' > teste.src

# Executar gerador de bytecode
dart run bin/main.dart teste.src --dump-bytecode
```

Ou usar diretamente no código Dart:

```dart
import 'package:compilador/lexica/lexer.dart';
import 'package:compilador/token_stream.dart';
import 'package:compilador/sintatica/parser.dart';
import 'package:compilador/semantic_analyzer.dart';
import 'package:compilador/vm/bytecode_generator.dart';

void main() {
  final codigo = 'int x = 10;';
  final lexer = Lexer(codigo);
  final tokens = lexer.analisar();
  final parser = Parser(TokenStream(tokens), codigo);
  final program = parser.parseProgram();
  
  final analyzer = SemanticAnalyzer(null, codigo);
  final symbolTable = analyzer.analyze(program);
  
  final generator = BytecodeGenerator(symbolTable);
  final bytecode = generator.generate(program);
  
  print(bytecode.toString());
}
```

