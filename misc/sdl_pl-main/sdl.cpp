//#include <SWI-Prolog.h>
#include <SWI-cpp.h>
#include <stdio.h>
#include <SDL.h>
#include <SDL_image.h>

SDL_Window* gWindow = NULL;
SDL_Surface* gSurface = NULL;
SDL_Renderer* gRenderer = NULL;
SDL_Texture* gTexture = NULL;

int SCREEN_WIDTH = 640;
int SCREEN_HEIGHT = 480;
int START_TIME = 0;

struct pair
{
	SDL_Surface* s;
	SDL_Texture* t;
};
typedef struct pair pair;

pair* gpair=NULL;

#include "setup.cpp"

PREDICATE (exit,0){
	SDL_DestroyWindow( gWindow );
	gWindow = NULL;

	SDL_Quit();
	IMG_Quit();
	return true;
	//PL_succeed;
}
 




















module_t m = PL_new_module(PL_new_atom("user"));
term_t goal=PL_new_term_ref();
term_t exception=PL_new_term_ref();

void write(term_t a) {
	!(PL_cons_functor(goal, PL_new_functor(PL_new_atom("writeln"), 1), a));	PL_call(goal,m);
}
void update(term_t a1,term_t a2) {
	!PL_put_term(a1, a2);
	!PL_put_variable(a2);
}
bool events(term_t &a1,term_t &a2) {
	SDL_Event e;
	term_t a0=PL_new_term_ref(),arg2=PL_new_term_ref();
	bool quit=false;
	term_t a=PL_new_term_ref();
	PL_put_atom_chars(exception,"error: event could not be called");
	//Handle events on queue
	while( SDL_PollEvent( &e ) != 0 )
	{
		//printf("%d,%d\n",e,&e);
		if( e.type == SDL_QUIT )
		{
			quit = true;
		}
		else if( e.type == SDL_KEYDOWN )
		{
			int key=e.key.keysym.sym;
			const char* s=SDL_GetKeyName(key);
			if(PL_put_string_chars(a0, s)&&PL_cons_functor(goal, PL_new_functor(PL_new_atom("keyDown"), 3), a0,a1,a2)&&PL_call(goal,m))
				0;
			update(a1,a2);
		}
		else if( e.type == SDL_MOUSEBUTTONUP )
		{
			int x, y;
			SDL_GetMouseState( &x, &y );
			if(PL_put_integer(a0, x)&&PL_put_integer(arg2, y)&&PL_cons_functor(goal, PL_new_functor(PL_new_atom("mouseUp"), 4), a0,arg2,a1,a2)){
				//printf("e:\n");	!(PL_cons_functor(a, PL_new_functor(PL_new_atom("writeln"), 1), goal));	PL_call(a,m);
				if(!PL_call(goal,m)){
					//PL_raise_exception(exception);
					write(exception);
					!(PL_cons_functor(a, PL_new_functor(PL_new_atom("halt"), 0), goal)); PL_call(a,m);
				}
			}
			else {
				throw(1);
			} 



			update(a1,a2);
		}
	}
	return quit;
}
PREDICATE (startDt,1) {
	SDL_Event e;
	int start=SDL_GetTicks();
	int dt=start,t0=dt,t1;
	term_t a0=PL_new_term_ref(),a1=A1,a2=PL_new_term_ref();
	bool quit=false;
	while( !quit )
	{
		//process events
		quit=events(a1,a2);	
		//loop
		t1=SDL_GetTicks();
		dt=t1-t0; t0=t1;
		!PL_put_integer(a0,dt);
		if(!(PL_cons_functor(goal, PL_new_functor(PL_new_atom("update"), 3), a0,a1,a2)&&PL_call(goal,m))) {
			printf("error: 'update' predicate failure\n");
			term_t exception=PL_new_term_ref();
			PL_put_atom_chars(exception,"error: update function failure");
			PL_raise_exception(exception);
			PL_fail;
		}
		!PL_put_term(a1, a2);
		!PL_put_variable(a2);
		SDL_Delay(1);
	}
	PL_succeed;
}
PREDICATE (sdl_start,2) {
	SDL_Event e;
	int count=0;
	bool quit=false;
	term_t a1=A2,a2=PL_new_term_ref(),prev=a1;
	term_t exception=PL_new_term_ref();
	PL_put_atom_chars(exception,"error: update function failure");
	int start=SDL_GetTicks();
	int dt=start,t0=dt,t1;
	int timer=50;
	int total=0;
	module_t m = PL_new_module(PL_new_atom("user"));
	!PL_get_integer(A1, &timer);
	while( !quit )
	{
		//process events
		quit=events(a1,a2);	
		//loop
		t1=SDL_GetTicks();
		dt=t1-t0; t0=t1;
		total+=dt;
		if(total>timer) {
			//printf("update;%d,%d\n",timer,total);
			total-=timer;
			if(!(PL_cons_functor(goal, PL_new_functor(PL_new_atom("update"), 2), a1,a2)&&PL_call(goal,m))) {
				printf("error: 'update' predicate failure\n");
				PL_raise_exception(exception);
				PL_fail;
			}
			update(a1,a2);
			//quit=true;//break;
		}
		SDL_Delay(1);
	}
	PL_succeed;
}
PREDICATE (init,2) {
	SCREEN_WIDTH=(int)A1;
	SCREEN_HEIGHT=(int)A2;
	return init();
	PL_succeed;
}
PREDICATE (init,0) {
	return init();
	PL_succeed;
}
PREDICATE (loadImage,2) {
	char *s;
	PL_get_chars(A1,&s,CVT_STRING)||printf("error\n");
	SDL_Surface* loadedSurface = IMG_Load( s );
	if( loadedSurface == NULL )	{
		printf( "Unable to load image %s! SDL Error: %s\n", s, SDL_GetError() );
		PL_fail;
	}
	SDL_Texture* newTexture = SDL_CreateTextureFromSurface( gRenderer, loadedSurface );
	if( newTexture == NULL ) {
		printf( "Unable to create texture from %s! SDL Error: %s\n", s, SDL_GetError() );
		PL_fail;
	}
	//SDL_FreeSurface( loadedSurface );
	pair *p1=new pair;
	gpair=p1;
	p1->s=loadedSurface;
	p1->t=newTexture;
	void *p=p1;
	//printf("p;%d;\n",p);printf("l;%d;%d;%d\n",loadedSurface,newTexture,loadedSurface->w);
	term_t a=PL_new_term_ref();
	PL_put_pointer(a, p);
	return PL_unify(A2, a);
}
PREDICATE (drawImage,3) {
	void *p;
	pair *p1;
	int i,x,y;
	!PL_get_pointer(A1,&p);
	!PL_get_integer(A2,&x);
	!PL_get_integer(A3,&y);
	p1=(pair*)p;
	SDL_Surface* s=p1->s;
	SDL_Texture* t=p1->t;
	//
	//printf("p;%d;\n",p);printf("d;%d;%d;(%d;%d;%d;%d;)\n",s,t,s->w,s->h,x,y); 
	SDL_Rect renderQuad = { x, y, s->w, s->h };
	SDL_RenderCopy( gRenderer, t, NULL, &renderQuad );
	PL_succeed;
}
PREDICATE (clear,0) {
	SDL_RenderClear( gRenderer );PL_succeed;
}
PREDICATE (refresh,0) {
	SDL_RenderPresent( gRenderer );PL_succeed;
}

