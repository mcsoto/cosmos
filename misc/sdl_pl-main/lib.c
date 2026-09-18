//#include <windows.h>
#include <stdio.h>
#include <SWI-Prolog.h>
#include <SDL.h>
#include <SDL_image.h>
#include <stdbool.h>

SDL_Window* gWindow = NULL;
SDL_Surface* gSurface = NULL;
SDL_Renderer* gRenderer = NULL;
SDL_Texture* gTexture = NULL;

const int SCREEN_WIDTH = 640;
const int SCREEN_HEIGHT = 480;
const int START_TIME = 0;

bool init()
{
	//Initialization flag
	bool success = true;

	//Initialize SDL
	if( SDL_Init( SDL_INIT_VIDEO ) < 0 )
	{
		printf( "SDL could not initialize! SDL_Error: %s\n", SDL_GetError() );
		success = false;
	}
	else
	{
		//Set texture filtering to linear
		if( !SDL_SetHint( SDL_HINT_RENDER_SCALE_QUALITY, "1" ) )
		{
			printf( "Warning: Linear texture filtering not enabled!" );
		}

		//Create window
		gWindow = SDL_CreateWindow( "Main", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN );
		if( gWindow == NULL )
		{
			printf( "Window could not be created! SDL_Error: %s\n", SDL_GetError() );
			success = false;
		}
		else
		{
			//
			gRenderer = SDL_CreateRenderer( gWindow, -1, SDL_RENDERER_ACCELERATED| SDL_RENDERER_PRESENTVSYNC );
			if( gRenderer == NULL )
			{
				printf( "Renderer could not be created! SDL Error: %s\n", SDL_GetError() );
				success = false;
			}
			else
			{
				//Initialize renderer color
				SDL_SetRenderDrawColor( gRenderer, 0xFF, 0xFF, 0xFF, 0xFF );
				//Clear screen
				SDL_RenderClear( gRenderer );
				//Initialize PNG loading
				int imgFlags = IMG_INIT_PNG;
				if( !( IMG_Init( imgFlags ) & imgFlags ) )
				{
					printf( "SDL_image could not initialize! SDL_image Error: %s\n", IMG_GetError() );
					success = false;
				}
			}
		}
	}

	return success;
}

int c_exit() {
	SDL_DestroyWindow( gWindow );
	gWindow = NULL;

	SDL_Quit();
	IMG_Quit();
}
static foreign_t pl_exit(){
	c_exit();
	PL_succeed;
}

void call(){
	
}
static foreign_t check(term_t a1,term_t a2){
		if(PL_unify(a1,a2)) {
			printf("same\n");
		}
		else {
			printf("comp;\n");
		}
		PL_succeed;
}
static foreign_t sdl_start(term_t arg1,term_t a){
	SDL_Event e;
	int count=0;
	bool quit=false;
	term_t a0=PL_new_term_ref(),a1,a2=PL_new_term_ref(),prev=a1;
	term_t goal = PL_new_term_ref();
	term_t exception=PL_new_term_ref();
	PL_put_atom_chars(exception,"error: update function failure");
	int start=SDL_GetTicks();
	int dt=start,t0=dt,t1;
	int timer=50;
	int total=0;
	PL_get_integer(arg1, &timer);
	a1=a;
	while( !quit )
	{
		//Handle events on queue
		while( SDL_PollEvent( &e ) != 0 )
		{
			//printf("%d,%d\n",e,&e);
			//User requests quit
			if( e.type == SDL_QUIT )
			{
				quit = true;
			}
			else if( e.type == SDL_KEYDOWN )
            {
				int key=e.key.keysym.sym ;
				char c=key;
				//printf("key;%d;%c\n",key,c);
				if(PL_put_integer(a0, key)&&PL_cons_functor(goal, PL_new_functor(PL_new_atom("keyDown"), 1), a0)&&PL_call(goal,NULL))
					0; 
			}
			else if( e.type == SDL_MOUSEBUTTONUP )
            {
				int key=e.key.keysym.sym;
				char c=key;
				//printf("key;%d;%c\n",key,c);
				if(PL_put_integer(a0, key)&&PL_cons_functor(goal, PL_new_functor(PL_new_atom("mouseUp"), 1), a0)&&PL_call(goal,NULL))
					0; 
			}
		}
		t1=SDL_GetTicks();
		dt=t1-t0; t0=t1;
		total+=dt;
		if(total>timer) {
			//printf("update;%d,%d\n",timer,total);
			total=0;
			if(PL_cons_functor(goal, PL_new_functor(PL_new_atom("update"), 2), a1,a2)&&PL_call(goal,NULL))
				0;
			else {
				printf("error: update function failure\n");
				PL_raise_exception(exception);
				PL_fail;
			}
			count++;
			a1=a2;
			a2=PL_new_term_ref();
		} 
		//if(count>5000)quit=true;
		SDL_Delay(1);
	}
	//PL_cons_functor(goal, PL_new_functor(PL_new_atom("update"), 3), a0,a0,a0)&&PL_call(goal,NULL)||printf("error\n");
	PL_succeed;
} 

