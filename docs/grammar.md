# Gramática (EBNF) — Linguagem "Compilador" simplificada

Este documento descreve, em EBNF (Extended Backus–Naur Form), a gramática simplificada suportada pelo parser atual do projeto.

Notas rápidas:
- O identificador de tipo `float` é mapeado internamente para `double` no analisador semântico.
- O terminador de comando é `;`.
- `uids` é um modificador especial que solicita inferência de tipo a partir do inicializador.

Terminologia de tokens (resumida):
- `IDENT` : identificadores (variáveis)
- `INT_LIT` : literais inteiros
- `FLOAT_LIT` : literais de ponto flutuante
- `STRING_LIT` : literais de string
- `BOOL_LIT` : `true` | `false`
- Símbolos: `=`, `;`, `(`, `)`, `{`, `}`, `+`, `-`, `*`, `/`, `<`, `>`, `<=`, `>=`, `==`, `!=`, `&&`, `||`, `!`

Gramática EBNF

program      ::= { declaration | statement } EOF ;

declaration  ::= type_keyword IDENT [ '=' expression ] ';' ;
type_keyword ::= 'uids' | 'int' | 'float' | 'bool' | 'string' ;

statement    ::= assignment
               | if_statement
               | while_statement
               | block
               | expression_statement ;

assignment   ::= IDENT '=' expression ';' ;

if_statement ::= 'if' '(' expression ')' statement [ 'else' statement ] ;

while_statement ::= 'while' '(' expression ')' statement ;

block        ::= '{' { declaration | statement } '}' ;

expression_statement ::= expression ';' ;

// EXPRESSÕES — precedência do mais alto (primary) ao mais baixo (or)
expression   ::= logical_or ;

logical_or   ::= logical_and { '||' logical_and } ;
logical_and  ::= equality { '&&' equality } ;

equality     ::= relational { ( '==' | '!=' ) relational } ;

relational   ::= additive { ( '<' | '>' | '<=' | '>=' ) additive } ;

additive     ::= multiplicative { ( '+' | '-' ) multiplicative } ;

multiplicative ::= unary { ( '*' | '/' ) unary } ;

unary        ::= ( '!' | '-' ) unary | primary ;

primary      ::= INT_LIT
               | FLOAT_LIT
               | STRING_LIT
               | BOOL_LIT
               | IDENT
               | '(' expression ')' ;

Comentários sobre semântica relacionada à gramática
- Declarações com `uids` inferem o tipo pelo inicializador; sem inicializador, o tipo é `dynamic`.
- Declarações com tipos explícitos (`int`, `float`, `bool`, `string`) registram esse tipo para a variável.
- `float` é tratado internamente como `double`. Atribuições/initializers `int -> double` são permitidas por coerção implícita — o analisador emite um aviso (`isWarning: true`).
- `if` e `while` exigem que a expressão condicional seja do tipo `bool` (caso contrário, é um erro semântico).
- O analisador semântico mantém escopos por bloco (`{ ... }`) — variáveis declaradas em um bloco não são visíveis fora dele.

Exemplos válidos
```
uids a = 10;
int b;
float c = 1.5;

if (a < 5) {
  b = b + 1;
} else b = 0;

while (b < 10) {
  b = b + 1;
}
```

Exemplos inválidos (erros semânticos)
- Atribuição com tipos incompatíveis (por exemplo, `int` atribuído a `string` sem conversão).
- Condição de `if`/`while` com tipo não-booleano.

Observações finais
- Esta gramática é deliberadamente simples e corresponde ao parser recursivo-descendente implementado em `lib/parser.dart`.
- Se desejar, posso gerar automaticamente um `docs/parser_design.md` complementar descrevendo a estratégia de parsing (funções, pontos de sincronização, mensagens de erro) a partir do código atual.
# Gramática e Projeto do Parser (EBNF)

Este documento descreve a gramática formal (EBNF) para a linguagem imperativa simplificada usada no projeto, a estratégia de implementação do parser (recursivo-descendente / LL(1) friendly), regras de expressão com precedência, exemplos de entrada/saída aceitos e rejeitados, e mapeamento entre produções e nós do AST que precisaremos implementar.

--

## 1. Objetivo

