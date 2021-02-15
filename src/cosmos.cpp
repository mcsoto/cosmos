#include "stdio.h"
#include "time.h"
#include "stdint.h"
#include "stdlib.h"
#include "math.h"
#include "string.h"

#include <iostream>
#include <string>
#include <vector>
#include <list>
#include <map>
/*

note: registers 251+ are reserved
251 is sometimes a temp register for object code
252 for require code

*/

char** args;
int arg_n;

typedef unsigned char  u8; //Byte
typedef unsigned short u16; //Word

static bool valid = true;
static bool trace = false;
static bool halt = false;
static bool step = false;

static int t1 = -2;
static int t2 = 0;

static int line = -1;
static int newline = -1;

static int v[3];

static FILE* f;

#define DEBUG_HALT 1 //pauses for input each time there's failure

#ifndef MAXSTACK
#define MAXSTACK 256
#endif
#ifndef MAXVARS
#define MAXVARS 200
#endif

//#define DEBUG 1
	
//#define type(o)		((o)->type)
#define value(o)	((o)->value.i)

#define mem(o)		do {if(o==NULL) throw "out of memory";} while (0)

#define read_int(n, f)	fread(&n, sizeof(int), 1, f)
#define strneq(s,s2) strcmp(s, s2)
#define streq(s,s2) !strcmp(s, s2)

#define	set_i(o,n) ((o)->value.i = n;)

#define setf(o) do { o->type = T_REF; o->value.o = o; } while (0)
	
#define setr(o,V) do { o->type = T_NUM; o->value.r = V; trail_push(o); } while (0)
#define seti(o,V) do { o->type = T_INT; o->value.i = V; trail_push(o); } while (0)
#define sets(o,V) do { o->type = T_STR; o->value.s = V; trail_push(o); } while (0)
	
#define news(o,V) do { o=new Object; o->type = T_STR; o->value.s = V; } while (0)
#define newi(o,V) do { o=new Object; seti(o,V); } while (0)

#define cpy(o,o2) {o->type=o2->type;o->value=2;}

//#define get(t,s,o2) do { o2 = (*t)[s]; } while (0)

	
#ifdef DEBUG
#define dbg() (e0->debug->lines ? e0->debug->lines : 0)
//#define p(X) do { if (DEBUG && !trace && dbg()) X; } while (0)//(DEBUG && !trace ? X : 0)
#define p(X) do { X; } while (0)//(DEBUG && !trace ? X : 0)
#define pf1(X) do { if (DEBUG && !trace) printf(X); } while (0)//(DEBUG && !trace ? X : 0)
#define pf2(X,Y) do { if (DEBUG && !trace) printf(X,Y); } while (0)//(DEBUG && !trace ? X : 0)
#define p1(X) printf(X)
#define p2(X,Y) printf(X,Y)
#define p3(X,Y,Y2) printf(X,Y,Y2)
#define p4(X,Y,Y2,Y3) printf(X,Y,Y2,Y3)
/*
#define p1(X) p(printf(X))
#define p2(X,Y) p(printf(X,Y))
#define pf3(X,Y,Y2) printf(X,Y,Y2)
#define p3(X,Y,Y2) p(printf(X,Y,Y2))
#define p4(X,Y,Y2,Y3) p(printf(X,Y,Y2,Y3))*/
#else
#define dbg() e->debug!=0 && e->debug->lines!=0
#define p(X) 
#define pf1(X)
#define pf2(X,Y)
#define p1(X)
#define p2(X,Y) 
#define p3(X,Y,Y2) 
#define pf3(X,Y,Y2) 
#define p4(X,Y,Y2,Y3) 
#endif

typedef enum
{
	PASS,
	
	ALLOC, DEALLOC,
	
	GET_INT_TEMP, GET_VALUE_TEMP, GET_VAR_TEMP,
	PUT_INT_TEMP, PUT_VALUE_TEMP, PUT_VAR_TEMP, //8
	
	PROCEED, CALL_ONE, CALL,
	TRY_ELSE, RETRY_ELSE, TRUST_ELSE, EXEC,
	HALT,
	
	PUT_CONST, PUT_FUNCTOR, PUT_TABLE, //19
	GET_CONST_TEMP, GET_TABLE,
	CLOSURE, MOVE,
	CALL_C,
	
	PUT_VALUE, PUT_VAR,
	
	GET_INT, GET_CONST, GET_VALUE, GET_VAR, //30
	
	GET_FUNCTOR, FC_INT, FC_CONST, FC_VALUE, FC_VAR,
	
	T_VAR_TEMP, T_CONST, T_VALUE, T_VAR,
	
	OBJ_GET_TEMP, OBJ_PRED,
	CALL_REG, EXEC_REG,
	
	FAIL,
	
	CONT,
	JMP, JMP_IF_TRUE,
	
	LINE, PRINT, NIL,
	
	EQ_VAR, EQ_VAL, //52
	
	OBJ_GET, OBJ_PUT,
	
	GET_OBJ, 
	
	PUT_VOID,
	GET_VOID,
	FC_VOID
	
	/*PUSH, PUSH_NULL,
	POP,
	ADD, SUB,
	OP_LE,	OP_LT, OP_EQ, OP_GT, OP_GE,
	STORE, STORE_0,
	LOAD, LOAD_0*/
	
} Opcode;

typedef enum
{
	T_NULL,
	T_NUM, //unused
	T_INT,
	T_STR,
	T_REL,
	//T_CFUNC, T_BOOL,	T_UNBOUND
	T_FILE,
	T_REF,
	T_DATA,
	T_FUNCTOR
} Type;

void rdy ();

struct Functor;

union Value
{
	//int    i;
	double i;
	double r; //real
	char*  s;
	u8*    f;
	void  (*p)();
	struct Object* o;
	struct Env* e;
	std::map<std::string, struct Object* > *t;
	void *fc;
	void *data;
};

typedef Value Value;

typedef Object Object;

struct Functor
{
	Object** param;
	char* name;
	int n;
	bool flag;
	~Functor() {
		//printf("Value %s#%d ", this->name, this); printf("collected.\n");
	}
};

struct Object
{
	Type  type;
	Value value;
	bool flag;
	~Object() {
		printf("Value %s%d collected.\n", this->type==T_REF ? "#var" : "", this);
	}
};

typedef Functor Functor;

typedef std::map<std::string, Object* > Table;
typedef std::map<const char*, Object* > Map;

typedef struct
{
	char* name;
	Value** names;
	char* src;
	//int n_args;
	Env* proto;
	int line;
	u8* lines;
} Debug;

static char* srcname;

typedef struct
{
	char mode;
	Env* e;
	Env* last;
	int line;
	int line2;
	int line_last;
} CDebug;

static CDebug cgb;

struct Env
{
	//Env* cont_env;
	u8*  insts;
	Object* consts;
	int* upvals;
	int n_args;
	int n_locals;
	int n_upvals;
	Env* upval_env;
	Object* upvalues;
	Debug* debug;
	bool flag;
	int mode;
	//Env** prototypes;
	~Env() {
		printf("Env ");
		printf("collected.\n");
	}
};

struct Closure
{
	Object* locals;
	struct Env *e;
	struct Closure *prev;
	int last;
	int pos;
	int stack;
	int cur_trail;
	struct ChoicePoint *cur_cp;
	int i;
	bool flag;
	~Closure() {
		int n=(this->e->n_locals)+(this->e->n_upvals);
		printf("Closure %s%d ", this->e->debug ? this->e->debug->name : "", this);
		printf("collected. \n", n);
		delete [] this->locals;
	}
};

struct ChoicePoint
{
	Env* e;
	Closure* c;
	u8*  insts;
	ChoicePoint* prev;
	int i;
	int pos;
	Object** regs;
	Object** locs;
	int trail_pos;
	int start;
	int stack;
	bool flag;
};

struct Cont
{
	Cont* prev;
	int i;
};

static int trail_start;

typedef Env Env;
typedef Closure Closure;

typedef struct
{
	Object* o;
} Ref;

static std::list<int> cp_location;

static int ident = 0;
static int pos = 0;
static int stack = -1;

static Env *e0;

static Closure *c;
static Object* null = new Object;

Object* any = new Object;

static std::list<char*> gc0;
static std::vector<Closure*> gc;
static std::list<Object*> gc1;
static std::vector<Functor*> gc2;
static std::vector<char*> gcs;



void prefix() {
	if(stack>25)
		fprintf(f,"(%d) ",stack);
	else
		for(int i=0;i<stack;++i) {fprintf(f,"|"); }
}

//static Object pool_locals[MAXVARS] = {{T_NUM,2},{T_NUM,3},{T_NUM,4}};

#define ALLOC_REGS 256
static Object* regs[ALLOC_REGS]; //hopefully not too much memory to allocate all these regs

static std::vector<Object*> trail;

static Closure *cur_c;

ChoicePoint *cp = NULL, *prev_cp;

Functor* cur_fc;
int i_param;
bool mode_write;

void alloc_inst(FILE *f,u8 *arr, int n) {
	char ch;
	//p1("[ ");
	for(int i=0;i<n;++i) {
		ch = fgetc(f);
		arr[i] = ch;
		//p2("%d ",arr[i]);
	}
	//p1("], ");
}

void print_bc(u8 *bc) {
	for(int i=0;;i++) {
		printf("%d,",bc[i]);
		if(bc[i]==HALT||i>30) break;
	}
}

