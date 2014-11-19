%.pl: %.cosmos
	cosmos --module $(patsubst %.cosmos,%,$<)

all: cosmos

core.pl:

math.pl: core.pl

string.pl: core.pl math.pl

list.pl: core.pl string.pl

logic.pl: core.pl list.pl string.pl math.pl

io.pl: core.pl logic.pl

types.pl: core.pl string.pl math.pl io.pl

lexer.pl: core.pl

whitespacer.pl: core.pl lexer.pl

parser.pl: core.pl lexer.pl whitespacer.pl

gen.pl: core.pl lexer.pl parser.pl whitespacer.pl types.pl

cosmos.pl: core.pl lexer.pl parser.pl whitespacer.pl gen.pl

cosmos: cosmos.pl
	swipl -t halt -o cosmos -g main -c $<

clean:
	rm cosmos.pl gen.pl io.pl lexer.pl list.pl logic.pl math.pl parser.pl string.pl table.pl test0.pl test1.pl types.pl whitespacer.pl

test: test0.pl test1.pl
	./cosmos --module test0
	./cosmos --module test1
