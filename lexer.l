%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

FILE *token_file;

void salva_token(const char *lexema, const char *tipo) {
    if (token_file)
        fprintf(token_file, "%-20s : %s\n", lexema, tipo);
}
%}

%option noyywrap

LETRA       [a-zA-Z]
DIGITO      [0-9]
DIGITO_NZ   [1-9]
ID          {LETRA}({LETRA}|{DIGITO}|"_")*
NUM         ("0"|{DIGITO_NZ}{DIGITO}*)("."{DIGITO}+)?
BORDADO     \"([^\"\\]|\\.)*\"
ESPACO      [ \t\r\n]+
COM_LINHA   "//"[^\r\n]*
COM_BLOCO   "/*"([^*]|\*+[^*/])*\*+"/"

%%

{ESPACO}        { /* ignora */ }
{COM_LINHA}     { salva_token(yytext, "comentario de linha"); }
{COM_BLOCO}     { salva_token(yytext, "comentario de bloco"); }

"fio"           { salva_token(yytext, "tipo inteiro"); return T_FIO; }
"barbante"      { salva_token(yytext, "tipo real"); return T_BARBANTE; }
"linha"         { salva_token(yytext, "tipo caractere"); return T_LINHA; }

"pescar"        { salva_token(yytext, "comando de entrada"); return T_PESCAR; }
"bordar"        { salva_token(yytext, "comando de saida"); return T_BORDAR; }

"medir"         { salva_token(yytext, "comando condicional"); return T_MEDIR; }
"avesso"        { salva_token(yytext, "comando condicional else"); return T_AVESSO; }
"volta"         { salva_token(yytext, "comando de repeticao for"); return T_VOLTA; }
"carreira"      { salva_token(yytext, "comando de repeticao while"); return T_CARREIRA; }
"escolherfio"   { salva_token(yytext, "comando de selecao"); return T_ESCOLHERFIO; }
"ponto"         { salva_token(yytext, "caso da selecao"); return T_PONTO; }
"arrematar"     { salva_token(yytext, "break"); return T_ARREMATAR; }

"correntinha"   { salva_token(yytext, "delimitador - abre bloco"); return T_CORRENTINHA; }
"cortarfio"     { salva_token(yytext, "delimitador - fecha bloco"); return T_CORTARFIO; }

"=="            { salva_token(yytext, "op relacional - igual"); return T_IGUAL; }
"!="            { salva_token(yytext, "op relacional - diferente"); return T_DIF; }
">="            { salva_token(yytext, "op relacional - maior ou igual"); return T_MAIG; }
"<="            { salva_token(yytext, "op relacional - menor ou igual"); return T_MEIG; }
">"             { salva_token(yytext, "op relacional - maior"); return T_MAIOR; }
"<"             { salva_token(yytext, "op relacional - menor"); return T_MENOR; }

"&&"            { salva_token(yytext, "op logico - e"); return T_JUNTO; }
"||"            { salva_token(yytext, "op logico - ou"); return T_OU; }
"!"             { salva_token(yytext, "op logico - nao"); return T_INVERTE; }

"+"             { salva_token(yytext, "op aritmetico - adicao"); return T_LACADA; }
"-"             { salva_token(yytext, "op aritmetico - subtracao"); return T_DESMANCHA; }
"*"             { salva_token(yytext, "op aritmetico - multiplicacao"); return T_MULT; }
"/"             { salva_token(yytext, "op aritmetico - divisao"); return T_DIV; }
"%"             { salva_token(yytext, "op aritmetico - resto"); return T_RESTO; }

"="             { salva_token(yytext, "op de atribuicao"); return T_RECEBE; }

"("             { salva_token(yytext, "delimitador - abre parentese"); return T_ABREPAR; }
")"             { salva_token(yytext, "delimitador - fecha parentese"); return T_FECHAPAR; }
";"             { salva_token(yytext, "delimitador - ponto e virgula"); return T_PVIRGULA; }
","             { salva_token(yytext, "delimitador - virgula"); return T_VIRGULA; }
"=>"            { salva_token(yytext, "simbolo especial - agulha"); return T_AGULHA; }

{BORDADO}       {
    salva_token(yytext, "literal de texto - bordado");
    strncpy(yylval.str_val, yytext, sizeof(yylval.str_val) - 1);
    yylval.str_val[sizeof(yylval.str_val) - 1] = '\0';
    return T_BORDADO;
}

{NUM}           {
    salva_token(yytext, "literal numerico");
    yylval.valor_num = atof(yytext);
    return T_NUM;
}

{ID}            {
    salva_token(yytext, "identificador");
    strncpy(yylval.nome_id, yytext, sizeof(yylval.nome_id) - 1);
    yylval.nome_id[sizeof(yylval.nome_id) - 1] = '\0';
    return T_ID;
}

.               { fprintf(stderr, "Erro lexico: caractere '%s' invalido\n", yytext); }

%%
