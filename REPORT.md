**Resumo**:
- **Propósito**: Documentar a gramática usada pelo parser, decisões de implementação (estratégia), tratamento de erros sintáticos, política de recuperação, pré-varredura semântica, exemplos e instruções de execução.
- **Localização principal do código**: `lib/parser.dart`, `lib/lexer.dart`, `lib/parse_error.dart`, `lib/semantic_analyzer.dart`, `lib/symbol_table.dart`.

**Gramática**:
- O arquivo fonte desta gramática está em `docs/grammar.ebnf` e foi incluído aqui para referência imediata.

```
(* Gramática EBNF usada pelo parser deste projeto. *)

(* Observações relevantes:
   - O parser é manual (recursivo-descendente) e aceita declarações de variável
     com inicializador opcional (ex.: `int x = 1;`).
   - O parser aceita declarações em qualquer posição (top-level ou dentro de blocos).
     A política de uso/declaração (declare-before-use) é aplicada pelo analisador semântico
     para variáveis locais; existe uma etapa opcional de pré-varredura para declarações
     top-level se desejado.
   - Comentários (//, /* */) e espaços são ignorados pelo lexer.
*)

program ::= { declaration_or_statement } ;

(* O parser aceita uma sequência arbitrária de declarações e statements;
  isto cobre tanto o caso Gramática: Programa -> Declarações Comandos
  quanto o estilo permissivo (declarações intercaladas). *)

declaration_or_statement ::= declaration | statement ;

functionDecl  ::= 'public'? 'static'? type IDENT '(' [ paramList ] ')' block ;
paramList     ::= param { ',' param } ;
param         ::= type IDENT ;

(* Declaração de variável: suportamos tipo explícito ou a keyword especial `uids`
  (inferência). Inicializador é opcional — o analisador semântico fará checagens
  de compatibilidade de tipo e possíveis avisos de coerção. *)
varDecl ::= type IDENT [ '=' expression ] ';' | 'uids' IDENT [ '=' expression ] ';' ;

// Tipos básicos
type ::= 'int' | 'float' | 'double' | 'string' | 'bool' ;

// Blocos e statements
block ::= '{' { declaration_or_statement } '}' ;

statement ::= block
            | ifStmt
            | whileStmt
            | forStmt
            | returnStmt
            | exprStmt
            | varDecl
            | ';' ;

ifStmt ::= 'if' '(' expression ')' statement [ 'else' statement ] ;
whileStmt ::= 'while' '(' expression ')' statement ;
forStmt ::= 'for' '(' [ forInit ] ';' [ expression ] ';' [ expression ] ')' statement ;
forInit ::= varDecl | exprStmt ;
returnStmt ::= 'return' [ expression ] ';' ;
exprStmt ::= expression ';' ;

// Expressões (esqueleto com precedência sugerida)
expression ::= assignment ;

assignment ::= conditional [ ( '=' | '+=' | '-=' | '*=' | '/=' ) assignment ] ;

conditional ::= logical_or [ '?' expression ':' conditional ] ;

logical_or ::= logical_and { '||' logical_and } ;
logical_and ::= equality { '&&' equality } ;

equality ::= relational { ( '==' | '!=' ) relational } ;

relational ::= additive { ( '<' | '>' | '<=' | '>=' ) additive } ;

additive ::= multiplicative { ( '+' | '-' ) multiplicative } ;

multiplicative ::= unary { ( '*' | '/' | '%' ) unary } ;

unary ::= ( '+' | '-' | '!' ) unary | primary ;

primary ::= literal | IDENT | '(' expression ')' ;

argList ::= expression { ',' expression } ;

literal ::= NUMBER | STRING | 'true' | 'false' ;

(* Fim da gramática *)
```

**Decisão de implementação (estratégia de parsing)**:
- O parser é implementado manualmente usando uma abordagem recursivo-descendente.
- Expressões são implementadas com funções encadeadas por níveis de precedência (por exemplo: `_parseAssignment`, `_parseConditional`, `_parseLogicalOr`, `_parseLogicalAnd`, `_parseEquality`, `_parseRelational`, `_parseAdditive`, `_parseMultiplicative`, `_parseUnary`, `_parsePrimary`).
- Declarações são aceitas em qualquer posição (permite `varDecl` dentro de blocos e no topo). A separação entre parsing permissivo e checagem semântica é intencional: o parser foca na estrutura sintática e o analisador semântico aplica políticas (p.ex., declare-before-use para locais).

