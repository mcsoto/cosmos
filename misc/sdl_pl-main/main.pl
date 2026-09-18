:- ensure_loaded(sdl).
keyDown(X,S,S) :- writeln(X),sdl_right(X),nb_setval(dir,right).
keyDown(X,S,S) :- writeln(X),sdl_left(X),nb_setval(dir,left).
keyDown(X,S,S).
mouseUp(_,_,S,S) :- writeln(X).

update(DT,[Y,I],[Y,I2]) :- 
	writeln('--'),writeln(args(DT,I,I2)),
	setRGBA(255,255,255,255),clear,
	I2 is I+1,writeln(I),
	setRGBA(0,0,0,255),drawImage(Y,I,120),writeln("d;"),%sdl_delay(2500),
	setRGBA(0,0,0,255),rect(I,1,50,50),refresh,
	true
	.
update([Y,I],[Y,I2]) :- 
	writeln('--'),writeln(args(I,I2)),
	nb_getval(dir,Dir),
	setRGBA(255,255,255,255),clear,
	(Dir=right->I2 is I+1;I2 is I-1),writeln(I),
	setRGBA(0,0,0,255),drawImage(Y,I,120),writeln("d;"),%sdl_delay(2500),
	setRGBA(0,0,0,255),circle(I,255,25),rect(I,1,50,50),refresh,
	true
	.
start :- init,
	loadImage("b1.png",Y),write("fc;"),writeln(Y),
	sdl_delay(500),nb_setval(total,0),
	nb_setval(dir,right),nb_setval(y,Y),nb_setval(x,50),writeln(Y),
	%sdl_start,
	sdl_start(100,[Y,50]),%getPoll(X1),getTicks(X),writeln(X),getPoll(X1),writeln(X1),
	%startDt([Y,50]),
	%setInterval(50,[Y,50]),
	exit,halt.

start1 :- true,init,loadImage("b.png",Y),write("fc;"),writeln(Y),
	setRGBA(0,0,0,255),drawImage(Y,50,120),rect(1,1,50,50),refresh,sdl_delay(1000),exit,writeln(1),halt.

:- start.