static foreign_t sdl_start_(){
	SDL_Event e;
	int count=0;
	bool quit=false;
	term_t a0=PL_new_term_ref();
	term_t goal = PL_new_term_ref();
	term_t exception=PL_new_term_ref();
	PL_put_atom_chars(exception,"error: update function failure");
	int start=SDL_GetTicks();
	int dt=start,t0=dt,t1;
	while( !quit )
	{
		//Handle events on queue
		while( SDL_PollEvent( &e ) != 0 )
		{
			//printf("%d,%d\n",e,&e);
			//User requests quit
			if( e.type == SDL_QUIT )
			{
				quit = true;
			}
		}
		t1=SDL_GetTicks();
		dt=t1-t0; t0=t1;
		PL_put_integer(a0, dt);
		if(PL_cons_functor(goal, PL_new_functor(PL_new_atom("update"), 1), a0)&&PL_call(goal,NULL))
			0;
		else {
			printf("error: update function failure\n");
			PL_raise_exception(exception);
			PL_fail;
		}
		count++;
		//if(count>5000)quit=true;
	}
	//PL_cons_functor(goal, PL_new_functor(PL_new_atom("update"), 3), a0,a0,a0)&&PL_call(goal,NULL)||printf("error\n");
	PL_succeed;
} 

static foreign_t eventIterator(term_t to){
	SDL_Event e;
	bool quit=false;
	while( !quit )
	{
		//Handle events on queue
		while( SDL_PollEvent( &e ) != 0 )
		{
			printf("%d,%d\n",e,&e);
			//User requests quit
			if( e.type == SDL_QUIT )
			{
				quit = true;
			}
		}
	} 







	PL_succeed;
}

static foreign_t pl_init(){
	init();
	PL_succeed;
}
struct pair
{
	SDL_Surface* s;
	SDL_Texture* t;
};
typedef struct pair pair;
static foreign_t loadImage(term_t t1, int n){
	char *s;
	PL_get_chars(t1,&s,CVT_STRING)||printf("error\n");
	//printf("l;%s;\n",s);
	SDL_Surface* loadedSurface = IMG_Load( s );
	SDL_Texture* newTexture = SDL_CreateTextureFromSurface( gRenderer, loadedSurface );
	if( newTexture == NULL )
		printf( "Unable to create texture from %s! SDL Error: %s\n", s, SDL_GetError() );
	SDL_FreeSurface( loadedSurface );
	if( loadedSurface == NULL )	{
		printf( "Unable to load image %s! SDL Error: %s\n", s, SDL_GetError() );
		PL_fail;
	}
	//void *p;
	pair p={loadedSurface,newTexture};
	term_t a1=PL_new_term_ref();term_t a2=PL_new_term_ref();
	term_t a=PL_new_term_ref();
	functor_t img=PL_new_functor(PL_new_atom("image"),2);
	//
	return PL_put_pointer(a1, loadedSurface)&&PL_put_pointer(a2, newTexture)&&PL_cons_functor(a,img,a1,a2)&&PL_unify(t1+1,a);
}

void draw(int x,int y) {
	//SDL_SetRenderDrawColor( gRenderer, 0xFF, 0xFF, 0xFF, 0xFF );
	SDL_Rect renderQuad = { x, y, gSurface->w, gSurface->h };
	SDL_RenderCopy( gRenderer, gTexture, NULL, &renderQuad );
}
static foreign_t drawImage(term_t a1, term_t a2)
{
	void *p;
	int i,x,y;
	SDL_Surface* s;
	SDL_Texture* t;
	term_t a=PL_new_term_ref();
	bool b=PL_get_arg(1,a1,a)&PL_get_pointer(a,&p);
	s=(SDL_Surface*)p;
	//get texture
	a=PL_new_term_ref();
	!PL_get_arg(2,a1,a)&PL_get_pointer(a,&p);
	t=(SDL_Texture*)p; 
	//printf("d;%d;%d;\n",s,t);
	gTexture=t;
	gSurface=s;
	!PL_get_integer(a1+1,&x)&&PL_get_integer(a1+2,&y);
	draw(x,y);
	PL_succeed;
}
	
