%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
extern FILE *yyin;
typedef struct Node {
    unsigned char *op;            
    struct Node *left;  
    struct Node *right; 
    char *opr;       
} Node;
	
Node *createNode( char *op, Node *left, Node *right, char *opr);
int eval(Node *root);
void inorderTraversal(Node *root);
void yyerror(const char *s);
int yylex();
%}

%union {
   char *opr;
    struct Node *node;
}
//%token '(' ')'
%token <opr> NUMBER
%token<opr>VAR
%left '+' '-'
%left '*' '/'
%right '='
%type <node> expr term factor program

%%

program:
	 program expr '\n' { printf("Inorder Traversal:");  inorderTraversal($2); 				 printf("\n"); }
  | expr '\n' {  printf("Inorder Traversal:");  inorderTraversal($1);printf("\n");}
  | '\n' {  }
      | expr  { //printf("Result: %d\n", eval($1)); 
              printf("Inorder Traversal:");  inorderTraversal($1); }
       ;
expr:
    expr '=' term { $$ = createNode("assign",$1,$3,NULL); }
  | expr '+' term { $$ = createNode("plus", $1, $3,NULL); }
  | expr '-' term { $$ = createNode("minus", $1, $3,NULL); }
  | term          { $$ = $1; }
  ;

term:
    term '*' factor { $$ = createNode("mul", $1, $3,NULL); }
  | term '/' factor { $$ = createNode("div", $1, $3,NULL); }
  | factor          { $$ = $1; }
  ;

factor:
      NUMBER {	char *n = malloc(strlen("num") + strlen($1) + 1);
        	sprintf(n, "%s%s", "num", $1);$$ = createNode(0, NULL, NULL,n); }
  |   VAR    {char *n = malloc(strlen("var") + strlen($1) + 1);
        sprintf(n, "%s%s", "var", $1);$$=createNode(0,NULL,NULL,n); }
  | '('expr ')' { $$ = createNode("parentheses",$2,NULL,NULL); }
  ;

%%

Node *createNode( char *op, Node *left, Node *right, char *opr) {
    Node *node = (Node *)malloc(sizeof(Node));
    node->op = op;
    node->left = left;
    node->right = right;
    node->opr=opr;
    return node;
}
/*int eval(Node *root) {
    if (root==NULL) 
	return 0;

    if (root->left==NULL && root->right==NULL) 
	return root->value;
     int leftVal = eval(root->left);
     int rightVal = eval(root->right); 
  // printf("Evaluating: %d %c %d\n", leftVal, root->op, rightVal);
   
	if(strcmp(root->op,"+")==0) 
		return leftVal + rightVal;
	if(strcmp(root->op,"-")==0) 
		return leftVal - rightVal;
	if(strcmp(root->op,"*")==0) 
		return leftVal * rightVal;
	if(strcmp(root->op,"/")==0) 
		return leftVal / rightVal;
	if(strcmp(root->op,"()")==0) 
		return leftVal;
	if(strcmp(root->op,"=")==0) 
		return leftVal=rightVal;

}
*/
void inorderTraversal(Node *root) {
    if (root==NULL) 
	return;
    if (root->left!=NULL && strcmp(root->op,"parentheses")==0)
{ 
    printf("( ");
    inorderTraversal(root->left);
    printf(")");
    return;
}
    inorderTraversal(root->left);
    if (root->op!=NULL && strcmp(root->op,"parentheses")!=0) 
	printf("%s ", root->op);
    else if(root->opr!=NULL)
       printf("%s ",root->opr);
inorderTraversal(root->right);
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}


int main(int argc,char **argv) {
	if(argc > 1) 
	{
		if(!(yyin = fopen(argv[1], "r"))) {
		perror(argv[1]);
		return (1);
		}
	}
    yyparse();
    return 0;
}

