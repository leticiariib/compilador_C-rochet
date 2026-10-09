# C-rochet

## Sobre a Linguagem
C-rochet é uma linguagem de programação didática baseada na sintaxe da linguagem C, com vocabulário temático do universo do crochê. Por exemplo:
- `fio` equivale a `int`
- `medir` equivale a `if`
- `carreira` equivale a `while`
- `volta` equivale a `for`
- `correntinha` equivale a `{` e `cortarfio` equivale a `}`

Mais detalhes: https://docs.google.com/document/d/1zvvzbgBkcYU7ZZjI4PZfLO1y2hMLUgkt2_dFNlCePeM/edit?usp=sharing 

## Pré-requisitos
- WSL (Windows Subsystem for Linux) com Ubuntu, ou Linux
- flex, bison e gcc instalados

Para instalar no Ubuntu/WSL:
sudo apt update
sudo apt install flex bison gcc -y

## Compilação
Na pasta do projeto, executar os comandos na ordem:
flex lexer.l
bison -d parser.y
gcc lex.yy.c parser.tab.c -o crochet -lfl

## Execução
./crochet exemplo1.crt
./crochet exemplo2.crt
./crochet exemplo3.crt

Ao executar, o programa:
1. Analisa léxica e sintaticamente o arquivo `.crt`
2. Gera automaticamente um arquivo `.crt.tokens` com o reconhecimento de todos os tokens

## Programas Exemplo
- Exemplo 1: entrada e saída (calcula média de duas notas)
- Exemplo 2: condicional (verifica se número é positivo/negativo/zero)
- Exemplo 3: repetição — soma os números de 1 a 5 com for 

## Estrutura dos Arquivos
```text 
crochet/
├── lexer.l ← Analisador Léxico 
├── parser.y ← Analisador Sintático 
├── exemplo1.crt ← entrada/saída
├── exemplo2.crt ← condicional
├── exemplo3.crt ← repetição
└── README.md ← esse arquivo

Os arquivos gerados pela compilação (`lex.yy.c`, `parser.tab.c`, `parser.tab.h`, `crochet`) são criados automaticamente e não precisam ser editados 

