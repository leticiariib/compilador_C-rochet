%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern char* yytext;
void yyerror(const char *msg);
extern FILE *token_file;
extern FILE *yyin;

/* TABELA SIMBOLOS */
char nomes_vars[200][50];
double valores_vars[200];
int total_vars = 0;

int obter_indice_var(char *nome) {
    for (int i = 0; i < total_vars; i++) {
        if (strcmp(nomes_vars[i], nome) == 0) return i;
    }
    strcpy(nomes_vars[total_vars], nome);
    valores_vars[total_vars] = 0.0;
    total_vars++;
    return total_vars - 1;
}

/* TIPOS DE NOS DA AST */
typedef enum {
    No_NUM,
    No_ID,
    No_STR,
    No_OP_BINARIA,
    No_ATRIBUICAO,
    No_ENTRADA,   /* pescar */
    No_SAIDA,     /* bordar */
    No_SE,
    No_ENQUANTO,  /* carreira */
    No_PARA,      /* volta */
    No_SWITCH,    /* escolherfio */
    No_CASO,      /* ponto */
    No_SEQ
} NoTipo;

typedef struct ASTNo {
    NoTipo tipo;
    double valor;
    char id[50];
    char str_val[256];
    int operador;
    struct ASTNo *esq;
    struct ASTNo *dir;
    struct ASTNo *cond;
    struct ASTNo *corpo;
    struct ASTNo *senao;
    struct ASTNo *proximo;
} ASTNo;

/* CONSTRUTORES */
ASTNo* novo_no_num(double val) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_NUM; no->valor = val;
    return no;
}
ASTNo* novo_no_id(char* nome) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_ID; strcpy(no->id, nome);
    return no;
}
ASTNo* novo_no_str(char* texto) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_STR; strcpy(no->str_val, texto);
    return no;
}
ASTNo* novo_no_op(int op, ASTNo* esq, ASTNo* dir) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_OP_BINARIA; no->operador = op;
    no->esq = esq; no->dir = dir;
    return no;
}
ASTNo* novo_no_atribuicao(char* nome, ASTNo* dir) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_ATRIBUICAO; strcpy(no->id, nome); no->dir = dir;
    return no;
}
ASTNo* novo_no_entrada(char* nome) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_ENTRADA; strcpy(no->id, nome);
    return no;
}
ASTNo* novo_no_saida(ASTNo* lista) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_SAIDA; no->esq = lista;
    return no;
}
ASTNo* novo_no_se(ASTNo* cond, ASTNo* corpo, ASTNo* senao) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_SE; no->cond = cond; no->corpo = corpo; no->senao = senao;
    return no;
}
ASTNo* novo_no_enquanto(ASTNo* cond, ASTNo* corpo) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_ENQUANTO; no->cond = cond; no->corpo = corpo;
    return no;
}
ASTNo* novo_no_para(ASTNo* init, ASTNo* cond, ASTNo* passo, ASTNo* corpo) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_PARA;
    no->esq = init; no->cond = cond; no->dir = passo; no->corpo = corpo;
    return no;
}
ASTNo* novo_no_switch(char* nome, ASTNo* casos) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_SWITCH; strcpy(no->id, nome); no->esq = casos;
    return no;
}
ASTNo* novo_no_caso(ASTNo* valor, ASTNo* corpo) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_CASO; no->cond = valor; no->corpo = corpo;
    return no;
}
ASTNo* novo_no_seq(ASTNo* cmd1, ASTNo* cmd2) {
    ASTNo* no = (ASTNo*)malloc(sizeof(ASTNo));
    memset(no, 0, sizeof(ASTNo));
    no->tipo = No_SEQ; no->esq = cmd1; no->proximo = cmd2;
    return no;
}

/* EXECUCAO DA AST*/
int flag_arrematar = 0;

void executar_saida(ASTNo* no);
double executar_arvore(ASTNo* no);

/* Percorre recursivamente a lista de casos do switch e executa o que bater */
int buscar_e_executar_caso(ASTNo* no, double val) {
    if (no == NULL) return 0;
    if (no->tipo == No_CASO) {
        if (executar_arvore(no->cond) == val) {
            flag_arrematar = 0;
            executar_arvore(no->corpo);
            flag_arrematar = 0;
            return 1;
        }
        return 0;
    }
    if (no->tipo == No_SEQ) {
        if (buscar_e_executar_caso(no->esq, val)) return 1;
        if (buscar_e_executar_caso(no->proximo, val)) return 1;
    }
    return 0;
}

void executar_saida(ASTNo* no) {
    if (no == NULL) return;
    if (no->tipo == No_SEQ) {
        executar_saida(no->esq);
        executar_saida(no->proximo);
    } else if (no->tipo == No_STR) {
        /* Remove aspas do literal string */
        char tmp[256];
        strcpy(tmp, no->str_val);
        int len = strlen(tmp);
        if (len >= 2 && tmp[0] == '"') {
            tmp[len-1] = '\0';
            printf("%s", tmp+1);
        } else {
            printf("%s", tmp);
        }
    } else {
        double val = executar_arvore(no);
        /* Imprime inteiro se nao tiver parte fracionaria */
        if (val == (long long)val)
            printf("%lld", (long long)val);
        else
            printf("%g", val);
    }
}

