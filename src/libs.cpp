static Object *o, *o2, *o3, *o4, *o5;
static Table *t;
static FILE *in=stdin, *out=stdout;

#include <stdlib.h>
//#include <time.h>

#define prep(X) do { o = regs[0]; } while (0)
#define prep2(X) do { o = regs[0]; o2 = regs[1]; } while (0)
#define prep3(X) do { o = regs[0]; o2 = regs[1]; o3 = regs[2]; } while (0)
#define prep4(X) do { o = regs[0]; o2 = regs[1]; o3 = regs[2]; o4 = regs[3]; } while (0)
#define d3(X) do { o = regs[0]; o2 = regs[1]; o3 = deref(regs[2]); } while (0)
#define fcvalue(o) (Functor*)o->value.fc
#define ivalue(o) o->value.i

//#define eqs(o1,V) do { Object* o=new Object; sets(o,V); trail_push(o); unify(o1,o); } while (0)
//#define eq_s(o1,V,c) do { Object* o=new Object; sets(o,V); trail_push(o); unify(o1,o); } while (0)
//#define eq_s(o1,V,c) do { Object* o=new Object; sets(o,V); trail_push(o); c=unify(o1,o); } while (0)

Object* var(char* s) {
	Object*o=new Object;
	sets(o,s);
	return o;
}

Object* var(int e) {
	Object*o=new Object;
	seti(o,e);
	return o;
}

int assert(bool b,char*s) {
	if(!b)
		throw var(s);
}

/*
It's all passed to registers before an external c:function is called.
It can be safely assumed they have been deferenced.
It's also up to the writer to see that functions that can receive a ref unbound deal with them,
if a function receives bound values only for some arguments this is to be set in other parts of the language so you can treat them as bound here.
If the ref is unbound you can use the function 'set' to set it, if it's guaranteed to be so.
*/

int require() {
	//printf("\n==\n");
	Closure *c0 = c;
	//c->last=last;
	Env *e = e0;
	regs[252] = null;
	Object* o = regs[0];
	Object* o2 = regs[1];
	Object* o3;
	
	if(o2->type!=T_REF) {
		valid = false;
		displayFormatln(o);
		displayFormatln(o2);
		throw "argument not a variable";
	}
	/*read from file*/
	char *s = o->value.s;
	char *s2;
	//printf("require:%s\n",s);
	o3 = req[s];
	if(!o3) {
		s2 = concat(s,".bc");
		o3 = req[s2];
	}
	if(!o3) {
		//printf("require:%s;\n",s);
		p2("require:%s;\n",s);
		e0 = read_file_(open_file(o->value.s));//read_file(o->value.s);
		p1("end read file\n");
		/* call upon a function */
		co_execute();
		p2("\nend require %s\n\n",s);
		//if(regs[252]->type==T_NULL) throw "required file has no export value";
		unify(o2,regs[252]);
		#ifdef DEBUG
		printf("value = ");
		displayFormatln(o2);
		#endif
		req[s] = regs[252];
	}
	else {
		#ifdef DEBUG
		printf("%s = ",s);
		displayFormatln(o3);
		#endif
		unify(o2,o3);
	}
	c = c0;
	e0 = e;
	p1("\n");
}

int eval_file() {
	prep2();
	//p2("\neval:%s\n",o->value.s);
	Env* e = e0;
	Closure *prev=c;
	e0 = read_file(o->value.s);
	if(e0==NULL) throw "eval: cannot open file";//return;
	
	saved_c=eval();
	//printf("eval:%d\n",saved_c);
	//if(saved_c==0) throw "failed eval";
	//seti(o2,(double)(int)saved_c);
	//pr_locs(saved_c);
	e0=e;c=prev;
}

int export_c() {
	regs[252] = regs[0];
}

/*
Functor* list_to_fc() {
	return fc;
}
*/

//callbacks

int callbacks() {
	prep();
	seti(o,time(0));
}

//system

