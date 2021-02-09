#include "stdio.h"
#include "stdint.h"
#include "stdlib.h"

#include <vector>
#include <list>
#include <stack>
#include <map>
#include <cstring>
#include <string>

#include <time.h>

void io_write() {
	puts("io_write\n");
}

static std::map<std::string, void(*)() > core;

void reg(std::string s, void (*p)()) {
	core[s] = p;
}

int main(){
	
	std::string s ("print");
	
	reg(s, io_write);
	
	void (*fn2)();
	fn2 = core["print"];
	fn2();

	FILE *f = fopen("out.bc","wb");
	int size = 6;
	//fwrite(size, sizeof(int), 1, f);
	fputc(112, f);fputc(114, f);fputc(105, f);fputc(110, f);fputc(116, f);fputc(0, f);
	fclose(f);
	
	f = fopen("out.bc","rb");
	
	//fread(&size, sizeof(int), 1, f);
	
	char *s2 = new char[size];
	fread(s2, sizeof(char), size, f);
	fclose(f);
	
	printf("str:%s (size:%d) = %d\n", s2, size, strcmp(s2, "print"));
	
	fn2 = core[s2];
	fn2();
	srand (time(NULL));
	printf("%f\n",rand());
	printf("%f\n",rand());
	printf("%f\n",rand());
}