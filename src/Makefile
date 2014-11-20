.PHONY: stdlib cosmos

COSMOS?=./cosmos
SWIPL?=swipl

cosmos_OPTS=--main
STDLIB_OPTS=--no-std-libs
list_OPTS=$(STDLIB_OPTS)
string_OPTS=$(STDLIB_OPTS)
math_OPTS=$(STDLIB_OPTS)
io_OPTS=$(STDLIB_OPTS)
logic_OPTS=$(STDLIB_OPTS)
table_OPTS=$(STDLIB_OPTS)

%.pl: %.cosmos
	$(COSMOS) $($*_OPTS) --module $(patsubst %.cosmos,%,$<)

# stdlib
math.pl:

string.pl: math.pl

list.pl: string.pl

logic.pl: list.pl string.pl math.pl

io.pl: logic.pl

stdlib-clean:
	touch list.cosmos string.cosmos math.cosmos io.cosmos logic.cosmos table.cosmos

stdlib: list.pl string.pl math.pl io.pl logic.pl table.pl

# compiler
types.pl:

whitespacer.pl: lexer.pl

parser.pl: lexer.pl whitespacer.pl

gen.pl: lexer.pl parser.pl whitespacer.pl types.pl

cosmos.pl: lexer.pl parser.pl whitespacer.pl gen.pl

compiler-clean:
	-rm cosmos.pl gen.pl lexer.pl parser.pl whitespacer.pl types.pl

compiler: cosmos.pl types.pl

# frontend
cosmos:
	$(SWIPL) -t halt -o cosmos -g main -c $@.pl

# tests
test0.pl: test1.pl

test: test0.pl test1.pl
	$(COSMOS) --module test0
	$(COSMOS) --module test1

# rebuild
rebuild:
	# build frontend with current compiler and stdlib modules
	$(MAKE) cosmos
	$(MAKE) compiler-clean
	$(MAKE) compiler cosmos
	$(MAKE) stdlib-clean
	$(MAKE) stdlib compiler-clean compiler cosmos test-clean test