int rec() {
	//i=0;
}

int os_time() {
	prep();
	seti(o,time(0));
}

int os_clock() {
	double x=((double)(clock())/CLOCKS_PER_SEC);
	prep();
	seti(o,x);
}

int exec() {
	Object* o = regs[0];
	system(o->value.s);
}

//debug
/*
int print_trail() {
	pr_trail();
	printf("\n");
}

int on() {
	halt = true;
}
*/
int set() {
	puts("break");
	step = true;cgb.mode='n';
	printf("mode:%c;%d\n",cgb.mode,cgb.line);
}

int table_new() {
	prep();
	o->type = T_DATA;
	o->value.t = new Table;
}

int arg() {
	Object* o = regs[0];
	printf("arg[%d]",arg_n);
	if(arg_n<3)
		throw "no arg2";
	printf("=%s\n",args[2]);
	o->value.s = args[2];
	o->type=T_STR;
}

int get_args() {
	Object* o1 = regs[0];
	Object* o;
	Functor* fc = cons();
	o1->value.fc=fc;
	o1->type=T_FUNCTOR;
	for(int i=0;i<arg_n;i++) {
		fc->param = new Object*[2];
		fc->param[0] = new Object;
		fc->param[0]->value.s = args[i];//o->value.s;
		fc->param[0]->type=T_STR;
		fc->param[1] = new Object;
		fc->param[1]->type = T_FUNCTOR;
		fc->param[1]->value.fc = cons();
		fc = fc->param[1]->value.fc;
	}
	fc->n=0;
}

int fc_get() {
	prep3();
	Functor* fc = fcvalue(o);
	unify(o3,fc->param[(int)ivalue(o2)]);
}

int fc_size() {
	prep2();
	Functor* fc = fcvalue(o);
	unify(o2,fc->n);
}

static Closure *c1;
//static ChoicePoint *c1;
//static Env *e;
static Closure **cur;
static Closure *c0;

static char** arr;


int locs() {
	Closure* c=saved_c;
	printf(";%d,%d\n",c,c->e);
	pr_locs(c);
	/*
	Object* o;
	for(int i=0;i<c1->e->n_locals;++i) {
		printf("%d=",i);//printf("%d=%s",i,arr[i]);
		o = c->locals[i];
		//displayFormat(&(cur)->locals[o->value.i]);
		c1->locals[i] = new Object*;
		//c1->locals[i] = &c->locals[i];
		c1->locals[i].value = o->value; c1->locals[i].type = o->type;
		displayFormat(&c1->locals[i]);
		printf(",");
	}
	if(e) {
		if(e!=c->e)
			throw 23;
		printf(";%d,%d\n",e->n_locals,c->e->n_locals);
		printf("[");
		for(int i=0;i<c->e->n_locals;++i) {
			printf("%d=",i);//printf("%d=%s",i,arr[i]);
			//displayFormat(&(cur)->locals[o->value.i]);
			//displayFormat(&c0->locals[i]);
			printf(",");
		}
		printf("]\n");
		return 0;
	}
	*/
}
	
int sethook() {
	prep2();
	hook1=o;
	displayFormatln(hook1);
	//seti(o2,c->e->n_args);
	//unify(o,o2);
}

int get_nargs() {
	prep();
	o2=new Object;
	seti(o2,c->e->n_args);
	printf("%d\n",c->e->n_args);
	unify(o,o2);
}

int get_nlocs() {
	prep();
	o2=new Object;
	seti(o2,c->e->n_locals+c->e->n_upvals);
	unify(o,o2);
	pr_locs(c);
}

int get_local() {
	prep3();
	Closure* c=(Closure*)(o->value.data);
	displayFormatln(&c->locals[(int)o2->value.i]);
	unify(o3,&c->locals[(int)o2->value.i]);
}

int get_register() {
	prep2();
	printf("put %d:\n",o->value.i);
	displayln(o);
	unify(o2,regs[(int)(o->value.i)]);
	displayln(o2);
}

