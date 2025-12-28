%{
/* 046266 Compilation Methods - Project Part 2
 * Bison parser for C--.
 *
 * Builds a parse tree using the provided ParserNode structure and helper
 * functions (makeNode/concatList/dumpParseTree).
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "part2.h" /* defines YYSTYPE as ParserNode* */

extern int yylex(void);
extern int yylineno;
extern char* yytext;

/* Root of parse tree. part2_helpers.c expects this symbol. */
ParserNode* parseTree = NULL;

/* Forward declaration */
void yyerror(const char* msg);

/* Utility: build a nonterminal node with N children in left-to-right order. */
static ParserNode* mkNodeN(const char* type, int n, ...)
{
    va_list ap;
    va_start(ap, n);

    ParserNode* first = NULL;
    ParserNode* tail  = NULL;

    for (int i = 0; i < n; ++i) {
        ParserNode* child = va_arg(ap, ParserNode*);
        if (child == NULL) {
            continue;
        }
        if (first == NULL) {
            first = child;
            tail  = child;
        } else {
            tail->sibling = child;
            tail = child;
        }
        /* If the child already has siblings, advance tail to the end. */
        while (tail && tail->sibling) {
            tail = tail->sibling;
        }
    }

    va_end(ap);
    return makeNode(type, NULL, first);
}

%}

/* Token declarations (must match the lexer) */
%token TK_INT TK_FLOAT TK_VOID
%token TK_WRITE TK_READ
%token TK_WHILE TK_DO
%token TK_IF TK_THEN TK_ELSE
%token TK_RETURN

%token TK_ID
%token TK_INTEGERNUM TK_REALNUM
%token TK_STR

%token TK_RELOP TK_ADDOP TK_MULOP
%token TK_ASSIGN
%token TK_AND TK_OR TK_NOT

/* Operator precedence / associativity (similar to C/C++) */
%left TK_OR
%left TK_AND
%left TK_RELOP
%left TK_ADDOP
%left TK_MULOP
%right TK_NOT

/* Dangling-else resolution: ELSE binds to the nearest IF */
%nonassoc IF_NO_ELSE
%nonassoc TK_ELSE

%%

PROGRAM
    : FDEFS
        {
            $$ = mkNodeN("PROGRAM", 1, $1);
            parseTree = $$;
        }
    ;

FDEFS
    : FDEFS FUNC_DEF_API BLK
        { $$ = mkNodeN("FDEFS", 3, $1, $2, $3); }
    | FDEFS FUNC_DEC_API
        { $$ = mkNodeN("FDEFS", 2, $1, $2); }
    | /* empty */
        { 
            ParserNode* eps = makeNode("EPSILON", NULL, NULL);
            $$ = mkNodeN("FDEFS", 1, eps); 
        }
    ;

FUNC_DEC_API
    : TYPE TK_ID '(' ')' ';'
        { $$ = mkNodeN("FUNC_DEC_API", 5, $1, $2, $3, $4, $5); }
    | TYPE TK_ID '(' FUNC_ARGLIST ')' ';'
        { $$ = mkNodeN("FUNC_DEC_API", 6, $1, $2, $3, $4, $5, $6); }
    ;

FUNC_DEF_API
    : TYPE TK_ID '(' ')'
        { $$ = mkNodeN("FUNC_DEF_API", 4, $1, $2, $3, $4); }
    | TYPE TK_ID '(' FUNC_ARGLIST ')'
        { $$ = mkNodeN("FUNC_DEF_API", 5, $1, $2, $3, $4, $5); }
    ;

FUNC_ARGLIST
    : FUNC_ARGLIST ',' DCL
        { $$ = mkNodeN("FUNC_ARGLIST", 3, $1, $2, $3); }
    | DCL
        { $$ = mkNodeN("FUNC_ARGLIST", 1, $1); }
    ;

BLK
    : '{' STLIST '}'
        { $$ = mkNodeN("BLK", 3, $1, $2, $3); }
    ;

DCL
    : TK_ID ':' TYPE
        { $$ = mkNodeN("DCL", 3, $1, $2, $3); }
    | TK_ID ',' DCL
        { $$ = mkNodeN("DCL", 3, $1, $2, $3); }
    ;

TYPE
    : TK_INT
        { $$ = mkNodeN("TYPE", 1, $1); }
    | TK_FLOAT
        { $$ = mkNodeN("TYPE", 1, $1); }
    | TK_VOID
        { $$ = mkNodeN("TYPE", 1, $1); }
    ;

STLIST
    : STLIST STMT
        { $$ = mkNodeN("STLIST", 2, $1, $2); }
    | /* empty */
        { 
            ParserNode* eps = makeNode("EPSILON", NULL, NULL);
            $$ = mkNodeN("STLIST", 1, eps); 
        }
    ;

STMT
    : DCL ';'
        { $$ = mkNodeN("STMT", 2, $1, $2); }
    | ASSN
        { $$ = mkNodeN("STMT", 1, $1); }
    | EXP ';'
        { $$ = mkNodeN("STMT", 2, $1, $2); }
    | CNTRL
        { $$ = mkNodeN("STMT", 1, $1); }
    | READ
        { $$ = mkNodeN("STMT", 1, $1); }
    | WRITE
        { $$ = mkNodeN("STMT", 1, $1); }
    | RETURN
        { $$ = mkNodeN("STMT", 1, $1); }
    | BLK
        { $$ = mkNodeN("STMT", 1, $1); }
    ;

