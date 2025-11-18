# Testes dos Operadores Incrementais (++ e --)

Este documento descreve os testes criados para validar a implementação dos operadores incrementais `++` e `--` (prefixo e sufixo).

## Implementação Realizada

### 1. Parser (`lib/parser.dart`)

**Modificações:**
- Adicionado suporte para `++` e `--` no método `_parseUnary()` (operadores prefixo)
- Criado novo método `_parsePostfix()` para tratar operadores sufixo (`i++`, `i--`)
- Operadores postfix são marcados com sufixo `post` (ex: `++post`, `--post`) para diferenciação

### 2. Gerador de Bytecode (`lib/bytecode_generator.dart`)

**Modificações no `visitUnary`:**
- Diferenciamento entre prefixo (`++i`, `--i`) e postfix (`i++`, `i--`)
- **Prefixo**: Incrementa primeiro, depois retorna o novo valor
- **Postfix**: Retorna o valor antigo, depois incrementa

## Comportamento Esperado

### Prefixo (`++i`, `--i`)

```dart
int i = 5;
++i;  // i agora é 6, a expressão retorna 6
```

**Bytecode gerado:**
```
loadVar("i")    // Carrega valor atual (5)
pushInt(1)      // Empilha 1
add             // Soma: 5 + 1 = 6
storeVar("i")   // Armazena 6 em i
// Resultado 6 permanece na pilha
```

### Postfix (`i++`, `i--`)

```dart
int i = 5;
i++;  // i agora é 6, mas a expressão retorna 5 (valor antigo)
```

**Bytecode gerado:**
```
loadVar("i")    // Carrega valor atual (5) - será retornado
loadVar("i")    // Carrega novamente para incrementar (5)
pushInt(1)      // Empilha 1
add             // Soma: 5 + 1 = 6
storeVar("i")   // Armazena 6 em i
// Resultado 5 (valor antigo) permanece na pilha
```

## Testes Criados

### Arquivo: `test/bytecode_increment_test.dart`

Conjunto completo de testes unitários:

1. **Prefixo ++i em expressão**
   - Testa que `++i` gera bytecode correto
   - Verifica instruções: `loadVar`, `pushInt(1)`, `add`, `storeVar`

2. **Postfix i++ em expressão**
   - Testa que `i++` gera bytecode correto
   - Verifica que carrega a variável duas vezes (uma para retornar, outra para incrementar)

3. **Prefixo --i**
   - Testa decremento prefixo
   - Verifica uso de `sub` ao invés de `add`

4. **Postfix i--**
   - Testa decremento postfix
   - Verifica uso de `sub`

5. **i++ em loop for**
   - Testa uso em update de loop for
   - Verifica geração correta no contexto de loop

6. **++i em atribuição**
   - Testa `int j = ++i;`
   - Verifica que novo valor é atribuído

7. **i++ em atribuição**
   - Testa `int j = i++;`
   - Verifica que valor antigo é atribuído a j

8. **Erro: variável não declarada**
   - Testa `++x;` onde x não existe
   - Verifica geração de erro semântico

9. **Erro: tipo não numérico**
   - Testa `++s;` onde s é string
   - Verifica geração de erro semântico

### Arquivo: `tools/test_increment.dart`

Script manual de teste para execução rápida:

```bash
dart run tools/test_increment.dart
```

Testa todos os casos acima e imprime o bytecode gerado em formato legível.

### Arquivo: `examples/test_i_plus_plus.src`

Exemplo simples de código fonte:

```dart
int i = 5;
i++;
int j = i;
```

## Como Executar os Testes

### Opção 1: Testes Unitários

```bash
cd Compiladores
dart test test/bytecode_increment_test.dart
```

### Opção 2: Script Manual

```bash
cd Compiladores
dart run tools/test_increment.dart
```

### Opção 3: Teste via Main

```bash
cd Compiladores
dart run bin/main.dart examples/test_i_plus_plus.src --dump-ast-json
```

## Exemplos de Saída Esperada

### Teste: Prefixo ++i

```
Código:
int i = 5;
++i;

BYTECODE GERADO:
  0: pushInt(5)
  1: storeVar(i)
  2: loadVar(i)
  3: pushInt(1)
  4: add
  5: storeVar(i)
  6: pop
  7: halt
```

### Teste: Postfix i++

```
Código:
int i = 5;
i++;

BYTECODE GERADO:
  0: pushInt(5)
  1: storeVar(i)
  2: loadVar(i)    // Valor antigo (será retornado)
  3: loadVar(i)    // Valor para incrementar
  4: pushInt(1)
  5: add
  6: storeVar(i)   // Armazena novo valor
  7: pop           // Descarta resultado (valor antigo)
  8: halt
```

### Teste: i++ em atribuição

```dart
int i = 5;
int j = i++;
```

**Comportamento:**
- `i` termina com valor 6
- `j` recebe valor 5 (valor antigo de i)

## Verificações Implementadas

1. ✅ Parser reconhece `++` e `--` como prefixo e sufixo
2. ✅ Gerador diferencia prefixo de postfix
3. ✅ Prefixo retorna novo valor
4. ✅ Postfix retorna valor antigo
5. ✅ Verificação de variável declarada
6. ✅ Verificação de tipo numérico
7. ✅ Funciona em expressões, atribuições e loops

## Notas de Implementação

- Operadores postfix são marcados internamente como `++post` e `--post` para diferenciação
- O gerador de bytecode detecta o sufixo `post` para aplicar a lógica correta
- Para postfix, a variável é carregada duas vezes: uma para retornar o valor antigo e outra para incrementar