bool unbound(Object* o) {
	//return o==NULL;
	//return o==any;
	//return o->type==T_UNBOUND;
	return o->value.o==o;
}

Object* deref(Object *o) {
	while(o->type==T_REF && !unbound(o)) {
		o = o->value.o;
	}
	return o;
}

void display(Object*, int);

void displayFormat(Object* o, int layer);
//void displayFormat(File* f, Object* o, int layer);
void fdisplay(FILE *f, Object* o, int layer);

void display(FILE *f, Object* o, int layer) {
	//printf(";%d;%d\n",o,o->type);
	if(o==NULL) fprintf(f,"c::null");
	else
	//if(o==NULL) throw 1;
	//if(o->type==NULL) throw 1;
	if(o->type>20||o->type<0) {
		throw "type unknown";
	}
	if(o->type==T_NUM)
		//fprintf(f,"%g",o->value.r);
		throw "type num";
	else if(o->type==T_INT) {
		//fprintf(f,"%d",o->value.i);
		fprintf(f,"%g",o->value.i);
	}
	else if(o->type==T_STR) {
		//fprintf(f,"'%s'",o->value.s);
		#ifdef DEBUG
		if(strlen(o->value.s)>40) {
			fprintf(f,"str#");
			//return;
		}
		#endif
		fprintf(f,"\"%s\"",o->value.s);
	}
	else if(o->type==T_REL) {
		p(if(o->value.e->debug) fprintf(f,"%s", (char*)o->value.e->debug->name););
		//fprintf(f,"#rel%d",(int)o->value.e / 100);
		fprintf(f,"#rel%d", o->value.e);
		/*printf("(");
		print_bc(o->value.e->insts);
		printf(")");*/
	}
	else if(o->type==T_NULL)
		fprintf(f,"null");
	else if(o->type==T_DATA) {
		fprintf(f,"#data");
	}/*
	else if(o->type==T_OBJ) {
		//printf("{}");
		//print_map(o->value.t);
		if(layer>4) {
			fprintf(f,"...");
			return;
		}
		fprintf(f,"data#{");
		Table* t = o->value.t;
		for (Table::iterator it=t->begin(); it!=t->end(); ++it) {
			if(it!=t->begin()) std::cout << ", ";
			std::cout << it->first;// << " = ";
			fprintf(f,":");
			display(f,it->second, layer+1);
		}
		fprintf(f,"}");
	}*/
	else if(o->type==T_FUNCTOR) {
		Functor* fc = (Functor*)o->value.fc;
		//if(layer>4) { printf("..."); return; }
		int layer2=layer+1, i=0;/**/
		if(streq(fc->name,"Cons")) {
			fprintf(f,"[");
			if(fc->n!=0) {
				//if(fc->param[0]==NULL) fprintf(f,"_"); else display(fc->param[0]);
				while(fc->n!=0) {
					//fprintf(f,";%d;%d\n",fc->param,i);
					if(fc->param[0]==NULL) fprintf(f,"_");
					else displayFormat(fc->param[0], layer2);
					if(fc->param[1]==NULL) break;
					if(deref(fc->param[1])->type==T_REF) {
						fprintf(f," | "); displayFormat(fc->param[1], layer2);//fprintf(f,"_");
						break;
					}
					if(deref(fc->param[1])->type!=T_FUNCTOR) {
						fprintf(f,";%d\n",fc->param[1]->type);
						displayFormat(fc->param[1], layer2);
						throw "tail of a list is not a list.";
					}
					fc = (Functor*)deref(fc->param[1])->value.fc;
					//fprintf(f," #%d;%d\n",fc);
					if(fc->n!=0) fprintf(f,", ");
					//if(i>8) { fprintf(f,"..."); break; }
					i++;
				}
			}
			fprintf(f,"]");
			//p2("#%d",fc->n);
		}
		else if(streq(fc->name,"T")) {
			fprintf(f,"{");
			if(layer>4) { fprintf(f,"..."); return; }
			if(fc->n<3&&fc->n!=0)
				throw "incorrect number of parameters for T";
			while(fc->n!=0) {
				if(fc->param[0]==NULL) {
					fprintf(f,"_");
					break;
				} else {
					displayFormat(fc->param[0], layer2); fprintf(f,": "); displayFormat(fc->param[1], layer2);
				}
				fc = (Functor*)fc->param[2]->value.fc;
				//fprintf(f," #%d;%d\n",fc);
				if(fc->n!=0) fprintf(f,", ");
			}
			fprintf(f,"}");
		}
		else {
			fprintf(f,"%s",fc->name);
			if(fc->n!=0) {
				fprintf(f,"(");
				for(int i=0;i<fc->n;++i) {
					if(i!=0) fprintf(f,", ");
					if(fc->param[i]==NULL) fprintf(f,"_");
					else {
						displayFormat(fc->param[i], layer2);
						//displayFormat(f,fc->param[i], layer2);
						//fdisplay(f,fc->param[i], layer2);
						//fprintf(f,"\n");
					}
				}
				fprintf(f,")");
			}
		}
	}
	else if(o->type==T_REF) {
		if(unbound(o)) {
			fprintf(f,"#var");
			fprintf(f,"%u",o);
			//p2("%d",o);
		}
		else {
			#if DEBUG
			fprintf(f,"#var");
			p(fprintf(f,"%d",o));
			fprintf(f," = ");
			#endif
			display(f,o->value.o, layer);
		}
	}
	else if(o->type==T_NULL)
		fprintf(f,"null");
	else if(o->type==T_FILE)
		fprintf(f,"#file");
	else {
		printf("??? (%d)\n",o->type);
		throw "???";
	}
}

void display(Object* o, int layer) {
	FILE *f=stdout;
	display(f,o,layer);
}

void display(Object* o) {
	display(o, 0);
}
/*
void displayFormat(File* f, Object* o, int i) {
	fdisplay(f,o);
}
*/
void displayFormat(Object* o, int i) {
	if(o==NULL)
		//throw "null";
		return "null";
	if(o->type==T_STR) {
		char *s = o->value.s;
		printf("'");
		for(int i=0;i<strlen(s);++i) {
			if(i>80) {
				printf("...");
				break;
			}
			if(s[i]=='\n')
				printf("\\n");
			else if(s[i]=='\t')
				printf("\\t");
			else if(s[i]=='\r')
				printf("\\r");
			else if(s[i]=='\'')
				printf("\\'");
			else
				putchar(s[i]);
		}
		printf("'");
	}
	else {
		display(o, i);
	}
}

void displayFormatln(Object* o, int i) {
	displayFormat(o,i);
	printf("\n");
}

void displayFormat(Object* o) {
	displayFormat(o,0);
}

void displayFormatln(Object* o) {
	displayFormatln(o,0);
}

void displayln(Object* o) {
	display(o);
	printf("\n");
}

void fdisplay(FILE *f, Object* o, int layer) {
	//printf(";%d;%d\n",o,o->type);
	//else if(o->type==T_REF)
		//printf("#val");
	if(o==NULL) fprintf(f,"null");
	else
	//if(o==NULL) throw 1;
	//if(o->type==NULL) throw 1;
	if(o->type>20||o->type<0) {
		throw "type unknown";
	}
	else if(o->type==T_NUM)
		//fprintf(f,"%g",o->value.r);
		throw "type num";
	else if(o->type==T_INT) {
		//fprintf(f,"%d",o->value.i);
		fprintf(f,"%g",o->value.i);
	}
	else if(o->type==T_STR) {
		//fprintf(f,"'%s'",o->value.s);
		#ifdef DEBUG
		if(strlen(o->value.s)>40) {
			fprintf(f,"str#");
			//return;
		}
		#endif
		fprintf(f,"\"%s\"",o->value.s);
	}
	else if(o->type==T_REL) {
		p(if(o->value.e->debug) fprintf(f,"%s", (char*)o->value.e->debug->name););
		fprintf(f,"#rel%d", o->value.e);
	}
	else if(o->type==T_NULL)
		fprintf(f,"null");
	else if(o->type==T_DATA) {
		fprintf(f,"#data");
	}
	else if(o->type==T_FUNCTOR) {
		//fprintf(f,"fc#");
		Functor* fc = (Functor*)o->value.fc;
		fprintf(f,"%s",fc->name);/*
		if(fc->n!=0) {
			fprintf(f,"(");
			for(int i=0;i<fc->n;++i) {
				if(i!=0) fprintf(f,", ");
				if(fc->param[i]==NULL) fprintf(f,"_");
				else fdisplay(f, fc->param[i], 0);
			}
			fprintf(f,")");
		}*/
	}
	else if(o->type==T_REF) {
		if(unbound(o)) {
			fprintf(f,"#var");
			fprintf(f,"%u",o);
			//p2("%d",o);
		}
		else {
			#if DEBUG
			fprintf(f,"#var");
			p(fprintf(f,"%d",o));
			fprintf(f," = ");
			#endif
			display(f, o->value.o, layer);
		}
	}
	else if(o->type==T_NULL)
		fprintf(f,"null");
	else if(o->type==T_FILE)
		fprintf(f,"#file");
	else {
		printf("??? (%d)\n",o->type);
		throw "???";
	}
}

