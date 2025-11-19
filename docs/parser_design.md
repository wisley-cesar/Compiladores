# Gramática e Projeto do Parser (EBNF)

Este documento descreve a implementação atual do parser recursivo-descendente em `lib/parser.dart`.
Ele documenta as funções principais, estratégias de recuperação de erro, pontos de sincronização e formatos das mensagens de erro.

1. Visão geral
- O parser consome um `TokenStream` (`lib/token_stream.dart`) produzido pelo `Lexer` e constrói uma árvore AST (`lib/ast/*`).
- É um parser manual, escrito em estilo recursivo-descendente (top-down). As funções de parsing correspondem a não-terminais da gramática.
- Erros de parsing são coletados no campo `errors` do `Parser` como instâncias de `ParseError` para permitir análise contínua e geração de múltiplos erros por execução.

2. Entrada e API principal
- Construtor: `Parser(TokenStream tokens, [String src = ''])` — o parâmetro `src` é opcional e usado para preencher o `contexto` (snippet) nas mensagens de erro.
- Ponto de entrada: `Program parseProgram()` — itera até EOF, parseando declarações (quando o próximo token é uma palavra-reservada de tipo) ou comandos/expressões caso contrário.

3. Funções chave e responsabilidades
- `_isTypeKeyword(Token t)` — identifica palavras-reservadas que iniciam declarações (`int`, `float`, `bool`, `string`, `uids`).

- `parseDeclaration()` / `parseVarDecl()` — lidam com declaração de variáveis:
  - `parseDeclaration()` é o caminho principal que consome um `type_keyword`, espera um `IDENT`, lê opcionalmente `= expression`, e exige `;`.
  - Em caso de erro (tipo faltando, identificador faltando, `;` faltando) registra um `ParseError` com linha/coluna/contexto e chama `_synchronize()` para recuperar.
  - `parseVarDecl()` existe como variante focada em `uids` com heurísticas extras para gerar mensagens mais amigáveis.

- `parseCommand()` — detecta e roteia para:
  - `parseIf()` quando token `if`;
  - `parseWhile()` quando token `while`;
  - `parseBlock()` quando token `{`;
  - `parseAssignment()` quando o padrão `IDENT '='` é visto;
  - trata `;` como declaração vazia;
  - caso encontre token inesperado, registra erro e chama `_synchronize()`.

- `parseAssignment()` — consome `IDENT`, espera `=`, parseia expressão e exige `;`. Em falha, registra `ParseError` e tenta recuperar.

- `parseIf()` / `parseWhile()` — ambos exigem parênteses em torno da expressão condicional, parseiam a condição com `parseExpression()` e esperam um `statement` como corpo. Suportam forma curta (`if (cond) stmt;`) ou bloco. Tratam `else` no `if`.

- `parseBlock()` — consome `{`, repete `parseCommand()` até encontrar `}`, monta `Block` com lista de statements. Se `}` não for encontrado, registra erro e sincroniza, mas retorna o bloco com o conteúdo já coletado.

4. Parsing de expressões (precedência)
- Entrada: `parseExpression()` chama `_parseAdditive()` como ponto de entrada para a hierarquia.
- Estrutura de precedência (mais baixo à mais alto):
  - aditivo: `+`, `-` (_parseAdditive)
  - multiplicativo: `*`, `/` (_parseMultiplicative)
  - unary: `+`, `-` (direita-associativo via _parseUnary)
  - primary: números, strings, booleanos, identificadores, parênteses (_parsePrimary)
- Operadores relacionais/equality/logic foram modelados nas versões anteriores e podem ser estendidos mantendo o padrão `left { op right }` para manter LL(1).

5. Reconhecimento de literais e tipos
- `_parsePrimary()` reconhece tokens de número, string, booleano e identificador.
- `_numberKind(String lex)` decide entre `int` e `double` com base na presença de `.` ou `e`/`E`.

6. Tratamento de erros e recuperação
- Todos os pontos de falha possíveis (token esperado não encontrado) criam um `ParseError` e chamam `_synchronize()` quando apropriado.
- `ParseError` contém `mensagem`, `linha`, `coluna` e `contexto` (trecho de código) — o `contexto` é obtido via `extractLineContext(src, linha)` quando `src` é fornecido ao parser.
- Estratégia de sincronização (`_synchronize()`):
  - Avança tokens até encontrar um ponto de sincronização natural: um ponto-e-vírgula (`;`) — assume que é fim do statement; consome esse `;` e retorna.
  - Ou encontra uma palavra-reservada (tipo ou keywords como `if`, `while`, `uids`, etc.) e então retorna sem consumir — permitindo que o laço externo reavalie o token no contexto correto.
  - Caso contrário, consome tokens até o final (EOF).
- Racional: permite continuar parseando o restante do arquivo e coletar múltiplos erros em vez de abortar no primeiro.

7. Convenções de sinalização de erro
- Várias funções retornam null para indicar que o node sintático não pôde ser construído (ex.: `parseCommand()` retorna `null` em caso de vazio ou erro recuperável). O `parseProgram()` ignora `null` e continua.
- `ParseError` distingue erros de sintaxe localizados; lógicas semânticas (tipo, uso de variável) ficam a cargo do `SemanticAnalyzer`.

8. Pontos de melhoria sugeridos
- Mais pontos de sincronização: além de `;` e palavras-reservadas, considerar `}` como ponto natural de recuperação (já tratado por `parseBlock`), ou tokens de início de statement adicionais.
- Mensagens mais ricas: incluir fragmentos de código com marcação (colchetes) em torno do token problemático para facilitar leitura.
- Reparo mínimo automático: em alguns casos, inserir tokens virtuais (ex.: assumir `;` quando ausente) permite parsear mais estrutura útil; isso deve ser usado com cautela.
- Testes de recuperação: adicionar casos que intencionalmente quebrem o código para verificar que o parser continua e registra erros esperados.

9. Onde procurar no código
- Implementação principal: `lib/parser.dart`.
- Erros/estrutura de erro: `lib/parse_error.dart` (modelo `ParseError`).
- Utilitários de contexto de erro: `lib/error_context.dart` (função `extractLineContext`).

10. Exemplos de mensagens de erro geradas
- `Esperado tipo de declaração, encontrado <token>` — quando não há palavra-reservada de tipo ao iniciar uma declaração.
- `Esperado identificador após tipo "uids" mas encontrado <TOKEN> "lexema"` — erro amigável com posição.
- `Esperado ";" após declaração na linha X, coluna Y` — erro por falta de terminador.
- `Token inesperado no início de comando: <lexema>` — token inválido ao começar um statement.
- `Parêntese ")" esperado na linha X, coluna Y` — erro de expressão entre parênteses.

11. Testes recomendados (para alinhar parser e docs)
- Casos positivos: programas com declarações, blocos aninhados, if/else curto e com bloco, while com bloco.
- Casos negativos e de recuperação: falta `;`, parênteses não fechados, declaração com tipo mas sem identificador, tokens inesperados no início de comando.

Se quiser, gero automaticamente exemplos de input/AST para cada item acima, assim como um conjunto de testes unitários que comprovem o comportamento de recuperação de erros do parser.