Fornecer uma gramática clara e não-ambígua, adequada para um parser recursivo-descendente (LL(1) friendly), cobrindo:
- Programa principal: declarações e comandos
- Declarações de variáveis com tipos simples
- Comandos: atribuição, condicional `if-else`, repetição `while`, blocos
- Expressões com precedência (unário, multiplicativo, aditivo, relacional, igualdade, lógica)

## 2. Tokens (terminais)

Usamos tokens fornecidos pelo lexer. Nome dos tokens (mapear para `TokenType`):

- `PALAVRA_RESERVADA` (ex.: `if`, `else`, `while`, `int`, `float`, `bool`, `uids`)
- `IDENT` — identificador (nome de variáveis)
- `NUMBER` — literal numérico (inteiro/float)
- `STRING` — literal string
- `BOOLEAN` — `true`/`false` (opcionalmente tratados como `PALAVRA_RESERVADA` ou token separado)
- `OPERADOR` — + - * / == != < > <= >= && || = etc.
- `SIMBOLO` — ( ) { } ; ,
- `EOF` — fim de arquivo

No EBNF abaixo usaremos símbolos literais para palavras reservadas e símbolos (`if`, `while`, `(`, `)`, `{`, `}`, `;`, `=`), e nomes em maiúsculas para classes de tokens (`IDENT`, `NUMBER`, `STRING`).

## 3. Gramática (EBNF)

Notas de estilo:
- `[...]` indica elemento opcional
- `{...}` indica repetição (0 ou mais)
- `|` escolhe alternativas
- Terminales entre aspas (por exemplo, `if`) representam palavras reservadas ou símbolos específicos

```ebnf
Program      ::= Declarations Commands EOF

Declarations ::= { Declaration }
Declaration  ::= Type IDENT ';'
Type         ::= 'int' | 'float' | 'bool' | 'string' | 'uids'

Commands     ::= { Command }
Command      ::= Assignment
               | Conditional
               | Repetition
               | Block
               | ';'   /* empty statement allowed for recovery */

Assignment   ::= IDENT '=' Expression ';'

Conditional  ::= 'if' '(' Expression ')' Command [ 'else' Command ]

Repetition   ::= 'while' '(' Expression ')' Command

Block        ::= '{' { Command } '}'

/* Expressions with precedence (lowest -> highest) */
Expression   ::= LogicalOr

LogicalOr    ::= LogicalAnd { '||' LogicalAnd }
LogicalAnd   ::= Equality { '&&' Equality }

Equality     ::= Relational { ( '==' | '!=' ) Relational }
Relational   ::= Additive { ( '<' | '>' | '<=' | '>=' ) Additive }

Additive     ::= Multiplicative { ( '+' | '-' ) Multiplicative }
Multiplicative ::= Unary { ( '*' | '/' ) Unary }

Unary        ::= ( '+' | '-' | '!' ) Unary | Primary

Primary      ::= NUMBER
               | STRING
               | IDENT
               | 'true' | 'false'
               | '(' Expression ')'
```

### Observações sobre a gramática
- A gramática foi escrita para evitar recursão à esquerda e favorecer parsing LL(1) (adequada para recursivo-descendente). Todas as alternativas repetitivas usam a forma "X ::= Y { op Y }".
- `Block` é um `Command` que contém zero ou mais comandos; isso permite aninhar blocos.
- Permitimos um `;` isolado como `Command` para facilitar recuperação de erros (o parser tratará isto como instrução vazia).

## 4. Erro sintático e recuperação

Estratégia recomendada:
- O parser deve coletar `ParseError` (não lançar exceção fatal na primeira falha sempre que possível).
- Ao detectar um erro, o parser deve chamar uma rotina `_synchronize()` que consome tokens até encontrar um delimitador de ponto de sincronização: `;`, `}` ou uma palavra reservada que inicia uma declaração/comando (`if`, `while`, tipo, `uids`, etc.).
- Exemplos de mensagens de erro:
  - "Esperado identificador após 'uids' mas encontrado <TOKEN> (linha X, coluna Y)"
  - "Esperado ')' após expressão condicional (linha X, coluna Y)"
  - "Esperado ';' após atribuição (linha X, coluna Y)"

## 5. Mapeamento Gramática → AST

Nós AST a implementar (nomes sugeridos):