char* to_str(Object* o) {
	char *s;
	int i;
	//printf("= "); displayFormatln(o, 1);
	//printf("%d;%d;",o->type,T_FUNCTOR);
	//return "...";
	if(o->type==T_FUNCTOR) {
		return "fc#";((Functor*)(o->value.fc))->name;//(o->value.fc)->name;//"#fc";
		s = new char[60];
		mem(s);
		sprintf(s,"fc#%s",((Functor*)(o->value.fc))->name);
		s=new char[1024];
		mem(s);
		gc0.push_back(s);
		if(s==NULL) throw "no memory";
		Functor* fc = (Functor*)o->value.fc;
		//displayln(o);
		if(streq(fc->name,"Cons")) {
			strcpy(s,"[");
			/*
			if(fc->n!=0) {
				//if(fc->param[0]==NULL) printf("_"); else display(fc->param[0]);
				while(fc->n!=0) {
					if(fc->param[0]==NULL) printf("_"); else displayFormat(fc->param[0], layer2);
					if(fc->param[1]==NULL) break;
					if(fc->param[1]->type==T_REF) {
						printf(" | "); displayFormat(fc->param[1], layer2);//printf("_");
						break;
					}
					fc = (Functor*)fc->param[1]->value.fc;
					//printf(" #%d;%d\n",fc);
					if(fc->n!=0) printf(", ");
				}
			}*/
			if(fc->n!=0) {
				while(fc->n!=0) {
					//displayln(fc->param[0]);
					//if(fc->param[0]==NULL) strcat(s,"_"); else strcat(s,to_str(fc->param[0]));
					//printf("\n");
					//if(i>10) { strcat(s,"..."); break; }
					i++;
					if(fc->param[0]==NULL)
						strcat(s,"_");
					else {
						strcat(s,to_str(fc->param[0]));//displayFormat(fc->param[0], layer2);
						//printf("%s, %d\n", to_str(fc->param[0]), strlen(s));
					}
					if(fc->param[1]==NULL) break;
					
					if(deref(fc->param[1])->type != T_FUNCTOR) {
						strcat(s,", ");
						strcat(s,to_str(fc->param[1]));
						//printf("last: %s, %d\n", to_str(fc->param[1]), strlen(s));
						printf("last: ");
						displayFormatln(fc->param[1]);
						printf("%d,%d: %d\n", fc->param[1]->type, T_FUNCTOR, fc->param[1]->type != T_FUNCTOR);
						break;
					}
					else {
						fc = (Functor*)deref(fc->param[1])->value.fc;
						if(fc->n!=0) strcat(s,", ");
					}
				}
			}
			//strcat(s,"...");
			strcat(s,"]");
		}
		else {
			strcpy(s,fc->name);
			if(fc->n!=0) {
				strcat(s,"(");
				for(int i=0;i<fc->n;++i) {
					if(i!=0) strcat(s,", ");
					if(fc->param[i]==NULL) strcat(s,"_");
					else strcat(s,to_str(fc->param[i]));
				}
				strcat(s,")");
			}
		}
		//sprintf(s2,s);
		return s;
	}
	//not a functor
	s = new char[60];
	mem(s);
	gc0.push_back(s);
	if(!s)
		throw 22;
	if(o->type==T_NUM) {
		//printf("str;%f\n",o->value.r);
		sprintf(s,"%f",o->value.r);
		throw "type num";
	}
	else if(o->type==T_INT)
		sprintf(s,"%f",o->value.i);
	else if(o->type==T_STR) {
		//sprintf(s,"'%s'",o->value.s);
		#ifdef DEBUG
		//return "...";
		return "str#";
		#endif
		char *s1 = o->value.s;
		sprintf(s,"'");
		int size=strlen(s1);
		int i,j;
		//printf("size:%d\n",size);
		for(i=0,j=1;i<50&&s1[i]!='\0';++i,j+=2) {
			if(s1[i]=='\n') {
				s[j]='\\';
				s[j+1]='n';
			}
			else if(s1[i]=='\t') {
				s[j]='\\';
				s[j+1]='t';
			}
			else if(s1[i]=='\r') {
				s[j]='\\';
				s[j+1]='r';
			}
			//else if(s1[i]=='\'')
				//s[i+1]='\'';
			else if(s1[i]=='\0') {
				break;
			}
			else {
				s[j]=s1[i];
				j--;
			}
		}
		//sprintf(s,"'");
		if(size>50) for(j++;j<i+4;j++) s[j]='.';
		else 1;
		s[j]='\'';
		s[j+1]='\0';
	}
	else if(o->type==T_REL) {
		sprintf(s,"#rel%d",(int)o->value.e / 100);
		/*printf("(");
		print_bc(o->value.e->insts);
		printf(")");*/
	}
	else if(o->type==T_NULL)
		strcpy(s,"null");
	else if(o->type==T_DATA) {
		sprintf(s,"#data");
	}
	else if(o->type==T_REF) {
		printf(s,"#var%d\n",o);
		if(unbound(o)) {
			sprintf(s,"#var%d",o);
			//p(sprintf(s,"%d",o));
		}
		else {
			p(sprintf(s,"%d",o));
			sprintf(s,"#var%d = %s", o, to_str(o->value.o));
			//sprintf(s, to_str(o->value.o));
		}
	}
	else if(o->type==T_NULL)
		sprintf(s,"null");
	else if(o->type==T_FILE)
		sprintf(s,"#file");
	else {
		sprintf(s,"??? (%d)\n",o->type);
		throw "???";
	}
	return s;
}

void display_cp(ChoicePoint* cp) {
	printf("cp{");
	printf("%d, %s, #%d",cp->i, cp->e->debug ? cp->e->debug->name : "", cp->pos);
	printf("}");
}

void display_cpln(ChoicePoint* cp) {
	display_cp(cp);
	printf("\n");
}

//

Object* get(Table* t, Object* o) {
	//printf("get\n"); displayFormatln(o);
	return (*t)[o->value.s];
}

Object* get_throw(Table* t, Object* o) {
	auto it = (*t).find(o->value.s);
	if(it==t->end()) throw "value not found in object";
	return it->second;
}

Table* set(Table* t, Object* o, Object* o2) {
	(*t)[o->value.s] = o2;
	return t;
}

Object* check_rel(Object *o2) {
	if(o2->type==T_REL) {
		Env *e = o2->value.e;
		if(e->n_upvals > 0) {
			//p2("upvals: %d\n",e->n_upvals);
			e->upvalues = new Object[e->n_upvals];
			mem(e->upvalues);
			for(int i=0;i<e->n_upvals;++i) {
				e->upvalues[i] = c->locals[e->upvals[i]];
				#ifdef DEBUG
				//printf("i=y%d; ",e->upvals[i]);
				//displayFormatln(&e->upvalues[i]);
				#endif
			}
			//p1("\n");
		}
	}
}

char* env_name(Env *e0) {
	return e0->debug!=NULL ? e0->debug->name : "";
}

void pr_header(Env *e0) {
	if(e0->debug!=NULL) {
		printf("%s", e0->debug!=NULL ? e0->debug->name : "");
		printf("(");
		for(int i=0;i<e0->n_args;++i) {
			if(i!=0) printf(", ");
			displayFormat(deref(regs[i]));
		}
		if(e0->mode==2)
			printf(") in %s\n",e0->debug->src);
		else
			printf(")\n");
		printf("[");
		for(int i=0;i<e0->n_upvals;++i) {
			if(i!=0) printf(", ");
			//displayFormat(deref(regs[i+e0->n_args]));
			displayFormat(&c->locals[i+e0->n_locals]);
		}
		printf("] locs:%d\n", e0->n_locals+e0->n_upvals);
	}
}

//vm utils

void pr_trace(FILE* f, Env *e0) {
	if(e0->debug!=NULL) {
		/*
		fprintf(f,"%s\n", e0->debug!=NULL ? e0->debug->name : "");*/
		fprintf(f,"%s", e0->debug!=NULL ? e0->debug->name : "");
		fprintf(f,"(");
		char *s;
		for(int i=0;i<e0->n_args;++i) {
			//printf("- %i\n",i);
			if(i!=0) fprintf(f,", ");
			//s=to_str(deref(regs[i]));
			fdisplay(f,deref(regs[i]),0);
			//fprintf(f,"%s",s);
		}
		fprintf(f,")\n");
	}
}

void pr_trail() {
	Object* o;
	printf("trail: [");
	for(int i=0;i<trail.size();++i) {
		o = trail[i];
		display(o); printf(", ");
	}
	printf("]\n");
}

void pr_cp() {
	//display current cp
	ChoicePoint *cur=cp;
	int i=0;
	while(cur!=NULL) {
		if(i>5) {
			printf(" ...\n");
			return;
		}
		display_cp(cur);
		printf(" -> ");
		cur = cur->prev;
		i++;
	}
	printf("null\n");
}
/*
void pr_locs(Closure* c, int n) {
	Object* o;
	printf("locs: [");
	for(int i=0;i<n;++i) {
		//printf("%d : ",i); printf("%d\n",c->locals[i]);
		if(&c->locals[i]) {
			o = deref(&c->locals[i]);
			if(o->type==T_REF) {
				printf("...");
				break;
			}
			displayFormat(o);
			printf(", ");
		}
	}
	printf("]\n");
}
*/
void display_args(Closure* c) {
	Object* o;
	int n=c->e->n_args;
	for(int i=0;i<n;++i) {
		//printf("%d : ",i); printf("%d\n",c->locals[i]);
		if(&c->locals[i]) {
			o = deref(&c->locals[i]);
			displayFormat(o);
			if(i<n) printf(", ");
		}
	}
}