int get_fname() {
	prep2();
	//printf("name;%s\n",c->e->debug->name);
	sets(o2,((Closure*)(o->value.data))->e->debug->name);
}

int loc() {
	prep2();
	Closure* c=saved_c;
	unify(o,&c->locals[(int)o2->value.i]);
}

int closure() {
	prep4();
	Closure* c=saved_c;//(Closure*)(o->value.data);
	//printf("name;%s\n",c->e->debug->name);
	printf("%d,%d,\n",c,c->e);
	sets(o2,c->e->debug->name);
	seti(o3,c->e->n_args);
	seti(o4,c->e->n_locals);
	//seti(o5,c->e->n_locals);
	
}

//logic

int neg() {
	Object* o = regs[0];
	Object* o2 = regs[1];
	//p(displayFormat(o); p1(" != "); displayFormatln(o2););
	if(unify(o,o2))
		valid=false;
}

int neq() {
	Object* o = regs[0];
	Object* o2 = regs[1];
	//p(displayFormat(o); p1(" != "); displayFormatln(o2););
	if(unify(o,o2))
		valid=false;
}

int logic_throw() {
	o = regs[0];
	throw o;
}

int pause() {
	getchar();
}

int deleteEnv(Closure* c) {
	Env *e=c->e;
	//delete c->locals;
}

int del() {
	o=regs[0];
	if(o->type==T_FUNCTOR) {
		delete o->value.fc;
		//delete o->type;
	}
	delete o;
}

int check() {
	prep();
	if(o->type==T_INT&&o->value.i>=0) {
		
	}
	else {
		if(o->type==T_INT)
			displayFormatln(o);
		throw var("byte has negative value");
	}
}

int def() {
	o=regs[0];
	if(o->type==T_REF) {
		printf("Variable ");
		displayFormat(o);
		printf(" is not defined in %s.\n", cur_c->e->debug->name);
		throw var("def");
	}
}

int undef() {
	prep();
	if(o->type!=T_REF) {
		printf("");
		displayFormat(o);
		printf(" is defined in %s.\n", cur_c->e->debug->name);
		throw var("def");
	}
}

int undata() {
	prep();
	assert(o->type!=T_DATA,"userdata sent");
}

int is_int() {
	prep();
	if(o->type!=T_INT&&o->type!=T_REF)
		throw var("int");
}

int type() {
	prep2();
	if(o->type==T_INT) {
		sets(o2,"Number");
		//eq_s(o3,"Number",v);
	}
	else if(o->type==T_STR) {
		sets(o2,"String");
	}
	else if(o->type==T_FUNCTOR) {
		sets(o2,"Functor");
	}
	else if(o->type==T_FILE) {
		sets(o2,"File");
	}
	else if(o->type==T_DATA) {
		sets(o2,"data");
	}
	else if(o->type==T_REL) {
		sets(o2,"Relation");
	}
	else {
		sets(o2,"ref");
	}
}

//vm

int pass() {
	
}

int info() {/*
	Env *e0 = cur_c->e;
	printf("---\n");
	if(e0->debug!=NULL) {
		printf("%s", e0->debug!=NULL ? e0->debug->name : "");
		printf("(");
		for(int i=0;i<e0->n_args;++i) {
			if(i!=0) printf(", ");
			displayFormat(deref(regs[i]));
		}
		printf(")\n");
	}
	pr_cl(c);
	printf("gcs: [%d, %d, %d]. [%d]\n", gc1.size(), gc2.size(), gc.size(), gc0.size());
	printf("---\n");*/
}

int info_gc() {
	printf("gcs: [%d, %d, %d]. [%d]\n", gc.size(), gc1.size(), gc2.size(), gc0.size());
	if(gc0.size()>25000)
		collect0();
}

