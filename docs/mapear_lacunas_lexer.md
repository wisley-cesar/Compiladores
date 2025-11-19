# Mapeamento de Lacunas — Lexer

Objetivo: documentar o que já existe no lexer do projeto e apontar o que falta para cumprir todos os requisitos do trabalho (técnicos e conceituais). O documento também propõe testes e patches prioritários.

## 1. O que já existe
- Entrada: `Lexer(codigo)` e `Lexer.fromFile(path)` — aceita string e arquivo.
- Tokens reconhecidos (via `TokenRecognizer`):
  - Palavras reservadas (conforme `lib/lexical_definitions.dart`).
  - Identificadores (ASCII: `[a-zA-Z_]` seguido de `[a-zA-Z0-9_]`).
  - Literais numéricos: inteiros, decimais e notação científica básica (`e/E`), com validação de expoente.
  - Strings entre aspas duplas com escapes básicos (`\n`, `\"`, `\\`), detecta string não fechada.
  - Booleanos `true`/`false` são reconhecidos.
  - Operadores e símbolos (suporta 1,2 e 3 caracteres; prioriza maior primeiro).
  - Comentários: linha (`//`) e bloco (`/* ... */`) — o lexer ignora comentários (não emite token).
- Posição: cada `Token` tem `linha` e `coluna` e `toJson()`.
- Erros léxicos: são registrados via `ErrorHandler` como `LexError(mensagem, linha, coluna, contexto)` e deduplicados.
- Saída: `Lexer.analisar()` retorna `List<Token>` e adiciona `TokenType.eof`.

## 2. Lacunas identificadas (o que falta)
1. Documentação AFD/Teoria
   - Falta arquivo que explique o AFD (ou a estratégia) usado para cada token e a prioridade (greedy matching). O código é manual, mas é necessário justificar/explicar a abordagem.

2. Testes unitários do lexer
   - Não há testes exclusivos e focados no lexer cobrindo casos-limite (strings não fechadas, números malformatados, `.5`, `5.`, expoente inválido, comentários sem fechar, tokens multi-char, posição correta, etc.).

3. Formato numérico ambíguo
   - `lerNumero()` não aceita literais que comecem com ponto como `.5` (behaviour não documentada). Decidir se aceita e implementar.

4. Suporte Unicode em identificadores
   - Atualmente `_isLetterOrDigit` usa `[a-zA-Z0-9_]` — limita a ASCII. Se quiser suporte a identificadores Unicode (letras acentuadas), regex precisa ser atualizada.

5. Comentários como tokens (opcional)
   - `TokenType.comentario` existe no enum, mas o lexer ignora os comentários. Escolher: manter ignorados (padrão) ou implementar opção `collectComments` para emiti-los como tokens.

6. Mensagens de erro mais granulares
   - Erros atuais cobrem grandes causas; porém seria útil distinguir mensagens para: "escape inválido", "caractere Unicode inválido", "underscore em número" etc., conforme escopo do curso.

7. CLI/artefatos de saída
   - O projeto já tem opções de dump (conforme resumo), porém falta opção explícita `--tokens-out <file>` para gravar tokens JSON e facilitar geração de slides/entrega.

8. AFD formal / diagrama
   - Ausência de diagrama/tabela de transições que represente o AFD global (útil para relatório e defesa do método).

9. Robustez em comentários de bloco
   - `ignorarComentarioBloco()` detecta fechamento mas não reporta posição final nem atualiza contexto detalhado em alguns cenários; precisa de testes para confirmar comportamento em EOF e em strings dentro de block comments.

10. Índice absoluto (opcional)
   - Tokens têm linha/coluna, mas não índice absoluto (`posIndex`) — adicionar pode facilitar mapeamento entre token e `codigo`.

