CC=g++
CFLAGS= -g -std=c++0x -fpermissive -w
CFLAGSP= -Wall -O2
C=./p

all:
	$(CC) $(CFLAGS) main2.cpp -o p
	$(CC) $(CFLAGS) -DDEBUG=1 main2.cpp -o p2
	$(CC) $(CFLAGS) main.cpp -o cosmos
	$(CC) $(CFLAGS) -DDEBUG=1 main.cpp -o cosmos2
	
test:
	./p nil
	./p2 nil
	./cosmos -l test8
	./cosmos -l test9
	./cosmos -l test1
	./cosmos -l test3

parser:
	./p c10 cosmos
	
cosmos:
	$(CC) $(CFLAGS) $(CFLAGSP) main.cpp -o cosmos

main:	
	$(CC) $(CFLAGS) main2.cpp -o p
	./p nil
	$(CC) $(CFLAGS) -DDEBUG=1 main2.cpp -o p2
	./p2 nil
	
install:
	$(CC) $(CFLAGS) cosmos.cpp -o p
	
debug: 
	$(CC) $(CFLAGS) -DDEBUG=1 main2.cpp -o p2
	$(CC) $(CFLAGS) -DDEBUG=1 main.cpp -o cosmos2
	
8:
	./gen7 gen8
12:
	./gen 10 gen9

c:
	#./p c0 c10
	$(C) 10 12
	$(C) 12 2
	
clean:
	rm -f cosmos cosmos2 test*.bc p p2 temp* log
	rm *.exe *.exe.stackdump
	
gen4: p
	./p c3 gen4
	
gen3:
	sh update.sh gen3
	
	
