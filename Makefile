# Target to build the executable
exec: makeexec ./expTree expression.txt
		./expTree expression.txt

# Target to compile the executable
makeexec: expTree.tab.o lex.yy.o
	gcc -o expTree expTree.tab.o lex.yy.o

# Compile object files from sources
expTree.tab.o lex.yy.o: expTree.tab.c lex.yy.c
	gcc  -c expTree.tab.c lex.yy.c

# Generate lex.yy.c from expTree.l
lex.yy.c: expTree.l
	flex expTree.l

# Generate expTree.tab.c and expTree.tab.h from expTree.y
expTree.tab.c expTree.tab.h: expTree.y
	bison -d expTree.y

# Clean up build artifacts
clean:
	rm -f expTree expTree.tab.c expTree.tab.h lex.yy.c expTree.tab.o lex.yy.o

