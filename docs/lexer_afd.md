# Documentação do Autômato Finito Determinístico (AFD) - Lexer

## Visão Geral

O analisador léxico implementa um **Autômato Finito Determinístico (AFD)** de forma manual através de um loop principal que processa o código-fonte caractere a caractere. Cada estado do autômato é determinado pelo caractere atual e pelas condições de transição.

## Estrutura do AFD

O AFD opera através do método `Lexer.analisar()`, que funciona como o loop principal do autômato. Cada iteração representa uma transição de estado baseada no caractere atual.

### Estados Principais

O autômato possui os seguintes estados implícitos:

1. **Estado Inicial (start)**: Estado inicial antes de processar qualquer caractere
2. **Estado de Espaço em Branco**: Ignora espaços, tabulações e quebras de linha
3. **Estado de Comentário de Linha**: Processa comentários `//`
4. **Estado de Comentário de Bloco**: Processa comentários `/* */`
5. **Estado de String**: Processa strings literais entre aspas duplas
6. **Estado de Número**: Processa números inteiros, decimais e notação científica
7. **Estado de Identificador**: Processa identificadores e palavras reservadas
8. **Estado de Operador/Símbolo**: Processa operadores e símbolos especiais
9. **Estado de Erro**: Detecta caracteres inválidos

## Diagrama de Transições

```
                    +-------+
                    | START |
                    +---+---+
                        |
        ┌───────────────┼───────────────┐
        |               |               |
    [espaço]      [letra]         [dígito]
        |               |               |
        v               v               v
   IGNORA        IDENTIFICADOR    NÚMERO
        |               |               |
        |               |               |
        |               |               |
    [palavra      [número      [número
     reservada]    decimal]     científico]
        |               |               |
        +───────────────┴───────────────+
                        |
                        v
                   EMIT TOKEN
                        |
        ┌───────────────┼───────────────┐
        |               |               |
     [" "]         ["/"]          [operador]
        |               |               |
        |          ┌────┴────┐          |
        |          |         |          |
        |       ["/"]     ["*"]         |
        |          |         |          |
        |    COMENTÁRIO  COMENTÁRIO     |
        |      LINHA      BLOCO         |
        |          |         |          |
        |          |         |          |
        +──────────┴─────────┴──────────+
                        |
                        v
                   [caractere
                    inválido]
                        |
                        v
                    ERRO LÉXICO
```

## Detalhamento dos Estados

### 1. Estado de Espaço em Branco

**Transição**: Qualquer espaço (` `), tabulação (`\t`) ou quebra de linha (`\n`, `\r\n`)

**Ação**: 
- Avança o ponteiro sem emitir token
- Atualiza contadores de linha/coluna para quebras de linha
- Retorna ao estado inicial

**Código**:
```dart
if (char == ' ' || char == '\t') {
  avancar();
  continue;
}
```

### 2. Estado de Comentário de Linha

**Transição**: Caractere `/` seguido de `/`

**Ação**:
- Consome todos os caracteres até encontrar `\n`
- Não emite token
- Retorna ao estado inicial

**Prioridade**: Verificado antes de operadores para evitar ambiguidade

### 3. Estado de Comentário de Bloco

**Transição**: Caractere `/` seguido de `*`

**Ação**:
- Consome todos os caracteres até encontrar `*/`
- Atualiza linha/coluna durante o processamento
- Se não encontrar `*/` antes do EOF, emite erro léxico
- Retorna ao estado inicial

### 4. Estado de String

**Transição**: Caractere `"`

**Ação**:
- Consome caracteres até encontrar `"` de fechamento
- Processa escape sequences (`\n`, `\t`, `\"`, `\\`, etc.)
- Se encontrar `\n` antes de fechar, emite erro
- Se chegar ao EOF sem fechar, emite erro
- Emite token `TokenType.string` com o conteúdo (sem aspas)

**Escape Sequences Suportadas**:
- `\n` - Nova linha
- `\t` - Tabulação
- `\"` - Aspas duplas
- `\\` - Barra invertida
- `\r` - Retorno de carro
- `\0` - Caractere nulo

**Validação**: Escape sequences inválidas geram erro léxico

