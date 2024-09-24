%{
#include "expTree.tab.h"
#include <stdlib.h>
%}

%%
[a-zA-Z][a-zA-Z0-9_]*   { yylval.opr=strdup(yytext); return VAR;}
[0-9]+   { yylval.opr= strdup(yytext); return NUMBER;}
[+\-*/()=] { return yytext[0]; }
\n        { return '\n'; }
[ \t]+    {}
[\r]+	  {}
. { printf("Mystery character %s\n", yytext); }
%%

int yywrap() {
    return 1;
}