PREDICATE (rect,4) {
	int i,i2,i3,i4;
	int b=PL_get_integer(A1,&i)&&PL_get_integer(A2,&i2)&&PL_get_integer(A3,&i3)&&PL_get_integer(A4,&i4);
	SDL_Rect fillRect = { i, i2, i3, i4 };
	//SDL_SetRenderDrawColor( gRenderer, 0x00, 0x00, 0x22, 0xFF );
	SDL_RenderFillRect( gRenderer, &fillRect );
	//Sdprintf(b);
	return b;
}
PREDICATE (rectBorder,4) {
	int i,i2,i3,i4;
	int b=PL_get_integer(A1,&i)&&PL_get_integer(A2,&i2)&&PL_get_integer(A3,&i3)&&PL_get_integer(A4,&i4);
	SDL_Rect rect = { i, i2, i3, i4 };
	SDL_RenderDrawRect( gRenderer, &rect );
	return b;
}
PREDICATE (circle,3) {
	int i,i2,i3,i4;
	int b=PL_get_integer(A1,&i)&&PL_get_integer(A2,&i2)&&PL_get_integer(A3,&i3);//&&PL_get_integer(A4,&i4);
	SDL_RenderFillCircle(gRenderer, i, i2, i3);
	return b;
}
PREDICATE (circleBorder,3) {
	int i,i2,i3,i4;
	int b=PL_get_integer(A1,&i)&&PL_get_integer(A2,&i2)&&PL_get_integer(A3,&i3);//&&PL_get_integer(A4,&i4);
	SDL_RenderDrawCircle(gRenderer, i, i2, i3);
	return b;
}
PREDICATE (setRGBA,4) {
	int i,i2,i3,i4;
	int b=PL_get_integer(A1,&i)&&PL_get_integer(A2,&i2)&&PL_get_integer(A3,&i3)&&PL_get_integer(A4,&i4);
	i4=0xFF;
	SDL_SetRenderDrawColor( gRenderer, i,i2,i3, i4 );
	return b;
}

PREDICATE (sdl_delay,1) {
	SDL_Delay(int(A1));
	PL_succeed;
}
PREDICATE (getTicks,1) {
	int i=SDL_GetTicks();
	return PL_unify_integer(A1,i);
}
PREDICATE (sdl_readkey,1) {
	//readkey();
	PL_succeed;
}

PREDICATE (check,2) {
	PL_succeed;
}
