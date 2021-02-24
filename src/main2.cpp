
#include "cosmos.cpp"

void pr_regs() {
	printf("regs: [");
	display(regs[0]); printf(", "); display(regs[1]); printf(", "); display(regs[2]);
	printf("]\n");
}


int main(int argc, char* argv[]){
	start();
	//resolve args
	args=argv;
	arg_n=argc;
	/*read from file*/
	try {
		if(argc>=2) {
			if(streq(argv[1], "-t")) {
				trace = true;
				if(argc>=3) {
					//printf("Reading: %s\n", argv[2]);
					e0 = read_file(argv[2]);
				}
				else
					e0 = read_file("nil.bc");
			}
			else {
				//printf("Reading: %s\n", argv[1]);
				e0 = read_file(argv[1]);
			}
		}
		else {
			e0 = read_file("nil.bc");
		}
	}
	catch (const char* s) {
		printf("\nCosmosRuntimeError: %s\n",s);
		error();
		return 0;
	}
	
	if(e0==NULL) return 1;
	/* call upon a function */
	int i=eval();
	/* display result */
	end();
	if(i==0)
		return 1;
}