int erase_trail(int pos) {
	for(int i=trail.size()-1;i >= pos;--i) {
		o = trail[i];
		trail.pop_back();/*
		#ifdef DEBUG
		pf2("%d ",i);
		//displayln(o);
		//printf("%d ",o);
		printf("unwind ");
		//displayln(o);
		#endif*/
	}
}

int erase_cp(ChoicePoint *cur) {
	while(cur!=cp) {
		cp=cp->prev;
	}
}

int cut() {
	p2("cut %d:\n", c->cur_trail);
	//pr_trail(); pr_cp(); printf("\n");
	erase_cp(c->cur_cp);
	erase_trail(c->cur_trail);
	//pr_trail(); pr_cp();
	//p1("\n");
}

int once() {
	prep2();
	int i = trail.size(); ChoicePoint *cur = cp;
	
	//run
	e0 = o->value.e;
	co_execute();
		
	erase_trail(i);
	//new cp added
	while(cur!=cp) { //cp->c!=c
		//restore(&e0, &c);
		//printf("ident: %d;%d,%d,%s\n",ident,cp->pos,c->pos,e0->debug->name);
		//ident--;
		cp=cp->prev;
	}
}

/*
in order to implement a meta call, apply2 puts elements of a list in registers while apply1 loads the relation into a special register
this implements apply(p,[...])
*/
int apply1() {
	prep();
	//displayln(o);
	regs[251] = deref(o);
}

int apply2() {
	prep();
	//displayFormatln(o);
	assert(o->type==T_FUNCTOR,"not functor");
	Functor *fc=o->value.fc;
	for(int i=0;fc->n!=0;++i) {
		regs[i] = deref(fc->param[0]);
		//displayFormatln(regs[i]);
		fc=fc->param[1]->value.fc;
	}
}

int apply() {
	prep2();
	
	regs[251] = deref(o);
	Functor *fc=o2->value.fc;
	for(int i=0;fc->n!=0;++i) {
		regs[i] = deref(fc->param[0]);
		fc=fc->param[1]->value.fc;
	}
}

//table

int table_set() {
	t=deref(regs[0])->value.t;
	o2=deref(regs[1]);
	o3=deref(regs[2]);
	o4=deref(regs[3]);
	//t->insert(std::pair<const char*, Object*>(o2->value.s, o3));
	t = set(t,o2,o3);//o3 = get(t,o2);//(*t)[o2->value.s] = o3;
	o4->type = T_DATA;
	o4->value.t = t;
	p(displayln(regs[3]));
	//std::cout << (t) << std::endl;
}

int table_get() {
	prep3();
	Functor *fc=o->value.fc;
	if(o->type!=T_FUNCTOR) throw "not functor";
	while(fc->n!=0) {
		displayFormat(fc->param[0]); printf(": "); displayFormat(fc->param[1]); printf("\n");
		if(unify(o2, fc->param[0])) {
			unify(o3, fc->param[1]);
			return 1;
		}
		fc = (Functor*)fc->param[2]->value.fc;
	}
	valid=false;
}

//object

int obj_get() {
	prep3();
	Table *t = o->value.t;
	o3->value.o = get(t,o2);
}

//bit

int bit_and() {
	prep3();
	o3->type=T_INT;
	o3->value.i = (int)o->value.i & (int)o2->value.i;
}

int bit_shl() {
	prep3();
	o3->type=T_INT;
	o3->value.i = (int)o->value.i << (int)o2->value.i;
}

int bit_shr() {
	prep3();
	//o3 = new Object;
	o3->type=T_INT;
	o3->value.i = (int)o->value.i >> (int)o2->value.i;	
}

//io

int io_write() {
	prep();
	//printf("io_write:"); displayFormatln(regs[0]); puts(";");
	//display(o);
	if(o->type!=T_STR)
		//throw "substr";
		//printf("%s",to_str(o->value.s);
		display(o);
	else
		printf("%s",o->value.s);
	//puts("");
}