void pr_locs(Closure* c) {
	Object* o;
	printf("locs: %d [", c->e->n_locals);
	for(int i=0;i<c->e->n_locals;++i) {
		//printf("%d : ",i); printf("%d\n",c->locals[i]);
		if(&c->locals[i]) {
			o = deref(&c->locals[i]);
			displayFormat(o);
			printf(", ");
			if(o->type==T_REF) {
				printf("...");
				break;
			}
		}
	}
	printf("]\n");
}

void pr_cl(Closure *c) {
	Closure *c0=c;	int i=0;
	while(c0!=NULL) {
		if(i>20) {
			printf(" ... ");
			break;
		}
		printf("%s -> ",c0->e->debug->name, c->i);
		//pr_locs(c0);
		c0 = c0->prev;i++;
	}
	printf("null;\n");
}

void pr_cl2(Closure *c) {
	Closure *c0=c;
	while(c0!=NULL) {
		printf("%s(",c0->e->debug->name, c->i);
		display_args(c0);
		printf(") ... \n");
		c0 = c0->prev;
	}
	printf("null;\n");
}

void pr_regs() {
	printf("regs: [");
	display(regs[0]); printf(", "); display(regs[1]); printf(", "); display(regs[2]);
	printf("]\n");
}


void trail_push(Object* o) {
	trail.push_back(o);
}

void print_locals(Env* e0, Closure* c) {
	printf("locals: ",e0->n_locals);
	for(int i=e0->n_locals;i<e0->n_locals;++i) {
		display(&c->locals[i]); printf(", ");
	}
	printf("\n");
}

//

bool unify(Object *o, Object *o2) {
	#if DEBUG
	//printf(""); displayFormat(o); printf(" = "); displayFormat(o2); printf("\n"); //printf(", ");
	#endif
	if(o2->type==T_REF) {
		Object* o3 = o;
		o = o2;
		o2 = o3;
	}
	
	if(o->type==T_REF) {
		//printf("%d,%d;\n",o, o->value.o);
		if(unbound(o)) {
			//o = new Object;
			o->value.o = o2;
			if(cp!=NULL) {
				//pf1("added\n"); displayln(o);
				trail_push(o);
			}
			#if DEBUG
			//p1("(unbound)\n");
			//displayln(o);
			#endif
		}
		else 
			return unify(deref(o), o2);
	}
	else {
		if(o->type!=o2->type)
			return false; //needed for general comparisons
	
		if(o->type==T_STR) {
			if(strcmp(o->value.s, o2->value.s)) return false;			
		}
		else if(o->type==T_FUNCTOR) {
			Functor* fc = (Functor*)o->value.fc;
			Functor* fc2 = (Functor*)o2->value.fc;
			
			if(fc->n!=fc2->n) return false;
			if(strneq(fc->name, fc2->name)) {return false;}
			//cur_fc = fc;
			
			for(int i=0;i<fc->n;++i) {
				if(!unify(fc->param[i], fc2->param[i])) return false;
			}
		}/*
		else if(o->type==T_REL) {
			#if DEBUG
			printf(" ... ");
			displayFormatln(o);
			#endif
			throw "comparison between relations (likely unintended)";
		}*/
		else if(o->value.i != o2->value.i) {
			#if DEBUG
			//display(o); printf(", "); display(o2); printf(", ");
			//printf("(false)\n");
			#endif
			return false;
		}
	}
	#if DEBUG
	//puts("");
	#endif
	return true;
}

void print(Object* o) {
	printf("(%d,%d)",o->value.i, o->type);
}

//

Functor* cons() {
	Functor* fc = new Functor();fc->n=2;fc->name="Cons";
	return fc;
}

void clist_to_list() {
	
}

Object* clist_to_fc(Object* args[], int n) {
	//
	Functor* fc = new Functor();
	fc->n=n;fc->name="F";
	fc->param = new Object*[n];
	//
	Object* o = new Object;
	o->value.fc=fc;
	o->type=T_FUNCTOR;
	for(int i=0;i<n;i++) {
		fc->param[i] = args[i];//new Object;
		displayFormatln(args[i]);
		//unify(fc->param[i], args[i]);
	}
	return o;
}

//

static Object* hook1 = null;

//void (Closure*) eval;
//Closure (*eval)();

Closure* eval(void);
Closure* co_execute(void);

static Closure* saved_c;

void call(Object* o) {
	printf("hook1\n");
	Env* e = e0;
	Closure *prev=c;
	saved_c=c;
	Object* temp=hook1;
	hook1=null;
	e0 = o->value.e;
	//
	Object* o2 = new Object;
	Object* temp1 = regs[0],* temp2 = regs[1],* temp3 = regs[2];
	o2->type=T_DATA;
	o2->value.data=prev;
	o2=clist_to_fc(regs,prev->e->n_args);
	displayFormatln(o2);
	regs[0] = o2;
	//
	co_execute();
	hook1=temp;
	regs[0]=temp1;
	regs[1]=temp2;
	regs[2]=temp3;//todo
	//delete o;
	//eval();
	e0=e;c=prev;
}

void hookcall() {
	if(hook1->type==T_REL) {
		call(hook1);
	}
}

//libs

static std::map<const char*, std::map<const char*, int(*)() > > libs;
static std::map<std::string, int(*)() > core;
//static std::map<void*, Debug* > symbol;

static Table *cur_t = NULL;

void cregister(std::string s, int (*p)()) {
	core[s] = p;
}

//vm helpers

void save_regs(int n) {
	p1("regs: [");
	for(int i=0;i<n;++i) {
		cp->regs[i] = regs[i];
		p(display(regs[i]); printf(", "););
	}
	p1("]\n");
}

void copy_regs(ChoicePoint* cp0, int n) {
	p1("regs: [");
	for(int i=0;i<n;++i) {
		regs[i] = deref(cp->regs[i]);
		p(display(regs[i]); printf(", "););
	}
	p1("]\n");
}

void save_locs(ChoicePoint* cp, Closure* c, int n) {
	//p1("saving locals: [");
	Value v;
	//v.i = 1;
	//Object* o2 = new Object; o2->value = v; o2->type = T_INT;
	for(int i=0;i<n;++i) {
		cp->locs[i] = new Object;
		cp->locs[i] = &c->locals[i];
		//p(displayFormat(cp->locs[i]); p1(", "););
	}
	//p2("]#%d\n\n",n);
}

void copy_locs(ChoicePoint* cp, Closure* c) {
	Object* o;
	//pf2("%d\n",cp->e->n_locals);
	p1("copying locals: [");
	for(int i=0;i<cp->e->n_locals;++i) {
		//reset locals (re-perform the get_vars)
		o = deref(cp->locs[i]);
		//displayln(o);
		c->locals[i].value = o->value; c->locals[i].type = o->type;
		#ifdef DEBUG
		display(&c->locals[i]); printf(", ");
		#endif
	}
	p1("]\n\n");
}

void collect0() {
	printf("\n---\nsize2:%d\n",gc0.size());
	char* o;
	std::list<char*>::iterator it;
	it=gc0.begin();
	while(it!=gc0.end()) {
		o=*it;
		it = gc0.erase(it);
		delete o;
	}
	printf("size2:%d\n",gc0.size());
}

//sets the lib
Object* get(std::map<const char*, Object* > &m, const char* s) {
	return m[s];
}

void set(std::map<const char*, Object* > &m, const char* s, Object* o) {
	m[s] = o;
}

void set1(std::map<const char*, Object* > &m, const char* s, Object* o) {
	m[s] = o;
}
/*
void set1(std::map<const char*, Object* > &m, std::string& s, Object* o) {
	//m[s] = o;
}*/

typedef std::map<const char*, Env* > Lib;

Env* get2(Lib &m, const char* s) {
	return m[s];
}

void set2(Lib &m, const char* s, Env* o) {
	m[s] = o;
}

//static Lib req;
static Table req;

int info();

int to_int32(u8* bc, int i) {
	int n,n2,n3,n4;
	int j;
	n = bc[++i]; n2 = bc[++i]<<8; n3 = bc[++i]<<16; n4 = bc[++i]<<24;
	j=n4 + n3 + n2 + n;
	//printf("[%d,%d,%d,%d=%d]\n",n,n2,n3,n4,j);
	return j;
}

int to_int16(u8* bc, int i) {
	int n,n2;
	int j;
	n = bc[++i]; n2 = bc[++i]<<8;
	j=n2 + n;
	return j;
}

#define i32(bc,i,j) do { j=to_int32(bc,i); i+=4; } while (0)
#define i16(bc,i,j) do { j=to_int16(bc,i); i+=2; } while (0)
	
/*
	While this requires no arguments, it assumes e0 is setup.
	A new closure, c, is made based on the content of e0.
	Arguments must also be setup, though it's usually done within bytecode.
*/
int last=0;

