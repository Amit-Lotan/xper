# 046266 Compilation Methods - Project Part 2
# Build the C-- parser (Flex + Bison) into an executable named: part2

CC      := gcc
LEX     := flex
YACC    := bison

CFLAGS  := -Wall -Wextra -std=gnu11 -Wno-sign-compare

TARGET  := part2

# Generated sources
LEX_C   := part2-lex.c
YACC_C  := part2.tab.c
YACC_H  := part2.tab.h

OBJ     := part2_helpers.o part2.tab.o part2-lex.o

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

# ---- Bison ----
$(YACC_C) $(YACC_H): part2.y part2.h part2_helpers.h
	$(YACC) -d -o $(YACC_C) part2.y

part2.tab.o: $(YACC_C) $(YACC_H) part2.h part2_helpers.h
	$(CC) $(CFLAGS) -c -o $@ $(YACC_C)

# ---- Flex ----
$(LEX_C): part2.lex $(YACC_H) part2.h part2_helpers.h
	$(LEX) -o $@ part2.lex

part2-lex.o: $(LEX_C) $(YACC_H) part2.h part2_helpers.h
	$(CC) $(CFLAGS) -c -o $@ $(LEX_C)

# ---- Helpers ----
part2_helpers.o: part2_helpers.c part2_helpers.h
	$(CC) $(CFLAGS) -c -o $@ part2_helpers.c

clean:
	rm -f $(TARGET) $(OBJ) $(LEX_C) $(YACC_C) $(YACC_H)