- `Program` — contém `List<Stmt> statements` (ou `List<Decl>` e `List<Stmt>` dependendo da implementação)
- `VarDecl` — nó para `Declaration` (tipo, nome, linha, coluna)
- `Block` — nó contendo `List<Stmt>`
- `Assign` (ou `Assignment`) — `Identifier target`, `Expr value`, posição
- `IfStmt` — `Expr condition`, `Stmt thenBranch`, `Stmt? elseBranch`
- `WhileStmt` — `Expr condition`, `Stmt body`

Expressões (existentes no projeto):
- `Literal` — número/string/boolean
- `Identifier` — nome
- `Unary` — operador, operand
- `Binary` — left, operator, right

Compatibilidade: ajuste `lib/ast/ast.dart` para incluir `visitIf`, `visitWhile`, `visitBlock`, `visitAssign`, `visitVarDecl` no `AstVisitor` e implementar `astToJson` para essas estruturas.

## 6. Exemplos (aceitos)

1) Declaração + atribuição simples

```c
int x;
float y;
x = 10;
```

2) If-else

```c
if (x > 0) {
  x = x - 1;
} else {
  x = 0;
}
```

3) While

```c
while (x < 10) x = x + 1;
```

4) Blocos aninhados

```c
{
  int a;
  a = 1;
  {
    a = a + 2;
  }
}
```

## 7. Exemplos (rejeitados) — casos sintaticamente inválidos

- Atribuição sem `;`:

```c
x = 1
```

- `if` sem parênteses:

```c
if x > 0 x = 1;
```

- Declaração sem tipo:

```c
x; // sem 'int' ou outro tipo
```

- Parêntese não fechado

```c
if (x > 0 {
  x = 1;
}
```

Nesses casos o parser deve reportar erro(s) com linha/coluna/contexto e — quando possível — recuperar e continuar analisando o resto do arquivo.

## 8. Integração com o lexer

- O parser recebe um `TokenStream` (lista de `Token` com `tipo`, `lexema`, `linha`, `coluna`).
- Use métodos utilitários no `TokenStream`: `peek()`, `next()`, `expect(tipo)`, e `isAtEnd`.
- Ao gerar mensagens de erro, preencha `ParseError.contexto` usando a função `extractLineContext(src, linha)` (ou similar) para que a CLI possa imprimir a linha com caret e gerar JSON de erros com contexto.

## 9. Estratégia de implementação do parser (passo a passo)

1. Adicionar/estender nós AST para `IfStmt`, `WhileStmt`, `Assign`, `Block`, `VarDecl`.
2. Em `lib/parser.dart` implementar (ou estender) funções:
   - `parseProgram()` (chama `parseDeclarations()` e então `parseCommands()`)
   - `parseDeclarations()` (laço que reconhece `Declaration`)
   - `parseDeclaration()` (reconhece `Type IDENT ;`)
   - `parseCommands()` (laço que chama `parseCommand()`)
   - `parseCommand()` (despacha para `parseAssignment`, `parseIf`, `parseWhile`, `parseBlock`)
   - `parseAssignment()` (IDENT '=' Expression ';')
   - `parseIf()` (conforme gramática)
   - `parseWhile()`
   - `parseBlock()`
   - `parseExpression()` (usar a implementação atual com precedência)
3. Implementar coleta de erros: não lançar exceção fatal em `expect()` — capturar e adicionar `ParseError` com contexto; retornar `null` quando declaração/comando for inválido para continuar.
4. Implementar `_synchronize()` que consome até `;` ou `}` ou palavra reservada iniciadora.

## 10. Testes sugeridos

Criar testes em `test/` cobrindo:
- Declarações válidas e inválidas
- `if` simples, `if-else`, `if` com erro (sem parênteses)
- `while` simples e com bloco
- Atribuições simples, com expressões compostas
- Recuperação de erro: arquivo com múltiplos erros deve produzir várias mensagens (não parar no primeiro)

## 11. Próximos passos imediatos

- Implementar os nós AST listados em `lib/ast/` e atualizar `astToJson`.
- Estender `lib/parser.dart` conforme a estratégia descrita.
- Criar testes de unidade para parser (`test/parser_declarations_test.dart`, `test/parser_if_while_test.dart`).

---

Se concorda com esta gramática e mapeamento para AST, eu prossigo implementando os nós AST (`IfStmt`, `WhileStmt`, `Assign`, `Block`, `VarDecl`) e atualizando `lib/ast/ast.dart`. Deseja que eu continue com essa etapa agora?