## 3. Recomendações e mudanças práticas (priorizadas)
### Prioridade Alta
- (A) Criar testes unitários `test/lexer_test.dart` com os seguintes casos:
  1. Sequência simples com cada tipo de token (palavras-reservadas, identificador, número, string, operador, símbolo) e assert do `toJson()` (tipo, lexema, linha, coluna).
  2. String não fechada (esperar `LexError` com mensagem adequada e `contexto`).
  3. Comentário de bloco não fechado (esperar `LexError`).
  4. Número com expoente inválido (`1.2e+`) — esperar `LexError`.
  5. Token multi-char (`==`, `!=`, `<=`, `>=`, `&&`, `||`) reconhecidos corretamente.
  6. Posições (linha/coluna) corretas ao combinar quebras de linha e tokens.

- (B) Adicionar documentação mínima no `README.md` com exemplo de input → saída JSON de tokens.

### Prioridade Média
- (C) Definir política para literais com ponto inicial `.5` e implementar ajuste em `TokenRecognizer.lerNumero()` se optar por suportar.
- (D) Adicionar opção CLI `--tokens-out <file>` para gravar JSON dos tokens (ou `--write-output-dir`).
- (E) Adicionar `posIndex` ao `Token` (opcional) para mapear posição absoluta.

### Prioridade Baixa
- (F) Suporte Unicode em identificadores (alterar regex) — aplicar se necessário para o escopo do curso.
- (G) Implementar `collectComments` para emitir tokens `TokenType.comentario` quando desejado.
- (H) Criar `docs/afd_lexer.md` com diagrama/tabela do AFD.

## 4. Patches sugeridos (esboço)
- Token: adicionar campo `pos` (índice absoluto)
  - Arquivo: `lib/token.dart`
  - Mudança: Token(this.tipo, this.lexema, this.linha, this.coluna, [this.pos]); incluir `toJson` com `pos`.

- TokenRecognizer.lerNumero(): aceitar `.5` (opcional)
  - Verificar lookbehind/ lookahead para suportar ponto inicial; implementar branch que, se `codigo[pos] == '.'` e próximo for dígito, tratar como número.

- CLI: `bin/main.dart` — adicionar parsing de flag `--tokens-out path` e escrever `jsonEncode(tokens.map((t) => t.toJson()).toList())`.

- Tests: criar `test/lexer_test.dart` com harness que chama `Lexer(codigo).analisar()` e checa `listaErrosEstruturados` e `tokens`.

## 5. Casos de teste (sugestões concretas)
1) Tokens básicos
```txt
uids x = 42;
if (x > 0) x = x - 1;
```
- tokens: `uids`, `identificador(x)`, `=`, `numero(42)`, `;`, `if`, `(`, `ident(x)`, `>`, `numero(0)`, `)`, `ident(x)`, `=`, `ident(x)`, `-`, `numero(1)`, `;`

2) String não fechada
```txt
string s = "Olá mundo
```
- espera `LexError` "String não fechada" com `linha`/`coluna` do início da string.

3) Número com expoente inválido
```txt
x = 1.2e+
```
- espera `LexError` "Expoente inválido em número".

4) Comentário bloco sem fechar
```txt
/* comentário
x = 1;
```
- espera `LexError` "Comentário de bloco não fechado".

5) Número com ponto inicial (decidir política)
```txt
x = .5;
```
- se suportar, token `numero` com lexema `.5`; se não, reportar `ERRO LÉXICO` ou token `simbolo '.'` seguido de `numero`.

## 6. Plano de execução imediato (o que eu faço agora)
1. Criar este arquivo `docs/mapear_lacunas_lexer.md` (feito).
2. Se você concordar: implementar os testes unitários `test/lexer_test.dart` (prioridade alta).
3. Em seguida resolver um ajuste rápido (por exemplo, aceitar `.5`) se desejado.

## 7. Perguntas (decisões que você precisa tomar)
- Quer que o lexer suporte literais com ponto inicial (`.5`)? (s/n)
- Deseja suportar identificadores com caracteres Unicode (letras acentuadas)? (s/n)
- Quer que comentários possam ser coletados como tokens (útil para documentação/extração)? (s/n)

---

Se você confirmar as decisões acima (ou indicar preferências), eu começo implementando os testes `test/lexer_test.dart` e executo `dart test` aqui na branch `sintatica`. Se preferir, posso começar implementando primeiro a opção CLI `--tokens-out`.