static foreign_t clear(){
	//SDL_SetRenderDrawColor( gRenderer, 0xFF, 0xFF, 0xFF, 0xFF );
	SDL_RenderClear( gRenderer );PL_succeed;
}
static foreign_t refresh(){
	//SDL_UpdateWindowSurface( gWindow );
	SDL_RenderPresent( gRenderer );PL_succeed;
}

static foreign_t rect(term_t a,term_t a2,term_t a3,term_t a4){
	int i,i2,i3,i4;
	int b=PL_get_integer(a,&i)&&PL_get_integer(a2,&i2)&&PL_get_integer(a3,&i3)&&PL_get_integer(a4,&i4);
	SDL_Rect fillRect = { i, i2, i3, i4 };
	//SDL_SetRenderDrawColor( gRenderer, 0x00, 0x00, 0x22, 0xFF );
	SDL_RenderFillRect( gRenderer, &fillRect );
	//Sdprintf(b);
	return b;
}
static foreign_t pl_circle(term_t a){
	//circle(screen,a0,a1,a2,a3);SDL_SetColorKey( loadedSurface, SDL_TRUE, SDL_MapRGB( loadedSurface->format, 0, 0xFF, 0xFF ) );
	PL_succeed;
}

static foreign_t setRGBA(term_t a,term_t a2,term_t a3,term_t a4){
	int i,i2,i3,i4;
	int b=PL_get_integer(a,&i)&&PL_get_integer(a2,&i2)&&PL_get_integer(a3,&i3)&&PL_get_integer(a4,&i4);
	i4=0xFF;
	SDL_SetRenderDrawColor( gRenderer, i,i2,i3, i4 );
	return b;
}


#define seti(i,a) do { int b=PL_get_integer(a,&i); } while (0)

static foreign_t pl_circlefill(term_t a,term_t a2,term_t a3,term_t a4){
	//circlefill(screen,&a0,&a1,&a2,&a3);
	//SDL_Rect fillRect = { a0, a1,a2,a3 };
	int i,i2,i3,i4;
	//int b=PL_get_integer(a,&i)&&PL_get_integer(a2,&i2)&&PL_get_integer(a3,&i3)&&PL_get_integer(a4,&i4);
	SDL_Rect fillRect = { i, i2, i3, i4 };
	//SDL_SetRenderDrawColor( gRenderer, 0xFF, 0x00, 0x00, 0xFF );		
	SDL_RenderFillRect( gRenderer, &fillRect );
	PL_succeed;
}
 


static foreign_t sdl_delay(term_t a)
{
	int i;
	seti(i,a);
	SDL_Delay(i);
	//SDL_Delay(1000);
	PL_succeed;
}
static foreign_t getTicks(term_t a)
{
	int i=SDL_GetTicks();
	return PL_unify_integer(a,i);
}
static foreign_t pl_readkey()
{
	//readkey();
	PL_succeed;
}

static PL_extension predicates[] = {
{ "init", 0, pl_init, 0 },
{ "exit", 0, pl_exit, 0 },
{ "check", 2, check, 0 },
{ "sdl_delay", 1, sdl_delay, 0 },
{ "circlefill", 4, pl_circlefill, 0 },
{ "rect", 4, rect, 0 },
{ "loadImage", 2, loadImage, 0 },
{ "refresh", 0, refresh, 0 },
{ "clear", 0, clear, 0 },
{ "drawImage", 3, drawImage, 0 },
{ "setRGBA", 4, setRGBA, 0 },
{ "getTicks", 1, getTicks, 0 },
{ "getPoll", 1, eventIterator, 0 },
{ "sdl_start", 2, sdl_start, 0 },
{ "sdl_start", 0, sdl_start_, 0 },
//{ "readkey", 0, pl_readkey, 0 },
{ NULL,         0,      NULL,   0 }
};
install_t install_lib()
{ //PL_register_foreign("say_hello", 1, pl_say_hello, 0);
//PL_register_foreign("init", 1, pl_init, 0);
PL_register_extensions(predicates);
}
//int main(int a,char*s){}