%nil(X) :- true.
%nil(X,Y) :- true.
%nil(X,Y,_) :- true.
nil(X,S,S,_) :- writeln(up),true.
nil(X,Y,S,S,_) :- writeln(up_),true.
get(T,Name,O) :- get_(T,Name,O) -> true ; O=clos([],nil).
%get(T,Name,O) :- get_(T,Name,O) -> true ; O=nil.
%start(Cl) :- call_cl(Cl).
%update(X,Y):-Y=X.
start(T1,T,Start) :- get_(T,"update",Cl),%writeln(Cl),call_cl(Cl,[1,Y1]),writeln(Y1),assert(update(X,Y):-(Y=X,writeln(Y))),update(1,1),
	get(T,"mouseup",Cl2),
	get(T,"keypressed",Cl3),
	assert(update(X,Y):-call_cl(Cl,[X,Y])),
	assert(mouseUp(X,Y,S,S1):-
		(X1 is float(X),Y1 is float(Y),call_cl(Cl2,[X1,Y1,S,S1]))),
	assert(keyDown(X,S,S1):-(string_lower(X,Y),call_cl(Cl3,[Y,S,S1]))),!,
	sdl_start(T1,Start).
%:- empty_assoc(T1),start(1,T1,_).