Closure* co_execute() {
	Env *e;
	Closure *c0 = NULL;
	goto main;
	
main:
	trail_start = trail.size();
	Object *o, *o2;
	ChoicePoint *cur, *cp0;
	Cont* cur_cont;
	Cont* cont = NULL;
	Functor *fc;
	char ch;
	//set up new env and closure
	u8* bc = e0->insts;
	c = new Closure;
	cur_c=c;
	c->locals = new Object[e0->n_locals+e0->n_upvals];
	mem(c->locals);
	c->e = e0;
	c->pos = ++ident;
	c->cur_trail = trail.size();
	c->cur_cp = cp;
	c->last = last;
	#ifdef DEBUG
	printf("new closure ;%d(y%du%d)%d\n", c, e0->n_locals, e0->n_upvals, e0->debug);
	//printf("%s\n", e0->debug!=NULL ? e0->debug->name : "");
	#endif
	//if(e0->n_upvals>250)
	//if(true)
		//return;
	gc.push_back(c);
	//call event
	++stack;
	if(trace)
		info();
	c->prev=c0;
	//set to null
	for(int i=0;i<e0->n_locals;++i) {
		c->locals[i].flag = 0; //= NULL;
		//gc1.push_back(&c->locals[i]);
		c->locals[i].type = T_NULL; //necessary for gc?
	}
	//gc debug
	//printf("%d\n", gc.size());
	//if(gc0.size()>100)
	//if(gc.size()>41000||gc0.size()>500) {	printf("gcs: [%d, %d, %d]. [%d]\n", gc.size(), gc1.size(), gc2.size(), gc0.size());	//throw "stack overflow"; }
	#ifdef DEBUG
	//new line event
	if(newline!=line) {
		
	}
	//trace
	long i3=gc2.size();
	if(i3>10000) {
		cur_c = c;
		//mark();
		
	}
	#endif
	if(e0->mode==2) {
		//prefix(); pr_trace(f, e0);
	}
	Value *v;
	u8 w;
	u8 *p = bc,*p2;
	int i,i2,n,n2,n3,n4;
	int j,r;
	//set upval
	if(e0->n_upvals > 0) {
		p2("upvals %d: ",e0->n_upvals);
		for(i=e0->n_locals,i2=0;i2<e0->n_upvals;++i,++i2) {
			c->locals[i] = e0->upvalues[i2];
			p3("\n(y%d=up%d) ",i,i2); p(display(&c->locals[i]));// printf(", ");
		}
		p("\n");
	}
	hookcall();
	#ifdef DEBUG
	p(printf("\n---------------\n"));
	if(e0->debug!=NULL) {
		pr_header(e0);
		printf("\n");
		//trace
	}
	//symbol[c] = (void*)new Debug;
	//print_consts(e0);
	#endif
	Table *t;
	goto vm0;
fail:
	//debug
	if(e0->mode==2)	{
		//prefix(); fprintf(f,"x\n");//fprintf(f,"false\n");
	}
	#ifdef DEBUG
	printf("\n"); printf("false\n");
	//display current cp
	printf("\n");
	pr_cp(); //pr_cl(c);
	//printf("locals: ");
	pr_locs(c);
	#endif
	//printf("\nsize: %d\n",gc0.size());
	//if(gc0.size()>100) { printf("\n\n\n\n\n\n\n\n\n\n\n\n==collect0: "); //collect0(); }
	//
	if(cp==NULL) {
		#ifdef DEBUG
		//pr_trail(); printf(" #%d\n", trail.size());
		#endif
		//throw "false, end";
		//printf("| false\n");
		return 0;
	}
	else {
fail1:
		stack=cp->stack;
		#ifdef DEBUG
		//pr_trail(); p1(" trail"); printf(" #%d, i:%d\n", trail.size(), cp->trail_pos);
		#endif
		//remove all env after point
		if(cp->pos>c->pos) {//nondet call
			//printf("nondet\n");
		}
		else {
			
		}
		//resets top of heap and stack
		//unwinds trail
		p4("ident: %d;#%d, i:%d\n",(ident),cp->trail_pos,trail.size());
		for(int i=trail.size()-1;i >= cp->trail_pos;--i) {
			//pf2("(%d) ",i);
			o = trail[i];
			trail.pop_back();
			o->type = T_REF;
			o->value.o = o;
		}
		//reset cregisters
		cp0=cp;
		c0=cp->c;
		//int n2=cp->e->n_args, n3=cp->e->n_locals;
				
		//recovers env
		e0 = cp->e;
		c = cp->c;
		bc = e0->insts;
		i = cp->i;
		//
		#if DEBUG_HALT == 1
		if(halt) {
			//printf("\n"); printf("Please input;"); if(getchar()=='a') return;
		}
		#endif
		goto vm;
	}
succ:
	//printf("%d\n",e0->insts);
	bc = e0->insts;
	++i;
	goto vm;
vm0:
	for(i=0;;i++) {
vm:
		#ifdef DEBUG
		//if(stack>100) throw "stack overflow";
		//printf("-%d; %s\ti:%d\n",bc[i], e0->debug ? e0->debug->name : "", i); //(int)e0 / 100
		#endif
		cgb.line = e0->debug ? (e0->debug->lines ? e0->debug->lines[i] : -1) : -1;
		if(cgb.line==-1||cgb.line==cgb.line_last) {
			
		}
		else {
			if(e0->debug) {//&&e0->debug->src)
				//printf("line %d in %s\n", (e0->debug->lines ? e0->debug->lines[i] : 0),e0->debug->src? e0->debug->src : "??",cgb.line_last);
				cgb.line_last = cgb.line;
			}
			//printf("mode:%c;%d\n",cgb.mode,cgb.line);
			if(cgb.mode=='s') {
				if(cgb.last==e0) {
					step=true;
				}
			}
			else if(cgb.mode=='n') {
				printf("line %d<-%d;%i;%d;%d\n", cgb.line, cgb.line2,e0,cgb.last);
				if(cgb.line!=cgb.line2)//||e0!=cgb.last)
					step=true;
			}
			if(step) {//&&(cgb.line>cgb.line2)
				printf("line %d;%s %i;%d\n", e0->debug ? (e0->debug->lines ? e0->debug->lines[i] : -1) : -1, e0->debug->name, i, e0->debug);
				printf("\n"); printf("> ");
				ch=getchar();
				//cgb.mode=ch;
				if(ch=='\n'||ch=='\r') ch=cgb.mode;
				if(ch=='a') return c;
				else if(ch=='c') { cgb.mode='c'; printf("-----------\n");step=false; }
				else if(ch=='s') { //skip over function
					cgb.last=e0;
					cgb.mode='s';
					step=false;
				}
				else {
					step=false;
					cgb.mode='n';
					printf("mode:%c;%d\n",cgb.mode,cgb.line);
				}
				//printf(";%d;%d,%d,%d;\n",(int)ch,(int)'\r',(int)'\n',cgb.mode);
				cgb.line2=cgb.line;
				cgb.last=e0;
				printf("line=%d\n", cgb.line2);
			}
		}
		//printf("-%d; %s\ti:%d\n",bc[i], e0->debug ? e0->debug->name : "", i);
		//if(bc[i]==-1||bc[i]==255) throw 3;
		if(t1>i&&t2==0) {
			printf("--\ntest gc %d at %d\n", t1, i);
			t2=1;
			rdy();
		}
		switch(bc[i]) {
		case PASS:
			p1("pass\n");
			break;
			
		case CALL:
			n = bc[++i];
			o = deref(&(c->locals[n]));
			c->i=i;last=i;
			//run
			e0 = o->value.e;
			if(o->type!=T_REL) {
				p3("call y(%d) %d\n", n, &(c->locals[n]));
				printf("call y(%d) ", n, &(c->locals[n]));
				displayFormatln(o);
				throw "trying to call value that is not a relation";
			}
			p3("call y(%d) %s\n", n, e0->debug!=NULL?e0->debug->name:"");
			c0 = c;
			//prev = c;
			goto main;
			break;
			
		case CALL_REG:
			n = bc[++i];
			o = regs[n];
			p2("call %d\n", n);
			//run
			c->i=i;last=i; e0 = o->value.e; c0 = c;
			goto main;
			break;
			
		//'put' ...
		case PUT_CONST:
			//puts const value into a register
			i16(bc,i,n); n2 = bc[++i];
			o = &e0->consts[n];
			p3("put_const:c(%d),%d; ",n,n2);
			p(displayFormatln(o));
			regs[n2] = o;
			break;
		case PUT_VALUE:
			//puts value of variable into a cregister
			i16(bc,i,n); n2 = bc[++i];
			o = deref(&c->locals[n]);
			regs[n2] = o;
			#ifdef DEBUG
			printf("put_val:y(%d),%d; ",n, n2);
			displayFormatln(o);
			#endif
			break;
		case PUT_VAR:
			//creates a variable on the heap and assigns to cregister
			i16(bc,i,n); n2 = bc[++i];
			//o = any;
			o = &c->locals[n];
			o->type = T_REF;
			o->value.o = o;
			regs[n2] = o;
			p4("put_var:y(%d),%d; ",n,n2,i);//; i:%d
			p(displayFormatln(deref(o)));
			break;
		case PUT_VOID:
			i16(bc,i,n); n2 = bc[++i];
			p2("put_void:%d\n", n2);
			o = new Object;
			o->type = T_REF;
			o->value.o = o;
			regs[n2] = o;
			break;
			
		//'get' unifies (compares) a cregister with a variable or constant
		case GET_CONST:
			//puts const value into a cregister
			n = bc[++i]; n2 = bc[++i];
			o = deref(regs[n2]); p3("get_const:c(%d),%d\n",n,n2);
			if(!unify(o, &e0->consts[n])) goto fail;
			//optimize into instruction later
			o2 = &e0->consts[n];
			check_rel(o2);throw 0;
			break;
		case GET_VALUE:
			//get value from Ai and compare it to Vn
			i16(bc,i,n); n2 = bc[++i];
			p3("get_val:y(%d),%d; ",n,n2); o = deref(&c->locals[n]);
			p(displayFormatln(o));
			o2 = regs[n2];
			//printf("%d\n",e0->n_locals); displayln(o); displayln(o2);
			if(!unify(o2, o)) goto fail;
			break;
		case GET_VAR:
			//get value from Ai and stores it in Vn
			i16(bc,i,n); n2 = bc[++i];// i16(bc,i,n2);
			o = deref(&c->locals[n]); setf(o); //if it's null, set it to var
			o2 = regs[n2];
			p3("get_var:y(%d),%d; ",n,n2);
			p(displayFormatln(o2));
			if(!unify(o2, o)) goto fail;
			break;
			
		case EQ_VAR:
			//creates a variable on the heap and assigns to cregister 0
			i16(bc,i,n); i16(bc,i,n2);
			//o = any;
			o = &c->locals[n];
			o->type = T_REF;
			o->value.o = o;
			o2 = &e0->consts[n2];
			p4("eq_var:y(%d),c(%d),i:%d; ",n,n2,i);
			p(displayFormatln(o));
			p(displayFormatln(o2));
			if(!unify(o, &e0->consts[n2])) goto fail;
			//optimize into instruction later
			check_rel(o2);
			break;
			
		case EQ_VAL:
			//puts value of variable into a cregister
			i16(bc,i,n); i16(bc,i,n2);
			o = deref(&c->locals[n]);
			p3("eq_val:y(%d),c(%d); ",n,n2);
			o2 = &e0->consts[n2];
			p(displayFormatln(o));
			p(displayFormatln(o2));
			
			#ifdef DEBUG
			//p(displayFormat(o)); p1(' = ');
			//p(displayFormatln(o2));
			#endif
			if(!unify(o, &e0->consts[n2])) goto fail;
			//optimize into instruction later
			check_rel(o2);
			break;
			
		case OBJ_GET_TEMP:
			i16(bc,i,n); n2 = bc[++i];
			p3("obj_get:y(%d);%d\n",n,n2);
			o = &(c->locals[n]); //gets object from locals
			o2 = regs[251]; //gets constant from Ai
			o = deref(o);
			if(o->type!=T_DATA) {
				p1("null\n");
				displayFormatln(o);
				displayFormatln(o2);
				throw "Value doesn't have type Object.";
			}
			t = o->value.t;
			p2("o.%s = ",o2->value.s);
			if(t==NULL) {
				throw "Object is null.";
			}
			o2 = get(t,o2);
			if(o2==NULL) {
				//displayFormatln(o);
				printf("o.%s not found\n",o2->value.s);
				throw "Object doesn't have property.";
			}
			p(displayFormatln(o2));
			regs[n2] = o2; //constant now gets object property
			break;
			
		case OBJ_GET:
		/*	i16(bc,i,n); i16(bc,i,n2);i16(bc,i,n3);//n2 = bc[++i]; n3 = bc[++i];
			p4("obj_get:y(%d),c(%d),y(%d)\n",n,n2,n3);
			o = deref(&(c->locals[n])); //gets object from locals
			o2 = &e0->consts[n2]; //gets constant
			//if(o->type==T_DATA) {//check if it's a c/stl or runtime object
			t = o->value.t;
			//}
			p2("o.%s = ",o2->value.s);
			o2 = get(t,o2);
			if(o2==NULL) {
				p1("null\n");
				throw "CosmosRuntimeError: Object doesn't have property.";
			}
			p(displayFormatln(o2));
			//regs[n3] = o2;*/
			throw 32;
			c->locals[n3] = *o2;
			break;
			
		case GET_FUNCTOR:
			//puts functor value n1 of size n3 into a register n2
			n = bc[++i]; n2 = bc[++i]; n3 = bc[++i];
			//p(printf("get_f:c(%d),%d,%d; %s#%d\n",n,n2,n3,(&e0->consts[n])->value.s,n3));
			o = deref(regs[n2]);
			p(printf("%s#%d\n",(&e0->consts[n])->value.s,n3));
			i_param = 0;
			if(o->type==T_REF) {
				mode_write = true;
				fc = new Functor;
				fc->flag = 0;
				o2 = new Object;
				gc1.push_back(o2);
				o2->flag = 0;
				gc2.push_back(fc);
				o2->value.fc = fc;
				o2->type = T_FUNCTOR;
				//set functor
				fc->n = n3;
				fc->param = new Object*[n3];
				if(n==251) fc->name = "#fc"; else fc->name = (&e0->consts[n])->value.s;//&(&e0->consts[n])->value;//&(&e0->consts[n])->value; //o4->value.s
				//#ifdef DEBUG
				for(int i=0;i<fc->n;++i) {
					fc->param[i] = NULL;
				}
				//#endif
				if(!unify(o, o2)) goto fail;
			}
			else {
				//comparing to another functor is 'read' or 'compare' mode
				if(o->type!=T_FUNCTOR) goto fail;
				fc = (Functor*)o->value.fc;
				if(fc->n!=n3) goto fail;
				if(strneq(fc->name,(&e0->consts[n])->value.s)) goto fail;
				mode_write = false;
			}
			cur_fc = fc;
			break;
			
		case FC_VAR:
			i16(bc,i,n);
			if(mode_write) {	
				o = &c->locals[n]; //todo hack? shouldn't need to make new ref for _ to work //fixed in void
				o->type = T_REF;
				o->value.o = o;
				p4("fc[%d] <- new y(%d) #var%d\n",i_param, n, o);
				cur_fc->param[i_param] = o;//&c->locals[n];
				i_param++;
			}
			else {
				p(printf("fc[%d] = new y(%d)\n",i_param, n));
				o = &c->locals[n];
				o->type = T_REF;
				o->value.o = o;
				o2 = cur_fc->param[i_param];
				if(!unify(o, o2))
					goto fail;
				i_param++;
			}
			break;
			
		case FC_VOID:
			i16(bc,i,n);
			if(mode_write) {	
				o = new Object;//&c->locals[n]; //todo hack? shouldn't need to make new ref for _ to work
				o->type = T_REF;
				o->value.o = o;
				p4("fc[%d] <- new void y(%d) #var%d\n",i_param, n, o);
				cur_fc->param[i_param] = o;//&c->locals[n];
				i_param++;
			}
			else {
				p3("fc[%d] = void y(%d)\n",i_param, n);
				i_param++;
			}
			break;
			
		case FC_VALUE:
			i16(bc,i,n);
			if(mode_write) {
				p4("fc[%d] <- y(%d) ",i_param,n,&c->locals[n]);
				cur_fc->param[i_param] = deref(&c->locals[n]);
				p(displayFormatln(cur_fc->param[i_param]));
			}
			else {
				o = cur_fc->param[i_param];
				o2 = deref(&c->locals[n]); //todo should this need deref?
				//display(o); printf(" = "); displayln(o2);
				p3("fc[%d] = y(%d)\n",i_param,n);
				//p(display(o)); pf1(", "); p(displayln(o2));
				if(!unify(o2, o)) //todo invert order?
					goto fail;
			}
			//display(&c->locals[n]); printf(", ");
			i_param++;
			//p(if(i_param>=cur_fc->n) p1("\n"));
			break;
			
		case FC_CONST:
			//n = bc[++i];
			i16(bc,i,n);
			//p2("fc_const:",n);
			if(mode_write) {
				p3("fc[%d] <- c(%d) ",i_param, n);
				cur_fc->param[i_param] = &e0->consts[n];
				p(displayln(cur_fc->param[i_param]));
			}
			else {
				p3("fc[%d] = c(%d) ",i_param, n);
				o=cur_fc->param[i_param];
				o2=&e0->consts[n];
				//display(o); printf(" = "); displayln(o2);
				p(displayln(o2));
				if(!unify(o2, o))
					goto fail;
			}
			i_param++;
			//p(if(i_param>=cur_fc->n) p1("\n"));
			break;
		
		case TRY_ELSE:
			i32(bc,i,n);
			prev_cp = cp;
			cp = new ChoicePoint;
			if(e0->debug==NULL)
				throw "args";
			n2=e0->n_args;
			cp->regs = new Object*[n2];
			if(cp->regs==NULL)
				throw "memory";
			cp->locs = new Object*[e0->n_locals];
			if(cp->regs==NULL||cp->locs==NULL)
				throw "memory";
			//save cregisters
			cp->e = e0;
			cp->c = c;
			cp->insts = e0->insts;
			cp->prev = prev_cp;
			cp->i = n; //next clause
			cp->pos = ++ident;
			//trail pointer
			cp->trail_pos = trail.size();
			cp->start = trail_start;
			cp->stack = stack;
			//heap pointer
			p(printf("\n{try %d, %s, %d, trail: %d;%d}\n",n, cp->e->debug ? cp->e->debug->name : "", cp->pos, cp->trail_pos,c->e->mode));
			save_regs(n2);
			save_locs(cp, c, e0->n_locals);
			break;
			
		case RETRY_ELSE:
			i32(bc,i,n);
			cp->i = n;
			p3("\n{retry %s, %d}\n", e0->debug ? e0->debug->name : "", n);
			//copy_locs(cp0,c);
			//printf("\n"); printf("Please input;"); if(getchar()=='a') return;
			break;
			
		case TRUST_ELSE:
			cp = cp->prev; //ident--;
			p3("\n{trust %s;%d}\n", e0->debug ? e0->debug->name : "",c->e->mode);
			//copy_locs(cp0,c);
			break;
			
		case OBJ_PUT:
			i16(bc,i,n); n2 = bc[++i]; n3 = bc[++i];
			p4("put_get:y(%d),c(%d),%d\n",n,n2,n3);
			o = &(c->locals[n]); //gets object from locals
			o2 = &e0->consts[n2]; //gets constant
			p(displayln(o));
			if(o->type==T_DATA) {
				t = o->value.t;
			}
			else {
				t = (o->value.o)->value.t;
			}
			p2("o.%s = ",o2->value.s);
			o2 = get(t,o2);
			if(o2==NULL) {
				printf("null\n");
				throw "CosmosRuntimeError: Object doesn't have property.";
			}
			p(displayln(o2));
			regs[n3] = o2;
			break;
			
		case GET_OBJ:
			//puts functor value of size n3 into a register n2
			n = bc[++i]; n2 = bc[++i]; n3 = bc[++i];
			p4("get_obj:c(%d),%d,%d\n",n,n2,n3);
			throw "object opcode not done";
			//
			o = deref(regs[n2]);
			i_param = 0;
			if(o->type==T_REF) {
				mode_write = true;
				fc = new Functor;
				//throw 12;
				o2 = new Object;
				o2->value.fc = fc;
				o2->type = T_FUNCTOR;
				//set functor
				fc->n = n3;
				fc->param = new Object*[n3];
				//printf("name:%s\n",&(&e0->consts[n])->value);
				fc->name = NULL;//(&e0->consts[n])->value.s;//&(&e0->consts[n])->value; //o4->value.s
				//#ifdef DEBUG
				for(int i=0;i<fc->n;++i) {
					fc->param[i] = NULL;
				}
				//#endif
				//todo null 3
				if(!unify(o, o2)) goto fail;
				//p(printf("write\n",n));
			}
			else {
				//comparing to another function is 'read' mode
				if(o->type!=T_FUNCTOR) goto fail;
				fc = (Functor*)o->value.fc;
				p(displayln(o));
				if(fc->n!=n3) goto fail;
				mode_write = false; //is a functor, go to read mode
				//p(printf("read\n",n));
			}
			cur_fc = fc;
			p(printf("\n"));
			break;
			
		case PROCEED: //unnecessary?
			//i=i2;
			printf("proceed\n");
			break;
			
		case CONT:
			n = bc[++i];
			cont = new Cont;
			cont->prev = cur_cont;
			cont->i = n;
			printf("continue\n");
			break;
			
		case CALL_C:
			n = bc[++i];
			o = &(e0->consts[n]);
			int j2;
			p3("call_c:c(%d),%s\n",n,o->value.s);
			if(streq(o->value.s, "arg")) {
				p1("args\n"); p2("%d\n",arg_n);
			}
			else if(streq(o->value.s, "require")) {
				//printf("--i:%d;%d\n",i,!strcmp(o->value.s, "require"));
				j2=i;
			}
			else if(streq(o->value.s, "halt")) {
				//printf("halt\n");
				return c;
			}
			//calling c function
			int (*fn2)();
			fn2 = core[o->value.s];//core_get(o->value.s);//
			if(!fn2) {
				printf("C-function: %s\n",o->value.s);
				throw "C-function doesn't exist";
			}
			fn2();
			if(!valid) {valid = true; goto fail;}
			if(streq(o->value.s, "require")) {
				i=j2;
			}
			break;
			
		case JMP:
			i2=i;
			p(printf("[%d,%d,%d,%d..]\n",bc[i],bc[i+1],bc[i+2],bc[i+3]));
			i32(bc,i,j);
			p3("jmp:%d->%d\n",i,j);
			i=j;
			//return;
			goto vm;
			break;
			
		case JMP_IF_TRUE:
			i++;
			w = bc[i];
			printf("jmpON:%d\n",w);
			break;
			
		case FAIL:
			p1("false;\n\n");
			goto fail;
			break;
			
		case HALT:
			p1("\nhalt"); stack--;
			i=c->last;
			//pr_cl(c);
			//??
			//delete[] c->locals;//[c->e->n_locals+c->e->n_upvals];
			//go to prev closure and env
			c0=c;
			c=c->prev;cur_c=c;
			if(e0->debug) {
				p2(":%s", e0->debug->name);
				p2(" in %s\n", e0->debug->src);
			}
			if(c==NULL) {
				return c0;
			}
			e0=c->e;//c->i;
			ident--;
			p2(" -> %s\n", e0->debug ? e0->debug->name : "");
			goto succ;
			break;
		case 99:
			printf("test\n");
			break;
        default:
            printf("error unknown opcode %d\n",bc[i]);
			printf("%d,%d,%d,%d,%d,%d,%d,%d,%d\n",bc[i-4],bc[i-3],bc[i-2],bc[i-1],bc[i],bc[i+1],bc[i+2],bc[i+3],bc[i+4]);
            return c;
		}
	}
}

