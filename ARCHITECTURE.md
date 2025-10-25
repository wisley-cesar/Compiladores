# 🏗️ Arquitetura do Compilador

## 📋 Visão Geral

O compilador foi projetado seguindo o princípio de **Separação de Responsabilidades**, dividindo o lexer em módulos especializados para melhor manutenibilidade e extensibilidade.

## 🔧 Módulos Principais

### 1. **Lexer** (Orquestrador Principal)
- **Responsabilidade**: Coordena todos os módulos e implementa o AFD
- **Arquivo**: `lib/lexer.dart`
- **Funcionalidades**:
  - Gerencia o fluxo de análise léxica
  - Coordena os módulos especializados
  - Implementa o autômato finito determinístico
  - Mantém estado global (posição, linha, coluna)

### 2. **TokenRecognizer** (Reconhecimento de Tokens)
- **Responsabilidade**: Reconhece tokens específicos
- **Arquivo**: `lib/token_recognizer.dart`
- **Funcionalidades**:
  - Strings literais com escape sequences
  - Números (inteiros, decimais, notação científica)
  - Identificadores e palavras reservadas
  - Operadores e símbolos
  - Comentários (linha e bloco)

### 3. **AmbiguityDetector** (Detecção de Ambiguidades)
- **Responsabilidade**: Detecta ambiguidades sintáticas
- **Arquivo**: `lib/ambiguity_detector.dart`
- **Funcionalidades**:
  - Parênteses extras consecutivos
  - Chaves extras consecutivas
  - Colchetes extras consecutivos
  - Ponto e vírgula duplo
  - Padrões problemáticos específicos

### 4. **ErrorHandler** (Tratamento de Erros)
- **Responsabilidade**: Gerencia erros léxicos
- **Arquivo**: `lib/error_handler.dart`
- **Funcionalidades**:
  - Coleta e organiza erros léxicos
  - Fornece estatísticas de erros
  - Mantém lista de erros para relatórios

### 5. **Statistics** (Estatísticas e Relatórios)
- **Responsabilidade**: Gera estatísticas e relatórios
- **Arquivo**: `lib/statistics.dart`
- **Funcionalidades**:
  - Contadores de tokens por tipo
  - Percentuais de distribuição
  - Relatórios detalhados
  - Métricas de análise

## 🔄 Fluxo de Execução

```
Código Fonte
     ↓
   Lexer
     ↓
┌─────────────────────────────────────┐
│  TokenRecognizer  │  AmbiguityDetector │
│  - Strings        │  - Parênteses      │
│  - Números        │  - Chaves          │
│  - Identificadores│  - Colchetes       │
│  - Operadores     │  - Ponto e vírgula │
│  - Comentários    │  - Padrões         │
└─────────────────────────────────────┘
     ↓
  ErrorHandler
     ↓
  Statistics
     ↓
  Relatório Final
```

## 📊 Vantagens da Arquitetura Modular

### ✅ **Manutenibilidade**
- Cada módulo tem responsabilidade única
- Fácil localização e correção de bugs
- Modificações isoladas por módulo

### ✅ **Extensibilidade**
- Novos tipos de tokens podem ser adicionados ao `TokenRecognizer`
- Novas detecções de ambiguidade no `AmbiguityDetector`
- Novos tipos de relatórios no `Statistics`

### ✅ **Testabilidade**
- Cada módulo pode ser testado independentemente
- Mocks e stubs mais fáceis de implementar
- Testes mais focados e específicos

### ✅ **Reutilização**
- Módulos podem ser reutilizados em outros projetos
- `ErrorHandler` pode ser usado em outras fases do compilador
- `Statistics` pode ser usado para análise de código

## 🚀 Próximos Passos

1. **Parser**: Implementar analisador sintático
2. **Semantic Analyzer**: Implementar análise semântica
3. **Code Generator**: Implementar geração de código
4. **Optimizer**: Implementar otimizações

## 📝 Padrões de Design Utilizados

- **Single Responsibility Principle**: Cada classe tem uma responsabilidade
- **Dependency Injection**: Módulos são injetados no Lexer
- **Strategy Pattern**: Diferentes estratégias de reconhecimento
- **Observer Pattern**: Detecção de ambiguidades observa tokens
- **Factory Pattern**: Criação de tokens e estatísticas
