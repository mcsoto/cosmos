//cosmos repl

#include "cosmos.cpp"
#include <time.h>       /* clock_t, clock, CLOCKS_PER_SEC */
int main(int argc, char* argv[]){
		
	null->type=T_NULL;
	args=argv;
	arg_n=argc;
	srand(time(NULL));
	
	cgb.mode='c';
	cgb.line2=-1;
	cgb.last=NULL;
	
	load_std();
	
	//move const 'p' to upvalue of 'q'
	//((Env*)(e0->consts[1].value.p))->upvalues = e0->consts;
	
	//place x,y in cregisters
	any->type = T_NULL;	
	Object* exports = new Object;
	exports->type = T_REF;
	exports->value.o = exports;
	regs[0] = any;//exports;
	regs[1] = any;
	regs[2] = any;
	
	//resolve args
	//printf("%d\n", argc);
	
	/*read from file*/
	e0 = read_file("cosmos.bc");
	
	f = fopen("log", "w");
	if(f==NULL) throw NULL;
	
	if(e0==NULL) return 1;
	//throw 2;
	/* call upon a function */
	regs[252] = NULL;
	int i=eval();
	
	/* display result */
	#ifdef DEBUG
	//printf("==> regs: ["); display(regs[0]); printf(", "); display(regs[1]); printf(", "); display(regs[2]); printf("]\n");
	fclose(f);
	#endif
	//double x=time();
	//return i;
	if(i==0)
		//printf("| false");
		printf("\nProgram did not return successfully.");
	end();
	return 0;
}

