if g++ -std=c++0x -fpermissive -g cosmos.cpp -o p; then (./p; if g++ -std=c++0x -DDEBUG=1 -fpermissive -g cosmos.cpp -o p2; then ./p2; fi) fi

echo $1
