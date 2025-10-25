/// Definições léxicas compartilhadas: operadores, símbolos e palavras reservadas

const Set<String> OPERADORES = {
  '+', '-', '*', '/', '%', '=', '==', '!=', '<', '>', '<=', '>=',
  '&&', '||', '!', '++', '--', '+=', '-=', '*=', '/=',
  '&', '|', '^', '~', '<<', '>>', '>>>', '>>=', '<<=', '=>'
};

const Set<String> SIMBOLOS = {
  '(', ')', '{', '}', '[', ']', ';', ',', '.', ':', '?', '->'
};

const Set<String> PALAVRAS_RESERVADAS = {
  'if', 'else', 'while', 'for', 'do', 'break', 'continue',
  'int', 'float', 'double', 'string', 'bool', 'char',
  'return', 'void', 'main', 'true', 'false', 'null',
  'class', 'public', 'private', 'static', 'final',
  'import', 'package', 'new', 'this', 'super'
  , 'uids'
};