void pr_pool(int size, Object* consts) {
	printf("pool: [");
	for(int i=0;i<size;++i) {
		display(&consts[i]);
		printf(",");
	}
	printf("]\n");
}

Env* read_fn(FILE* f) {
	Object *consts;
	u8 *arr;
	Env *e = new Env;
	mem(e);
	char ch;
	int i;
	int n,n2,nc;
	int size;
	
	//number of consts
	read_int(n,f);
	//printf("consts: %d,\n",n);
	consts = new Object[n];
	mem(consts);
	nc=n;
	
	//...
	Object* c;
	for(i=0;i<n;++i) {
		ch = fgetc(f);
		//printf("(%x) ",ch);break; //todo check if it is a language file
		c = &(consts[i]);
		if (ch==0) {
			c->type = T_NULL;
			//do nothing
		}
		else if (ch==1) {
			consts->type = T_NUM;
			//consts->value.d = d;
			throw "type num";
		}
		else if (ch==2) {
			c->type = T_INT;
			read_int(n2,f);
			//printf("int:%d\n",n2);
			c->value.i = n2;
		}
		else if (ch==3) {
			c->type = T_STR;
			
			fread(&size, sizeof(int), 1, f);
			
			char *s2 = new char[size];//(char*)malloc(sizeof(char) * size);
			mem(s2);
			fread(s2, sizeof(char), size, f); //fgetc(f);
			c->value.s = s2;
			//printf("str:%s (size:%d;%d)\n",c->value.s, strlen(c->value.s), size);
			
		}
		else if (ch==4) {
			p1("rel: {");
			c->type = T_REL;
			c->value.e = read_fn(f);
			c->value.e->upval_env = e;
			p1("} ");
		}
		else
			n2 = fgetc(f);
	}
	//pr_pool(n, consts);
	
	e->consts = consts;
	
	//number of locals
	read_int(n,f);
	p2("l: %d, ",n);
	e->n_locals = n;
	
	//number of upvalues
	ch = fgetc(f);
	p2("u: %d, ",ch);
	n = (int)ch;
	e->n_upvals = n;//e->upvalues = new Object[n];
	
	//...
	e->upvals = new int[n];
	
	for(i=0;i<n;++i) {
		read_int(n2,f);
		//p2("(upval:%d)\n",n2);
		e->upvals[i] = n2;
		//e->upvalues[i] = consts[e->upvals[i]];
	}
	
	p2("c: %d, ",nc);
	//read insts
	//n = (int)fgetc(f); //n of instructions
	read_int(n,f);
	//p2("insts: %d\n",n);
	arr = new u8[n];//(u8 *)malloc(sizeof(u8)*n);
	mem(arr);
	e->insts = arr;
	alloc_inst(f,e->insts,n);
	
	//read debug info
	Debug* d;
	int debug=(int)fgetc(f);
	e->mode=0;
	if(debug==1) {
		d = new Debug;
		e->debug = d;
		//size, name, n_args
		fread(&size, sizeof(int), 1, f);
		d->name = new char[size];
		fread(d->name, sizeof(char), size, f);
		fread(&e->n_args, sizeof(int), 1, f);
		//e->n_args=d->n_args;
		p3("name: %s#%d ",d->name,e->n_args);
		//p2("name: %d\n",d->name[0]);
		d->lines = NULL;
		d->src = NULL;
	}
	else if(debug==0) {
		printf("debug=0\n");
		e->debug = NULL;
		fread(&e->n_args, sizeof(int), 1, f);
	}
	else {
		p1("debug=2 ");
		d = new Debug;
		e->debug = d;
		//size, name, n_args
		fread(&size, sizeof(int), 1, f);
		d->name = new char[size];
		d->name[size] = '\0';
		fread(d->name, sizeof(char), size, f);
		fread(&e->n_args, sizeof(int), 1, f);
		//e->n_args=d->n_args;
		p3("name: %s#%d ",d->name,e->n_args);
		//printf("name: %s;%d#%d ",d->name,strlen(d->name),e->n_args);
		//line info
		u8 *arr2 = new u8[n];
		mem(n);
		d->lines = arr2;
		p2("file: %s",srcname);
		d->src=new char[strlen(srcname) + 1];//srcname;
		strcpy(d->src,srcname);
		//printf("file: %s.%s\n",srcname,d->src);
		alloc_inst(f,d->lines,n);
		e->mode=2;
	}
	return e;
}