int io_read() {
	Object* o = regs[0];
	char *s = new char[256]; //todo is this necessary to allocate?
	char c;
	int i=0;
	while(c=getc(stdin)) {
		if(c==EOF) {
			break;
		}
		if(c=='\n') {
			break;
		}
		s[i] = c;
		++i;
		if(i==255)
			break;
	}
	s[i] = 0;
	//o2 = new Object; //o2 = o; o2->value.s = s; o2->type = T_STR;
	sets(o, s);
	//unify(regs[0], o2);
	//p_displayln(o);
}

int io_print() {
	//p1("\n===\nio_write: ");
	Object* o = regs[0];
	//printf("%d\n", o);
	//printf("rel %s->%s ;line %d\n", c->prev->e->debug->name, e0->debug->name, e0->debug ? (e0->debug->lines ? e0->debug->lines[0] : 0) : 0);
	displayln(o);
	//printf("===\n");
	//printf(";\n===\n");//p1(";\n===\n");
}

int io_print2() {
	p1("\n===\nio_write: ");
	Object* o = regs[0];
	//printf("%d\n", o);
	//printf("rel %s->%s ;line %d\n", c->prev->e->debug->name, e0->debug->name, e0->debug ? (e0->debug->lines ? e0->debug->lines[0] : 0) : 0);
	displayln(o);
	printf("===\n");
	//printf(";\n===\n");//p1(";\n===\n");
}

//io - file

int open() {
	//pl::fopen(name,mode,f)
	Object* o = regs[0];
	Object* o2 = regs[1];
	Object* o3 = regs[2];
	char* name = o->value.s;
	char* mode = o2->value.s;
	FILE *f = fopen(name, mode);
	//p2("%s,%s\n",name,mode);
	if(f==NULL)
		//valid=false;
		throw "Could not open file;";
	else {
		o3->value.fc = f;
		o3->type = T_FILE;
	}
}

int open_binary() {
	Object* o2 = regs[1];
	char* mode;
	//printf("%s,%s\n",regs[0]->value.s,regs[1]->value.s);
	if(streq(o2->value.s, "write")) {
		mode = "wb";
		news(regs[1], mode);
		//printf("%s\n",regs[1]->value.s);
	}
	else
		throw 0;
	open();
}

int write8() {
	prep2();
	FILE *f = (FILE *)o->value.fc;
	if(f==NULL)
		throw "no file";
	char c = (char)o2->value.i;
	fputc((int)c, f); //todo
}

int write32() {
	prep2();
	FILE *f = (FILE *)o->value.fc;
	int i = o2->value.i;
	fwrite(&i, sizeof(int), 1, f);
}

int fwrite() {
	prep2();
	FILE *f = fopen(o->value.s, "write");
	char *s = o2->value.s;
	int n=strlen(s);
	printf("write %s, %d\n", o->value.s, strlen(s));
	//fwrite(s, sizeof(char), strlen(s), f);
	//char buffer[1024];
	//printf(";%s\n", o2->value.s); printf(";%s\n", to_str(o2));
	fprintf(f, "%s\n", s);
	fclose(f);
	printf("end write %s, %d\n", o->value.s, strlen(s));
	//printf("%s", s);
}

int fileReadAll() {
	// Determine file size
	FILE *f = (FILE *)regs[0]->value.fc;
	fseek(f, 0, SEEK_END);
	size_t size = ftell(f);

	char* where = new char[size];

	rewind(f);
	fread(where, sizeof(char), size, f);
	regs[2]->value.s = where;
	//delete[] where;
}

int readFile() {
	//String String
	prep2();
	char *name = o->value.s;
	FILE *f = fopen(name, "r");
	if(f==NULL) {
		//valid=false;
		throw "Could not read file";
		return 1;
	}
	
	//read whole file
	fseek(f, 0, SEEK_END); // Determine file size
	size_t size = ftell(f);
	char* where = new char[size+1];
	rewind(f);
	fread(where, sizeof(char), size, f);
	fclose(f);
	where[size] = '\0';
	o2->type=T_STR;
	o2->value.s = where;
	//delete[] where;
}