double executar_arvore(ASTNo* no) {
    if (no == NULL) return 0;

    switch (no->tipo) {
        case No_NUM:
            return no->valor;

        case No_STR:
            return 0;

        case No_ID:
            return valores_vars[obter_indice_var(no->id)];

        case No_SEQ:
            executar_arvore(no->esq);
            if (!flag_arrematar)
                executar_arvore(no->proximo);
            return 0;

        case No_ATRIBUICAO: {
            double val = executar_arvore(no->dir);
            valores_vars[obter_indice_var(no->id)] = val;
            return val;
        }

        case No_ENTRADA: {
            double entrada;
            printf("Entrada para '%s': ", no->id);
            if (scanf("%lf", &entrada) != 1) entrada = 0;
            valores_vars[obter_indice_var(no->id)] = entrada;
            return entrada;
        }

        case No_SAIDA:
            executar_saida(no->esq);
            printf("\n");
            return 0;

        case No_SE:
            if (executar_arvore(no->cond) != 0)
                executar_arvore(no->corpo);
            else if (no->senao != NULL)
                executar_arvore(no->senao);
            return 0;

        case No_ENQUANTO:
            while (executar_arvore(no->cond) != 0)
                executar_arvore(no->corpo);
            return 0;

        case No_PARA:
            for (executar_arvore(no->esq);
                 executar_arvore(no->cond) != 0;
                 executar_arvore(no->dir)) {
                executar_arvore(no->corpo);
            }
            return 0;

        case No_SWITCH: {
            double var_val = valores_vars[obter_indice_var(no->id)];
            buscar_e_executar_caso(no->esq, var_val);
            return 0;
        }

        case No_CASO:
            /* Executado dentro do SWITCH acima */
            return 0;

        case No_OP_BINARIA: {
            double esq = executar_arvore(no->esq);
            double dir = executar_arvore(no->dir);
            switch (no->operador) {
                case '+': return esq + dir;
                case '-': return esq - dir;
                case '*': return esq * dir;
                case '/': return dir == 0 ? 0 : esq / dir;
                case '%': return dir == 0 ? 0 : (double)((long long)esq % (long long)dir);
                case '>': return esq > dir;
                case '<': return esq < dir;
                case 1:   return esq == dir; /* T_IGUAL */
                case 2:   return esq != dir; /* T_DIF   */
                case 3:   return esq >= dir; /* T_MAIG  */
                case 4:   return esq <= dir; /* T_MEIG  */
                case '&': return esq && dir; /* T_JUNTO */
                case '|': return esq || dir; /* T_OU    */
            }
        }
    }
    return 0;
}
%}

%union {
    double valor_num;
    char   nome_id[50];
    char   str_val[256];
    struct ASTNo* no_ast;
    int    op_val;
}

%token <valor_num> T_NUM
%token <nome_id>   T_ID
%token <str_val>   T_BORDADO

%token T_FIO T_BARBANTE T_LINHA
%token T_PESCAR T_BORDAR
%token T_MEDIR T_AVESSO
%token T_VOLTA T_CARREIRA
%token T_ESCOLHERFIO T_PONTO T_ARREMATAR
%token T_CORRENTINHA T_CORTARFIO
%token T_IGUAL T_DIF T_MAIOR T_MENOR T_MAIG T_MEIG
%token T_JUNTO T_OU T_INVERTE
%token T_LACADA T_DESMANCHA T_MULT T_DIV T_RESTO
%token T_RECEBE
%token T_ABREPAR T_FECHAPAR T_PVIRGULA T_VIRGULA T_AGULHA

%type <no_ast> programa comandos comando bloco
%type <no_ast> dec_variavel op_atribuicao exp_atribuicao
%type <no_ast> comando_entrada comando_saida saida_args saida_item
%type <no_ast> condicional condicao op_relacional op_logica
%type <no_ast> repeticao_for repeticao_while
%type <no_ast> switch casos caso
%type <no_ast> op_aritmetica caractere
%type <op_val> relacional logico aritmetico

%%

programa
    : comandos
        {
            executar_arvore($1);
        }
    ;

comandos
    : comando
        { $$ = $1; }
    | comandos comando
        { $$ = novo_no_seq($1, $2); }
    ;

comando
    : dec_variavel   { $$ = $1; }
    | op_atribuicao  { $$ = $1; }
    | comando_entrada{ $$ = $1; }
    | comando_saida  { $$ = $1; }
    | condicional    { $$ = $1; }
    | repeticao_for  { $$ = $1; }
    | repeticao_while{ $$ = $1; }
    | switch         { $$ = $1; }
    ;

tipo
    : T_FIO
    | T_BARBANTE
    | T_LINHA
    ;

dec_variavel
    : tipo T_ID T_PVIRGULA
        { $$ = novo_no_atribuicao($2, novo_no_num(0)); }
    | tipo T_ID T_RECEBE op_aritmetica T_PVIRGULA
        { $$ = novo_no_atribuicao($2, $4); }
    | tipo T_ID T_RECEBE T_BORDADO T_PVIRGULA
        { $$ = novo_no_atribuicao($2, novo_no_str($4)); }
    ;