char* concat(char* s,char* s2) {
	int len1=strlen(s), len2=strlen(s2);
	int len = len1 + len2;
	char* s3 = new char[len + 1];
	strcpy (s3,s);
	strcat (s3,s2);
	return s3;
}

Env *read_file(char* fname) {
	char ch;
	char* s;
	int i;
	int n;
	Env *e0 = NULL;
	
	FILE *f = fopen(fname, "rb");
	
	if(f==NULL) {
		//printf("Could not open file: %s\n",fname);
		s = concat(fname,".bc"); //todo
		f = fopen(s, "rb");
		if(f==NULL) {
			printf("Could not open file: %s[2]\n",s);
			throw "Could not open file;;";
			//return e0;
		}
	}
	//printf("Opened file: %s,%d\n",fname,f);
	
	srcname=fname;
	e0 = read_fn(f);//e0 = read_fn(f,"_"); //(Object *)malloc(sizeof(Object)*n);
	fclose(f);
	//printf("\nClosed file: %s\n",fname);
	return e0;
}

FILE *open_file(const char* fname) {
	char* s;
	Env *e0 = NULL;
	
	FILE *f = fopen(fname, "rb");
	s=fname;
	if(f==NULL) {
		s = concat(fname,".bc");
		f = fopen(s, "rb");
		if(f==NULL) {
			printf("Could not open file: %s[1]\n",fname);
			throw "Could not open file;";
		}
	}
	srcname=s;//fname;
	return f;
}