int close() {
	fclose((FILE *)regs[0]->value.fc);
}
	


//math

int math_sqrt() {
	puts("sqrt:");
	Object* o = regs[0];
	Object* o2 = regs[1];
	o2->value.i = sqrt(o->value.i);
	o2->type = T_INT;
}

int math_seed() {
	Object* o = regs[0];
	srand(o->value.i);
}

int math_random() {
	Object* o = regs[0];
	o->value.i = (double)(rand()%RAND_MAX) / RAND_MAX;
	o->type = T_INT;
}

int math_abs() {
	Object* o = regs[0];
	Object* o2 = regs[1];
	o2->value.i = abs(o->value.i);
}

int math_floor() {
	Object* o = regs[0];
	Object* o2 = regs[1];
	o2->value.i = floor(o->value.i);
}

int math_ceil() {
	Object* o = regs[0];
	Object* o2 = regs[1];
	o2->value.i = ceil(o->value.i);
}

int toStr() {
	o = regs[0];
	o2 = regs[1];
	o2->type = T_STR;
	o2->value.s = o->type==T_STR ? o->value.s : to_str(o);
}

int math_sub() {
	Object* o = (regs[0]);
	Object* o2 = (regs[1]);
	Object* o3 = regs[2];
	o3->type = T_INT;
	o3->value.i = o->value.i-o2->value.i;
	//p4("%d - %d = %d\n",o->value.i,o2->value.i,o3->value.i);
}
/*
void _add(Object* o, int i, int y) {
	setr(o3, i+y);
}

void _add(Object* o, int i, double y) {
	setr(o3, o->value.i+o2->value.i);
}
*/
int math_add() {
	prep3();
	seti(o3, o->value.i+o2->value.i);
	p4("%g + %g = %g\n",o->value.i,o2->value.i,o3->value.i);
}

int math_div() {
	prep3();
	seti(o3, o->value.i/o2->value.i);
	//printf("%d<%d\n\n",o->value.i,o2->value.i);
}

int math_mul() {
	prep3();
	seti(o3, o->value.i*o2->value.i);
	//printf("%d<%d\n\n",o->value.i,o2->value.i);
}

int math_ge() {
	prep2();
	if(o->value.i<o2->value.i)
		valid=false;
	//printf("%d,%d\n\n",o->value.i,o2->value.i);
}

int math_gt() {
	prep2();
	if(o->value.i<o2->value.i)
		valid=false;
	//printf("%d,%d\n\n",o->value.i,o2->value.i);
}

int math_le() {
	prep2();
	if(o->value.i>=o2->value.i)
		valid=false;
	printf("%d,%d\n\n",o->value.i,o2->value.i);
}

int math_lt() {
	prep2();
	if(o->value.i>=o2->value.i)
		valid=false;
	//printf("%d<%d\n\n",o->value.i,o2->value.i);
}

//string

int string_le() {
	Object* o = regs[0];
	Object* o2 = regs[1];
	//display(o); printf(" (%d) <= ", o->value.s[0]);
	//display(o2); printf(" (%d)\n", o2->value.s[0]);
	int i=strcmp(o->value.s, o2->value.s);
	p(printf("=> %s\n",(i<=0? "yes" : "no")));
	if(i>0) valid=false;
}


//String Integer
int string_code() {
	prep2();
	if(o2->type == T_REF) {
		o2->value.i = (o->value.s)[0];
		o2->type = T_INT;
	}
	else if(o->type == T_REF){
		o->value.s = new char[2];
		o->value.s[0] = (o2->value.i);
		o->value.s[1] = '\0';
		o->type = T_STR;
	}
	else {
		if((o->value.s)[0]!=(o2->value.i))
			valid=false;
	}
}

