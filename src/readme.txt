see readme.md

'make' will create two files 'p' and 'p2'.

./p2 test0
./p test0

p2 shows the whole execution and bytecode in addition to running the program.

helper files (unix-only):

./gen 12 test0 #runs test0.co using parser 12.co

12.co uses gen9.co, which was compiled with 10.co, which uses gen5.co, and so on. 

comp.js is only for comparison (a vm written in a non-C language), it is not maintained

the code is written in a C-style on purpose, with a few C++ features, so as to (possibly) be C-compatible later. this won't happen, though. do not complain about this.