Env *read_file_(FILE * f) {
	//printf("Opened file: %s\n[",srcname);	
	e0 = read_fn(f); //(Object *)malloc(sizeof(Object)*n);
	fclose(f);
	//printf("]\nClosed file: %s\n",srcname);
	return e0;
}

//gc

int c_size(Closure *c) {
	return c->e->n_locals+c->e->n_upvals;
}

void mark_obj(Object* o);

void mark_fc(Functor *fc) {
	fc->flag = 1;
	printf("mark fc %d\n", fc);
	for(int i=0;i<fc->n;++i) {
		//if(fc->param[i]->type==T_FUNCTOR)
		//printf(" mark %d\n", fc->param[i]);
		mark_obj(fc->param[i]);
		//fc->param[i]->flag = 1;
	}
	
}

void mark_obj(Object *o) {
	if(o->flag==1)
		return;
	if(o->type==T_FUNCTOR) {
		o->flag = 1;
		printf("mark fc %d; %d\n",o, ((Functor*)(o->value.fc)));
		mark_fc(((Functor*)(o->value.fc)));
	}
	else if(o->type==T_REF) {
		o->flag = 1;
		printf("mark #%d\n",o);
		mark_obj(o->value.o);
	}
	else if(o->type==T_REL) {
		o->flag = 1;
		printf("mark rel ");
		displayFormatln(o);
		//mark_obj(o->value.o);
	}
	else {
		printf("mark value %d ",o);
		displayFormatln(o);
		o->flag = 1;
	}
}

void mark_c(Closure *c) {
	if(c==NULL) return;
	//if(c->flag==1) return;
	Object*o;
	if(c->flag==0) {
		printf("mark closure %s%d, #%d\n", c->e->debug->name, c, c_size(c));
		c->flag = 1;
		int size=c_size(c);
		for(int i=0;i<size;++i) {
			o=&c->locals[i];
			if(o!=NULL) {
				printf("Object %d: ", i);
				displayFormatln(o);
				mark_obj(o);
			}
		}
		//printf("\n");
		mark_c(c->prev);
	}
}

void mark_cp(ChoicePoint *c) {
	printf("-%d\n",c);/*
	if(c!=NULL) {
		int size=c_size(c);
		for(int i=0;i<size;++i) {
			mark_obj(&c->locals[i]);
		}
		c->flag = 1;
		mark_cp(c->prev);
	}*/
}

void mark() {
	//mark objects accessible by current closure with flag=1
	//closure, env, prevs....
	Closure *c = cur_c;
	printf("mark closure %d\n", c);
	mark_c(c);
	
	printf("--\ntrail: %d\n",trail.size());
	Object *o;
	//trail
	for(int i=0;i<trail.size();++i) {
		o = trail[i];
		mark_obj(o);
	}
}


void unmark_obj(Object *o) {
	if(o->flag==0)
		return;
	if(o->type==T_FUNCTOR) {
		o->flag = 0;
		mark_fc(((Functor*)(o->value.fc)));
	}
	else if(o->type==T_REF) {
		o->flag = 0;
		unmark_obj(o->value.o);
	}
	else if(o->type==T_REL) {
		o->flag = 0;
		unmark_obj(o->value.o);
	}
	else {
		o->flag = 0;
	}
}

void unmark_c(Closure *c) {
	if(c==NULL) return;
	//if(c->flag==1) return;
	Object *o;
	//printf("mark closure %s%d, #%d\n", c->e->debug->name, c, c_size(c));
	c->flag = 0;
	int size=c_size(c);
	for(int i=0;i<size;++i) {
		o=&c->locals[i];
		unmark_obj(o);
	}
	//unmark_c(c->prev);
}

void unmark() {
	//mark objects back to flag=0
	printf("--\n");
	//env, prevs....
	//closures	
	Closure *c;
	Object *o;
	std::vector<Closure*>::iterator it; //closure
	it=gc.begin();
	while(it!=gc.end()) {
		c=*it;
		printf("-%d\n", c);
		unmark_c(c);
		++it;
	}
	
	//trail
	printf("--\ntrail: %d\n",trail.size());
	for(int i=0;i<trail.size();++i) {
		o = trail[i];
		o->flag=0;
	}
}

bool collectable(Closure *o) {
	Closure *c = o;
	if(o->flag==0) { //collect
		int size=c_size(o);
		//printf("; %d\n",size);
		for(int i=0;i<size;++i) {
			if((&o->locals[i])->flag==1)
				return false;
		}
		return true;
	}
	return false;
}

void collect3() {
	Closure *o, *o2;
	//printf("\n---\nsize:%d\n",gc.size());
	std::vector<Closure*>::iterator it; //closure
	it=gc.begin();
	while(it!=gc.end()) {
		o=*it;
		//printf("%d\n",o);
		if(collectable(o)) { //collect
			it = gc.erase(it);
			delete o;
		}
		else {
			printf("skip %d\n",o);
			it++;
		}
	}
	printf("size:%d\n",gc.size());
	//getchar();
}

void collect() {
	Closure *c;
	//for(int i=0;i<gc.size(); i++)
	while(gc.size()>0) {
		c=gc.back();
		gc.pop_back();
		delete c;
	}
}

void collect1() {
	Object *o, *o2;
	std::list<Object*> *gc = &gc1;
	std::list<Object*>::iterator it;
	printf("\n---\nsize:%d\n",gc->size());
	printf("size:%d\n",gc1.size());
	it=gc->end();
	o=gc->back();
	it=gc->begin();
	while(it!=gc->end()) {
		o=*it;
		if(/*o->type!=T_FUNCTOR&&o->type!=T_FILE&&*/o->flag==0) { //collect
			if(o->type==T_REF||o->type==T_FUNCTOR) {
				//printf("-%d\n",o);
				//displayFormatln(o);
				it = gc->erase(it);
				delete o;
			}
			else{
				//displayFormatln(o);
				//printf("skip %d\n",o);
				it++;
				//throw 1;
				//break;
			}
		}
		else {
			it++;
			printf("skip %d!\n",o);
		}
		
		//break;
	}
	printf("size:%d\n",gc->size());
	//printf("size:%d\n",gc->size());
	//delete gc;
}

void collect2() {
	printf("\n---\nsize2:%d\n",gc2.size());
	Functor* o;
	std::vector<Functor*>::iterator it;
	it=gc2.begin();
	while(it!=gc2.end()) {
		o=*it;
		if(o->flag==0) { //collect
			it = gc2.erase(it);
			delete o;
		}
		else {
			printf("skip %d\n",o);
			it++;
			//throw 2;
			//break;
		}
		//break;
	}
	printf("size2:%d\n",gc2.size());
}
void error() {
		//printf("... %d\n", cur_c);
		if(cur_c) {
			printf("... in %s at %s\n", cur_c->e->debug->name, cur_c->e->debug->src);
			pr_cl(cur_c);
		}
		//#ifdef DEBUG
		fclose(f);
		//#endif
}

Closure* eval() {
	Closure* c;
	try {
		c = co_execute();
	}
	catch (Object* o) {
		//printf("\nline %d in %s\n", cgb.line_last,e0->debug->src? e0->debug->src : "??");
		printf("\nCosmosRuntimeError: ");
		displayln(o);
		error();
		return 0;
	}
	catch (const char* s) {
		printf("\nCosmosRuntimeError: %s\n",s);
		error();
		return 0;
	} catch (int i) {
		printf("\nCosmosRuntimeError2: %d:\n",i);
		//printf("... in %s:%s;%d\n", cur_c->e->debug->name,cur_c->e->debug->src,cur_c->e->mode);
		error();
		//pr_cl(cur_c);
		return 0;
	} catch (...) {
		printf("\nCosmosRuntimeError: error found.\n");
		error();
		return 0;
	}
	//printf("c;%d\n",c);
	return c;
}

#include "libs.cpp"

void start() {
		
	null->type=T_NULL;
	srand(time(NULL));
	
	regs[252] = null;
	
	cgb.mode='c';
	cgb.line2=-1;
	cgb.last=NULL;
	
	load_std();
	
	//place x,y in cregisters
	any->type = T_NULL;	
	regs[0] = any;
	regs[1] = any;
	regs[2] = any;
	regs[3] = any;
	regs[4] = any;
	
}

void end() {
	//printf("end\n");
	//printf("%d\n",libsize(lib));
	/*
	Object *o, *o1;
	Table*t = new Table;
	set(t,var("s"),var("s"));
	displayFormatln(get(t,var("s")));
	get(t,var("s2"));*/
	//printf("%d\n", i);
}