int string_substr() {
	Object* o = regs[0];
	if(o->type==T_REF)
		throw "substr";
	int i = regs[1]->value.i;
	int i2 = regs[2]->value.i;
	int j,j2;
	Object* o2 = regs[3];
	char* s = o->value.s;
	char* s2 = new char[i2-i+1];
	j2=0;
	for(j=i;j<i2;++j) {
		s2[j2] = s[j];
		++j2;
	}
	s2[j2] = '\0';
	
	Object* o3 = new Object;
	o3->value.s = s2;//s1.substr(i, i2).c_str();
	o3->type = T_STR;
	
	#ifdef DEBUG
	printf("substr: "); //displayln(o2);//displayFormat(o);
	printf(" #%d\n [%d:%d] = %s;",i2-i,i,i2,s2);
	displayln(o3);
	#endif
	if(o2->type==T_STR) {
		if(!unify(o2, o3)) valid=false;
	}
	else {
		
		if(!unify(o2->value.o, o3)) {printf("valid\n"); valid=false;}
		else {}
	}
}

int stringToInteger() {
	prep2();
	o2->type = T_INT;
	o2->value.i = atoi(o->value.s);
}

//find s2 in s1, starting from index i
//rel findIndex(String s1, String s2, Integer i, Integer pos)
int string_findIndex() {
	Object* o = regs[0];
	Object* o2 = regs[1];
	Object* o3 = regs[2];
	Object* o4 = regs[3];
	o4->type = T_INT;
	
	char *s = o->value.s;
	char *s2 = o2->value.s;
	int i = o3->value.i;
	int j, j0, k, len=strlen(s), len2=strlen(s2);
	//printf("%d < %d\n",i,len);
	for(j=i;j<len;++j) {
		//printf("- %d\n",j);
		j0=j;
		for(k=0;k<len2;++k,++j) {
			if(s2[k] != s[j])
				break;
		}
		if(k>=len2) {
			o4->value.i = j0;
			return 0;
		}
	}
	o4->value.i = -1;
	valid=false;
}

//fun. c=output
int string_at() { //s, i, c
	prep3();
	int i;
	//o3->value.o = new Object;
	char *s = o->value.s;
	i = o2->value.i;
	p3("%d, %d\n",i,strlen(s));
	if(i>=strlen(s)) {
		valid=false;
		return 0;
	}
	Object *o4 = new Object;//o3->value.o;
	char *s2 = new char[2];
	//if(strlen(s)>i) fail();
	char c=o->value.s[(int)o2->value.i];
	//printf("%c;%d\n",c,c);
	s2[0] = o->value.s[(int)o2->value.i];
	s2[1] = '\0';
	o4->value.s = s2;//o->value.s[o2->value.i];
	o4->type = T_STR;
	p(displayFormatln(o4));
	unify(o3->value.o, o4);
}

int string_concat() {
	prep3();
	char *s1 = o->value.s;
	char *s2 = o2->value.s;
	int i, j, len1=strlen(o->value.s), len2=strlen(o2->value.s);
	int len = len1 + len2;
	char *s3 = new char[len + 1];
	strcpy (s3,o->value.s); strcat (s3,o2->value.s);
	/*
	i=0;
	for(j=0;j<len1;++i,++j) {
		s3[i] = s1[j];
	}
	for(j=0;j<len2;++i,++j) {
		s3[i] = s2[j];
	}
	s3[i] = '\0';*/
	Object *o4 = new Object;
	o4->value.s = s3;
	o4->type = T_STR;
	unify(o3->value.o, o4);
	p(printf("s:%s,%s\n",o->value.s,o2->value.s));
	p(printf("s:%s,%d\n",s3,i));
}

int string_size() {
	Object* o = regs[0];
	Object* o2 = regs[1];
	//printf("%d;\n",o2->type==T_INT);
	if(o2->type==T_INT) {
		if(o2->value.i!=strlen(o->value.s))
			valid=false;
		return 0;
	}
	o2->value.i = strlen(o->value.s);
	o2->type = T_INT;
}

