
#include "cosmos.cpp"

int main(int argc, char* argv[]){
	start();
	//resolve args
	args=argv;
	arg_n=argc;
	/*read from file*/
	if(argc>=2) {
		if(streq(argv[1], "-t")) {
			trace = true;
			if(argc>=3) {
				//printf("Reading: %s\n", argv[2]);
				e0 = read_file(argv[2]);
			}
			else
				e0 = read_file("out.bc");
		}
		else {
			//printf("Reading: %s\n", argv[1]);
			e0 = read_file(argv[1]);
		}
	}
	else {
		//e0 = read_file("out.bc");
		//e0 = read_file("test.bc");
		e0 = read_file("nil.bc");
	}
	
	f = fopen("log", "w");
	if(f==NULL) throw NULL;
	
	if(e0==NULL) return 1;
	/* call upon a function */
	//regs[252] = NULL;
	int i=eval();/*
	if(regs[252]!=NULL) {
		printf("\n==> ");
		displayFormatln(regs[252]);
	}*/
	/* display result */
	#ifdef DEBUG
	//printf("==> regs: ["); display(regs[0]); printf(", "); display(regs[1]); printf(", "); display(regs[2]); printf("]\n");
	fclose(f);
	#endif
	end();
	if(i==0)
		return 1;
}

