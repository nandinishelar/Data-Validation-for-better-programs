%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>

extern FILE *yyin;

typedef struct Node {
    char *op;              
    struct Node *left;     
    struct Node *right;   
    char *opr;            
} Node;

typedef struct Variable {
    char *name;
    int value;
    bool isResolved;
    bool isVisited;
    struct Node *expression;
    struct Variable *dependencies[100]; // Variables it depends on
    int dependencyCount;
    bool isAssigned; // Track if a variable has already been assigned
} Variable;

Node *createNode(char *op, Node *left, Node *right, char *opr);
void inorderTraversal(Node *root);
int eval(Node *root);
void resolveVariables();
void yyerror(const char *s);
int yylex();
Variable *findOrCreateVariable(char *name);
bool detectCycle(Variable *var);
void addDependency(Variable *var, char *dependencyName);

#define MAX_VARIABLES 100
Variable variables[MAX_VARIABLES];
int variableCount = 0;

%}

%union {
   char *opr;
   struct Node *node;
}

%token <opr> NUMBER
%token <opr> VAR
%left '+' '-'
%left '*' '/'
%right '='
%type <node> expr term factor program

%%

program:
    program expr '\n' {
        //printf("Inorder Traversal: ");
        //inorderTraversal($2);
        //printf("\n");
        if ($2->op && strcmp($2->op, "assign") == 0) {
            Variable *var = findOrCreateVariable($2->opr);
            if (var->isAssigned) {
                printf("Error: Variable '%s' already assigned. Redeclaration is not allowed.\n", var->name);
                exit(1);
            }
            var->isAssigned = true;
            var->expression = $2;
        }
    }
  | expr '\n' {
      /*  printf("Inorder Traversal: ");
        inorderTraversal($1);*/
       // printf("\n");
        if ($1->op && strcmp($1->op, "assign") == 0) {
            Variable *var = findOrCreateVariable($1->opr);
            if (var->isAssigned) {
                printf("Error: Variable '%s' already assigned. Redeclaration is not allowed.\n", var->name);
                exit(1);
            }
            var->isAssigned = true;
            var->expression = $1;
        }
    }
  | '\n'
  ;

expr:
    VAR '=' expr {
        $$ = createNode("assign", $3, NULL, $1);
        Variable *var = findOrCreateVariable($1);
        addDependency(var, $3->opr); // Add dependencies
    }
  | expr '+' term {
        $$ = createNode("plus", $1, $3, NULL);
    }
  | expr '-' term {
        $$ = createNode("minus", $1, $3, NULL);
    }
  | term {
        $$ = $1;
    }
  ;

term:
    term '*' factor {
        $$ = createNode("mul", $1, $3, NULL);
    }
  | term '/' factor {
        $$ = createNode("div", $1, $3, NULL);
    }
  | factor {
        $$ = $1;
    }
  ;

factor:
    NUMBER {
        $$ = createNode(NULL, NULL, NULL, $1);
    }
  | VAR {
        $$ = createNode(NULL, NULL, NULL, $1);
    }
  | '(' expr ')' {
        $$ = $2;
    }
  ;

%%

Node *createNode(char *op, Node *left, Node *right, char *opr) {
    Node *node = (Node *)malloc(sizeof(Node));
    node->op = op;
    node->left = left;
    node->right = right;
    node->opr = opr;
    return node;
}

Variable *findOrCreateVariable(char *name) {
    for (int i = 0; i < variableCount; i++) {
        if (strcmp(variables[i].name, name) == 0) {
            return &variables[i];
        }
    }
    Variable *var = &variables[variableCount++];
    var->name = strdup(name);
    var->isResolved = false;
    var->isVisited = false;
    var->expression = NULL;
    var->dependencyCount = 0;
    var->isAssigned = false;
    return var;
}

void addDependency(Variable *var, char *dependencyName) {
    if (!dependencyName || isdigit(dependencyName[0])) return;
    Variable *dependency = findOrCreateVariable(dependencyName);
    var->dependencies[var->dependencyCount++] = dependency;
}

bool detectCyclehelp(Variable *var, bool *recStack) {
    if (var->isVisited == false) {
        var->isVisited = true;
        recStack[variableCount] = true;

        for (int i = 0; i < var->dependencyCount; i++) {
            Variable *dependency = var->dependencies[i];
            if (!dependency->isResolved && (recStack[variableCount] || detectCyclehelp(dependency, recStack))) {
                return true;
            }
        }
    }
    recStack[variableCount] = false;
    return false;
}

bool detectCycle(Variable *var) {
    bool recStack[MAX_VARIABLES] = {false};
    return detectCyclehelp(var, recStack);
}

int eval(Node *root) {
    if (root == NULL) return 0;

    if (root->opr) {
        if (isdigit(root->opr[0])) return atoi(root->opr);
        
      
        Variable *var = findOrCreateVariable(root->opr);
        if (!var->isAssigned) {
            printf("Error: Variable '%s' has not been assigned a value.\n", var->name);
            exit(1);  // Exit if the variable is unassigned
        }
        if (!var->isResolved) {
            resolveVariables(var);  // Resolve dependencies for the variable
        }
        return var->value;
    }

   
    int leftVal = eval(root->left);
    int rightVal = eval(root->right);

    if (strcmp(root->op, "plus") == 0) return leftVal + rightVal;
    if (strcmp(root->op, "minus") == 0) return leftVal - rightVal;
    if (strcmp(root->op, "mul") == 0) return leftVal * rightVal;
    if (strcmp(root->op, "div") == 0) return leftVal / rightVal;
    return 0;
}

void resolveVariables(Variable *var) {
    if (detectCycle(var)) {
        printf("Error: Cycle detected. Execution halted.\n");
        exit(1);
    }

    
    for (int i = 0; i < var->dependencyCount; i++) {
        Variable *dep = var->dependencies[i];
        if (!dep->isAssigned) {
            printf("Error: Variable '%s' has not been assigned a value and is required by '%s'.\n", dep->name, var->name);
            exit(1);
        }
        // Resolve the dependency if it's not already resolved
        if (!dep->isResolved) {
            resolveVariables(dep);
        }
    }

   
    if (var->expression) {
        var->value = eval(var->expression->left);  
        var->isResolved = true;
    }
}


void inorderTraversal(Node *root) {
    if (root == NULL) return;
    inorderTraversal(root->left);
    if (root->op) printf("%s ", root->op);
    else if (root->opr) printf("%s ", root->opr);
    inorderTraversal(root->right);
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        if (!(yyin = fopen(argv[1], "r"))) {
            perror(argv[1]);
            return 1;
        }
    }
    yyparse();
    for (int i = 0; i < variableCount; i++) {
        resolveVariables(&variables[i]);
        printf("%s = %d\n", variables[i].name, variables[i].value);
    }
    return 0;
} 