exp_atribuicao
    : T_ID T_RECEBE op_aritmetica
        { $$ = novo_no_atribuicao($1, $3); }
    | T_ID T_RECEBE T_BORDADO
        { $$ = novo_no_atribuicao($1, novo_no_str($3)); }
    ;

op_atribuicao
    : exp_atribuicao T_PVIRGULA
        { $$ = $1; }
    ;

op_aritmetica
    : caractere
        { $$ = $1; }
    | op_aritmetica aritmetico caractere
        { $$ = novo_no_op($2, $1, $3); }
    | T_ABREPAR op_aritmetica T_FECHAPAR
        { $$ = $2; }
    ;

caractere
    : T_ID  { $$ = novo_no_id($1); }
    | T_NUM { $$ = novo_no_num($1); }
    ;

aritmetico
    : T_LACADA   { $$ = '+'; }
    | T_DESMANCHA{ $$ = '-'; }
    | T_MULT     { $$ = '*'; }
    | T_DIV      { $$ = '/'; }
    | T_RESTO    { $$ = '%'; }
    ;

comando_entrada
    : T_PESCAR T_ABREPAR T_ID T_FECHAPAR T_PVIRGULA
        { $$ = novo_no_entrada($3); }
    ;

comando_saida
    : T_BORDAR T_ABREPAR saida_args T_FECHAPAR T_PVIRGULA
        { $$ = novo_no_saida($3); }
    ;

saida_args
    : saida_item
        { $$ = $1; }
    | saida_args T_VIRGULA saida_item
        { $$ = novo_no_seq($1, $3); }
    ;

saida_item
    : T_BORDADO  { $$ = novo_no_str($1); }
    | T_ID       { $$ = novo_no_id($1); }
    | T_NUM      { $$ = novo_no_num($1); }
    ;

relacional
    : T_IGUAL { $$ = 1; }
    | T_DIF   { $$ = 2; }
    | T_MAIG  { $$ = 3; }
    | T_MEIG  { $$ = 4; }
    | T_MAIOR { $$ = '>'; }
    | T_MENOR { $$ = '<'; }
    ;

logico
    : T_JUNTO { $$ = '&'; }
    | T_OU    { $$ = '|'; }
    ;

op_relacional
    : caractere relacional caractere
        { $$ = novo_no_op($2, $1, $3); }
    ;

op_logica
    : op_relacional logico op_relacional
        { $$ = novo_no_op($2, $1, $3); }
    | T_INVERTE op_relacional
        { $$ = novo_no_op('!', novo_no_num(0), $2); }
    ;

condicao
    : op_logica    { $$ = $1; }
    | op_relacional{ $$ = $1; }
    ;

bloco
    : T_CORRENTINHA comandos T_CORTARFIO
        { $$ = $2; }
    ;

condicional
    : T_MEDIR T_ABREPAR condicao T_FECHAPAR bloco
        { $$ = novo_no_se($3, $5, NULL); }
    | T_MEDIR T_ABREPAR condicao T_FECHAPAR bloco T_AVESSO bloco
        { $$ = novo_no_se($3, $5, $7); }
    | T_MEDIR T_ABREPAR condicao T_FECHAPAR bloco T_AVESSO condicional
        { $$ = novo_no_se($3, $5, $7); }
    ;

repeticao_for
    : T_VOLTA T_ABREPAR exp_atribuicao T_PVIRGULA condicao T_PVIRGULA exp_atribuicao T_FECHAPAR bloco
        { $$ = novo_no_para($3, $5, $7, $9); }
    ;

repeticao_while
    : T_CARREIRA T_ABREPAR condicao T_FECHAPAR bloco
        { $$ = novo_no_enquanto($3, $5); }
    ;

switch
    : T_ESCOLHERFIO T_ABREPAR T_ID T_FECHAPAR T_CORRENTINHA casos T_CORTARFIO
        { $$ = novo_no_switch($3, $6); }
    ;

casos
    : caso
        { $$ = $1; }
    | casos caso
        { $$ = novo_no_seq($1, $2); }
    ;

caso
    : T_PONTO T_NUM T_AGULHA comandos T_ARREMATAR T_PVIRGULA
        { $$ = novo_no_caso(novo_no_num($2), $4); }
    ;

%%

void yyerror(const char *msg) {
    fprintf(stderr, "Erro sintatico perto de '%s': %s\n", yytext, msg);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Uso: %s <arquivo_fonte>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Erro ao abrir arquivo de entrada");
        return 1;
    }

    char nome_saida[512];
    snprintf(nome_saida, sizeof(nome_saida), "%s.tokens", argv[1]);
    token_file = fopen(nome_saida, "w");
    if (!token_file) {
        perror("Erro ao criar log de tokens");
        fclose(yyin);
        return 1;
    }

    int status = yyparse();

    fclose(yyin);
    fclose(token_file);

    if (status != 0)
        fprintf(stderr, "Falha na analise sintatica\n");

    return status;
}
