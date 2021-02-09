
YACC=yacc
YFLAGS= -d
LEX=flex
CC=g++
CFLAGS= -g -std=c++0x -fpermissive -w

all:
	$(CC) $(CFLAGS) main2.cpp -o p
	./p nil
	$(CC) $(CFLAGS) -DDEBUG=1 main2.cpp -o p2
	#./p2
	$(CC) $(CFLAGS) main.cpp -o cosmos
	
test:
	$(CC) $(CFLAGS) main2.cpp -o p
	./p nil
	$(CC) $(CFLAGS) -DDEBUG=1 main2.cpp -o p2
	./p2 nil
	$(CC) $(CFLAGS) main.cpp -o cosmos
	$(CC) $(CFLAGS) -DDEBUG=1 main.cpp -o cosmos2

parser:
	./p c10 cosmos
	
cosmos:
	$(CC) $(CFLAGS) main.cpp -o cosmos

main:
	$(CC) $(CFLAGS) main.cpp -o cosmos
old:
	$(CC) $(CFLAGS) cosmos0.cpp -o p3
	./p3
	$(CC) $(CFLAGS) -DDEBUG=1 cosmos0.cpp -o p4
	./p4
	
install:
	$(CC) $(CFLAGS) cosmos.cpp -o p
	
debug: 
	$(CC) $(CFLAGS) -DDEBUG=1 main2.cpp -o p2
	$(CC) $(CFLAGS) -DDEBUG=1 main.cpp -o cosmos2
	
5: gen4
	./p3 c3.bc c5
6:
	./p3 c3.bc c6
8:
	./gen7 gen8
c:
	./p c0 c10

clean:
	rm cosmos cosmos2 test*.bc p p2 temp* log
	rm *exe*
	
gen4: p
	./p c3 gen4
	
gen3:
	sh update.sh gen3
	
	