**Tratamento de erros sintáticos**:
- Erros sintáticos usam a classe `ParseError` em `lib/parse_error.dart` com campos padronizados: `mensagem`, `esperado`, `recebido`, `linha`, `coluna`, `contexto`.
- Mensagens formatadas são testadas por `test/parser_error_messages_test.dart`.
- Recuperação de erro: o parser usa `_synchronize()` para pular tokens até encontrar pontos de ressincronização (por exemplo: `;`, `}`, `)`, palavras-chave como `if`, `while`, `for`, `return`, `else`). Isso permite continuar o parsing e coletar múltiplos erros por execução.

**Integração com análise semântica**:
- O `lib/semantic_analyzer.dart` realiza checagens de tipos, escopo e aviso de coerções.
- Há uma etapa de pré-varredura (pre-scan) opcional usada para registrar declarações top-level explícitas antes da análise completa. A pré-varredura evita problemas de forward-reference para declarações com tipo explícito, mas não pré-declara `uids` que dependem de inferência por inicializador.

**Arquivos-chave e responsabilidades**:
- `lib/lexer.dart` / `lib/lexical_definitions.dart`: tokenização, comentários, literais.
- `lib/token.dart`, `lib/token_recognizer.dart`, `lib/token_stream.dart`: suporte aos tokens.
- `lib/parser.dart`: parser recursivo-descendente — entradas principais: `parseProgram()`, `parseDeclaration()`, `parseCommand()` e cadeias de parsing de expressões.
- `lib/parse_error.dart`: representação padronizada de erros sintáticos.
- `lib/semantic_analyzer.dart`: checagens de tipos, escopos, pré-varredura top-level.
- `lib/symbol_table.dart`: implementação de escopos e busca de símbolos.
- `lib/ast/`: definições das nós AST (Program, VarDecl, Assign, Binary, Unary, Identifier, Literal, Block, IfStmt, WhileStmt, etc.).

**Mapeamento para testes (critério de avaliação)**:
- Mensagens de erro sintático (15%): `test/parser_error_messages_test.dart` valida formato e conteúdo das mensagens.
- Recuperação de erros (15%): `test/parser_recovery_test.dart` assegura parse continua após erro.
- Expressões e precedência (20%): `test/expression_precedence_test.dart`, `test/expression_logical_relational_test.dart`.
- Aceitar/Rejeitar (40%): `test/acceptance/` e `test/rejection/` contêm casos mínimos e limites usados para comprovar comportamento.
- Exemplos e ASTs (suporte à documentação): exemplos em `examples/` e ASTs em `examples/ast/`.

**Como executar (ambiente macOS / `zsh`)**:
- Executar todos os testes:

```bash
dart test
```

- Executar uma suíte específica (ex.: testes de parser de mensagens):

```bash
dart test test/parser_error_messages_test.dart
```

- Rodar análise estática e formatação:

```bash
dart analyze
dart format .
```

- Gerar ASTs a partir de exemplos (se houver utilitário no `bin/`):

```bash
dart run bin/debug_parser.dart examples/demo1.src > examples/ast/demo1.json
```

**Exemplos e inspeção**:
- Exemplos de entrada: `examples/*.src`.
- ASTs JSON geradas: `examples/ast/*.json` — úteis para validar saída do parser.

**Checklist / Próximos passos sugeridos**:
- [ ] Executar `dart test` completo e ajustar regressões remanescentes.
- [ ] Rodar `dart analyze` e corrigir problemas relatados.
- [ ] Consolidar `REPORT.md` com evidências de execução (logs de testes, trechos de saída do parser) se necessário para entrega.
- [ ] Adicionar workflow de CI (`.github/workflows/dart.yml`) para automatizar testes e análise.

---

Se quiser, eu já posso:
- Rodar a suíte completa de testes agora e reportar os resultados.
- Adicionar exemplos adicionais na seção `examples/` ou ampliar `docs/grammar.ebnf` com produções faltantes.
- Gerar um `CHANGELOG` resumindo as mudanças sintáticas e semânticas recentes.

Diga qual próximo passo prefere.  