RETURN
    : TK_RETURN EXP ';'
        { $$ = mkNodeN("RETURN", 3, $1, $2, $3); }
    | TK_RETURN ';'
        { $$ = mkNodeN("RETURN", 2, $1, $2); }
    ;

WRITE
    : TK_WRITE '(' EXP ')' ';'
        { $$ = mkNodeN("WRITE", 5, $1, $2, $3, $4, $5); }
    | TK_WRITE '(' TK_STR ')' ';'
        { $$ = mkNodeN("WRITE", 5, $1, $2, $3, $4, $5); }
    ;

READ
    : TK_READ '(' LVAL ')' ';'
        { $$ = mkNodeN("READ", 5, $1, $2, $3, $4, $5); }
    ;

ASSN
    : LVAL TK_ASSIGN EXP ';'
        { $$ = mkNodeN("ASSN", 4, $1, $2, $3, $4); }
    ;

LVAL
    : TK_ID
        { $$ = mkNodeN("LVAL", 1, $1); }
    ;

CNTRL
    : TK_IF BEXP TK_THEN STMT TK_ELSE STMT
        { $$ = mkNodeN("CNTRL", 6, $1, $2, $3, $4, $5, $6); }
    | TK_IF BEXP TK_THEN STMT %prec IF_NO_ELSE
        { $$ = mkNodeN("CNTRL", 4, $1, $2, $3, $4); }
    | TK_WHILE BEXP TK_DO STMT
        { $$ = mkNodeN("CNTRL", 4, $1, $2, $3, $4); }
    ;

BEXP
    : BEXP TK_OR BEXP
        { $$ = mkNodeN("BEXP", 3, $1, $2, $3); }
    | BEXP TK_AND BEXP
        { $$ = mkNodeN("BEXP", 3, $1, $2, $3); }
    | TK_NOT BEXP
        { $$ = mkNodeN("BEXP", 2, $1, $2); }
    | EXP TK_RELOP EXP
        { $$ = mkNodeN("BEXP", 3, $1, $2, $3); }
    | '(' BEXP ')'
        { $$ = mkNodeN("BEXP", 3, $1, $2, $3); }
    ;

EXP
    : EXP TK_ADDOP EXP
        { $$ = mkNodeN("EXP", 3, $1, $2, $3); }
    | EXP TK_MULOP EXP
        { $$ = mkNodeN("EXP", 3, $1, $2, $3); }
    | '(' EXP ')'
        { $$ = mkNodeN("EXP", 3, $1, $2, $3); }
    | '(' TYPE ')' EXP
        { $$ = mkNodeN("EXP", 4, $1, $2, $3, $4); }
    | TK_ID
        { $$ = mkNodeN("EXP", 1, $1); }
    | NUM
        { $$ = mkNodeN("EXP", 1, $1); }
    | CALL
        { $$ = mkNodeN("EXP", 1, $1); }
    ;

NUM
    : TK_INTEGERNUM
        { $$ = mkNodeN("NUM", 1, $1); }
    | TK_REALNUM
        { $$ = mkNodeN("NUM", 1, $1); }
    ;

CALL
    : TK_ID '(' CALL_ARGS ')'
        { $$ = mkNodeN("CALL", 4, $1, $2, $3, $4); }
    ;

CALL_ARGS
    : /* empty */
        { 
            ParserNode* eps = makeNode("EPSILON", NULL, NULL);
            $$ = mkNodeN("CALL_ARGS", 1, eps); 
        }
    | POS_ARGLIST
        { $$ = mkNodeN("CALL_ARGS", 1, $1); }
    | NAMED_ARGLIST
        { $$ = mkNodeN("CALL_ARGS", 1, $1); }
    | POS_ARGLIST ',' NAMED_ARGLIST
        { $$ = mkNodeN("CALL_ARGS", 3, $1, $2, $3); }
    ;

POS_ARGLIST
    : EXP
        { $$ = mkNodeN("POS_ARGLIST", 1, $1); }
    | POS_ARGLIST ',' EXP
        { $$ = mkNodeN("POS_ARGLIST", 3, $1, $2, $3); }
    ;

NAMED_ARGLIST
    : NAMED_ARG
        { $$ = mkNodeN("NAMED_ARGLIST", 1, $1); }
    | NAMED_ARGLIST ',' NAMED_ARG
        { $$ = mkNodeN("NAMED_ARGLIST", 3, $1, $2, $3); }
    ;

NAMED_ARG
    : TK_ID ':' EXP
        { $$ = mkNodeN("NAMED_ARG", 3, $1, $2, $3); }
    ;

%%

void yyerror(const char* msg)
{
    (void)msg; /* msg is not used; we print in the required format */

    const char* lexeme = (yytext && yytext[0]) ? yytext : "EOF";
    printf("Syntax error: '%s' in line number %d\n", lexeme, yylineno);
    exit(2);
}
