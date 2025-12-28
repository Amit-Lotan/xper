/* Part 2 - shared definitions for lexer and parser
 *
 * Defines the semantic value type (YYSTYPE) as a pointer to ParserNode.
 * IMPORTANT: This header must be included *before* including part2.tab.h
 * in any compilation unit (e.g., the lexer), so that Bison will not
 * typedef YYSTYPE to int.
 */

#ifndef PART2_H
#define PART2_H

#include "part2_helpers.h"

/* Semantic value for both Flex and Bison */
#define YYSTYPE ParserNode*

#endif /* PART2_H */