### 5. Estado de Número

**Transição**: Dígito (`0-9`) ou ponto (`.`) seguido de dígito

**Ação**:
- Consome dígitos consecutivos
- Se encontrar `.` seguido de dígito, processa parte decimal
- Se encontrar `e` ou `E`, processa notação científica
- Valida formato (não aceita apenas `.` sem dígitos)
- Emite token `TokenType.numero`

**Formatos Aceitos**:
- Inteiros: `123`, `0`, `42`
- Decimais: `1.5`, `0.5`, `.5` (sem parte inteira - **aceito**)
- Notação científica: `1.23e5`, `1.23e+5`, `1.23e-5`, `.5e10`

**Validações**:
- Pelo menos um dígito deve ser consumido
- Expoente deve ser seguido de dígitos (opcionalmente precedido de `+` ou `-`)
- Números malformados geram erro léxico

### 6. Estado de Identificador

**Transição**: Letra (`a-z`, `A-Z`) ou underscore (`_`)

**Ação**:
- Consome letras, dígitos e underscores consecutivos
- Verifica se é palavra reservada
- Se for `true` ou `false`, emite `TokenType.booleano`
- Caso contrário, emite `TokenType.identificador` ou `TokenType.palavraReservada`

**Regex**: `[a-zA-Z_][a-zA-Z0-9_]*`

### 7. Estado de Operador/Símbolo

**Transição**: Caractere que pertence ao conjunto de operadores ou símbolos

**Ação**:
- **Greedy Matching**: Tenta reconhecer primeiro operadores de 3 caracteres, depois 2, depois 1
- Prioriza tokens maiores para evitar ambiguidade
- Emite token `TokenType.operador` ou `TokenType.simbolo`

**Exemplo de Priorização**:
```
>>> (3 chars) > >> (2 chars) > > (1 char)
```

### 8. Estado de Erro

**Transição**: Caractere que não corresponde a nenhum padrão válido

**Ação**:
- Emite erro léxico com mensagem descritiva
- Inclui posição (linha/coluna) e contexto
- Avança o ponteiro para continuar análise (recuperação de erro)

## Estratégia de Greedy Matching

O lexer utiliza **greedy matching** (casamento guloso) para garantir que sempre reconhece o token mais longo possível. Isso é especialmente importante para:

1. **Operadores Multi-caractere**: `>>>` é reconhecido antes de `>>` ou `>`
2. **Números**: `123.45` é reconhecido como um único token, não `123` + `.` + `45`
3. **Identificadores**: `while` é reconhecido como palavra reservada, não como `w` + `hile`

## Ordem de Verificação (Prioridade)

A ordem de verificação no método `analisar()` é crucial para evitar ambiguidades:

1. Espaços em branco (ignorados)
2. Quebras de linha (ignoradas)
3. Comentários de linha `//` (verificado antes de operador `/`)
4. Comentários de bloco `/*` (verificado antes de operador `/`)
5. Strings `"` (verificado antes de qualquer outro caractere especial)
6. Números (verificado antes de identificadores para evitar conflito)
7. Identificadores (verificado antes de operadores)
8. Operadores/Símbolos
9. Erro (caractere inválido)

## Recuperação de Erros

Quando um erro léxico é detectado:

1. O erro é registrado no `ErrorHandler` com:
   - Mensagem descritiva
   - Linha e coluna exatas
   - Contexto (trecho do código ao redor)
2. O ponteiro avança para continuar a análise
3. A análise não é interrompida (permite detectar múltiplos erros)

## Token EOF

Ao final da análise, um token especial `TokenType.eof` é adicionado para indicar o fim do arquivo. Este token é útil para o parser identificar o fim da entrada.

## Complexidade

- **Tempo**: O(n), onde n é o número de caracteres no código-fonte
- **Espaço**: O(m), onde m é o número de tokens reconhecidos

## Referências

- Aho, A. V., Lam, M. S., Sethi, R., & Ullman, J. D. (2006). *Compilers: Principles, Techniques, and Tools* (2nd ed.). Pearson Education.
- Cooper, K. D., & Torczon, L. (2011). *Engineering a Compiler* (2nd ed.). Morgan Kaufmann.