int string_slice() {
	string_substr();
}

static int i=0;

int temp() {
	Object* o = regs[0];
	o->value.i = i;
	o->type = T_INT;
}

int string_eq(Object* o, Object* o2) {
	
}

//general

int any_add() {
	prep();
	if(o->type==T_STR) {
		//throw 1;
		string_concat();
	}
	else if(o->type==T_INT)
		math_add();
	else {
		displayFormatln(o);
		throw "math operation with unrecognised value";
	}
}

void rdy() {
	printf("\n--\n");
	//printf("\n");
	info_gc();
	mark();
	printf("regs: [%d, %d, %d]\n",regs[0],regs[1],regs[2]);
	printf("--\n");
	//collect1();
	//collect2();
	collect3();
	printf("cps: ");
	pr_cp();
	//printf("gcs: [%d, %d, %d]\n", gc1.size(), gc2.size(), gc.size());
	info_gc();
	printf("\n");
	unmark();
}

//register libs

typedef struct reg {
	const char *name;
	int (*p)();
} reg;

static const reg nil = {0,0};

reg lib[] = {
	{"print", io_print},
	{"full_print", io_print2},
	{"write", io_write},
	{"read", io_read},
	{"open", open},
	{"fopen_binary", open_binary},
	{"close", close},
	{"readFile", readFile},
	{"write8", write8},
	{"write32", write32},
	{"fwrite", fwrite},
	{"pause", pause},
	{"def", def},
	{"undef", undef},
	{"type", is_int},
	{"del", del},
	{"coll", rdy},
	
	{"sqrt", math_sqrt},
	{"seed", math_seed},
	{"random", math_random},
	{"abs", math_abs},
	{"floor", math_floor},
	{"ceil", math_ceil},
	{"add", any_add},
	{"sub", math_sub},
	{"div", math_div},
	{"mul", math_mul},
	{"le", math_le},
	{"lt", math_lt},
	{"ge", math_ge},
	{"gt", math_gt},
	{"neg", neg},
	{"neq", neq},
	
	{"cut", cut},
	{"break", set},
	{"throw", logic_throw},
	
	{"bit_and", bit_and},
	{"bit_shl", bit_shl},
	{"bit_shr", bit_shr},
	//{"trail", print_trail},	{"info", info},	{"on", on},	{"set", set},
	
	{"s_le", string_le},
	{"code", string_code},
	{"substr", string_substr},
	{"at", string_at},
	{"findIndex", string_findIndex},
	{"slice", string_slice},
	{"size", string_size},
	{"concat", string_concat},
	{"s_to_int", stringToInteger},
	{"stringToNumber", stringToInteger},
	
	{"table_new", table_new},
	{"table_set", table_set},
	{"table_get", table_get},
	
	{"exec", exec},
	{"clock", os_clock},
	{"time", os_time},
	
	{"export", export_c},
	{"arg", arg},
	{"args", get_args},
	{"rec", rec},
	{"eval", eval_file},
	{"apply1", apply1},
	{"apply2", apply2},
	
	//debug
	{"loc", loc},
	{"locs", locs},
	{"reg", get_register},
	{"check", check},
	{"undata", undata},
	{"type", type},
	{"fcget", fc_get},
	{"fcsize", fc_size},
	
	{"require", require},
	{"toString", toStr},
	
	{"getnargs", get_nargs},
	{"getnlocs", get_nlocs},
	{"getfname", get_fname},
	{"getlocal", get_local},
	{"closure", closure},
	{"sethook", sethook},
	nil
};

reg mathlib[] = {
	nil
};


static int libsize (const reg *l) {
  int size = 0;
  for (; l->name; l++) size++;
  return size;
}

int register_lib (const reg *l) {
	for (i=0; i<libsize(l); i++)
		cregister(l[i].name, l[i].p);
}
//

void load_std() {
	//register_lib(mathlib);
	register_lib(lib);
}



