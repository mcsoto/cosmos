:- ensure_loaded(reif).
:- ensure_loaded(library(clpr)).
:- ensure_loaded(library(random)).%:- ensure_loaded(clp).
:-style_check(-singleton),style_check(-no_effect).

% Resolve Cosmos sources and libraries relative to this runtime when a
% launcher has not already supplied a search path. This keeps generated Prolog
% usable from a working directory other than the compiler repository.
:- ( nb_current(path,_) -> true
   ; prolog_load_context(directory,RuntimeDir),
     directory_file_path(RuntimeDir,'?',SourceTemplate),
     directory_file_path(RuntimeDir,'../libs/?',LibraryTemplate),
     directory_file_path(RuntimeDir,'../userlibs/?',UserLibraryTemplate),
     atomic_list_concat([SourceTemplate,LibraryTemplate,UserLibraryTemplate,'?'],';',RuntimePath),
     nb_setval(path,RuntimePath)
   ).

%loaded manually for compatibility with old swipl versions
%:- ensure_loaded(clp).
%:- use_module(library(lists)).
%:- ensure_loaded(assoc).
:- ensure_loaded(library(assoc)).

assoc_to_list2(Assoc, List) :-
    assoc_to_list2(Assoc, List, []).

assoc_to_list2(t(Key,Val,_,L,R), List, Rest) :-
    assoc_to_list2(L, List, [fc_Pair(Key,Val)|More]),
    assoc_to_list2(R, More, Rest).
assoc_to_list2(t, List, List).

:- use_module(library(prolog_stack)).
:- use_module(library(error)).

has_(L,X) :- var(L),!,freeze(L,has_(L,X)).
has_(L,X) :- is_list(L),!,member(X,L).
has_(L,X) :- is_assoc(L),!,get_(L,_,X).
has_(L,X) :- string(L),!,s_get(L,_,X).

cosmos_float(Value, Float) :- Float is float(Value).

% Classification exposed by logic.type/2.  Keep the public names in the
% Cosmos vocabulary while leaving type constraints to type_is/2 below.
cosmos_type(Value, "Any") :- var(Value), !.
cosmos_type(Value, "Number") :- number(Value), !.
cosmos_type(Value, "String") :- string(Value), !.
cosmos_type(Value, "List") :- is_list(Value), !.
cosmos_type(Value, "Table") :- is_assoc(Value), !.
cosmos_type(Value, "Functor") :- compound(Value), !.
cosmos_type(_, "Any").

size_(L,X) :- var(L),!,freeze(L,size_(L,X)).
size_(L,X) :- is_list(L),!,length(L,I),cosmos_float(I,X).
size_(L,X) :- is_assoc(L),!,length_(L,X).
size_(L,X) :- string(L),!,s_size(L,X).
size(L,X) :- list(L),!,length(L,I),cosmos_float(I,X).

%get_(T, Key, Value) :- freeze(Key,freeze(T,get2(T, Key, Value))).
errorget(T, Key, Value) :- write("> "),write_(T),write("["),write_(Key),write("]"),nl,cthrow(": attempt to index a variable").
get_(T, Key, Value) :- (var(T)->errorget(T, Key, Value);true),freeze(Key,get2(T, Key, Value)).%in,in,any
get2(T, Key, Value) :- is_assoc(T),!,get_assoc(Key, T, Value).
get2(T, Key, Value) :- string(T),!,int(Key,HostKey),sub_string(T,HostKey,1,_,Value).
get2(T, Key, Value) :- T=obj(T2),!,%writeln(objcall(T2,-Key,-Value)),
get_obj(T2, Key, Found),
	(Found=clos(_,_)->Value=method_cl(T,Found);Value=Found).

%pure(T,Key)
%choose(T)
%getnil(T, Key, Value) :- errorget(T, Key, Value). %var
%delay(Key)
%getnil(T, Key, Value) :- freeze(Key,get22(T, Key, Value)).%in,in,any

getnil(T, Key, Value) :- (var(T)->errorget(T, Key, Value);true),freeze(Key,get22(T, Key, Value)).%in,in,any
get22(T, Key, Value) :- var(T),!,errorget(T, Key, Value).
get22(T, Key, Value) :- is_assoc(T),!,get_tablenil2(T, Key, Value).
get22(T, Key, Value) :- string(T),!,int(Key,HostKey),(sub_string(T,HostKey,1,_,Value) -> true ; Value=fc_null).
get22(T, Key, Value) :- is_list(T),!,int(Key,HostKey),(nth0(HostKey,T,Value) -> true ; Value=fc_null).
get22(T, Key, Value) :- get2(T, Key, Value).

add_(X,Y,Z) :- var(X),var(Y),var(Z),!,when((nonvar(X);nonvar(Y);nonvar(Z)),add_(X,Y,Z)).
% `+` concatenates when either operand is a string.  Numeric operands are
% converted consistently, so both `''+1` and `'col'+col` use string semantics.
add_(X,Y,Z) :- (string(X);string(Y)),!,cosmos_string(X,SX),cosmos_string(Y,SY),s_concat(SX,SY,Z).
add_(X,Y,Z) :- (number(X);number(Y);number(Z)),!,{Z = X+Y}.
add_(X,Y,Z) :- is_list(X),!,append(X,Y,Z).
add_(X,Y,Z) :- is_assoc(X),!,default_lib("table",T),get_(T,"update",Clos),call_cl(Clos,[X,Y,Z]).
%calc(X+Y,Z) :- ((string(X),string(Y))->s_concat(X,Y,Z);((number(X),number(Y))->{Z = X+Y};Z = X+Y)).

cosmos_string(X,S) :- var(X),!,freeze(X,cosmos_string(X,S)).
cosmos_string(X,X) :- string(X),!.
cosmos_string(X,S) :- number(X),!,number_string(X,S).
cosmos_string(X,_) :- throw(error(type_error(string_or_number,X),cosmos_string/2)).

%
assert_(L) :- assert(predicate(L)).
assert_get(L) :- predicate(L).
%cosmos_assert(Goal, Message) :- ( once(Goal) -> true ; throw(Message) ).

%
typeof(X,S) :- is_list(X),!,S="list".
typeof(X,S) :- is_assoc(X),!,S="table".
type_is(_, "Any") :- !.
type_is(X, "Number") :- number(X), !.
type_is(X, "String") :- string(X), !.
type_is(X, "List") :- is_list(X), !.
type_is(X, "Table") :- is_assoc(X), !.
type_is(fc_null, "Null") :- !.
protocol_is(_, []).
protocol_is(Value, [Member|Rest]) :- get2(Value, Member, _), protocol_is(Value, Rest).
getmeta(fc_Pair(_,T),T) :- !.
getmeta(O,T) :- typeof(O,S),meta_(S,T).
setmeta(S,T) :- assert(meta_(S,T)).
getmetaobj(O,O).

% Generic iterator protocol used by Cosmos `for`/`some`. Built-in lists and
% tables work without library setup; other values delegate to their metatable.
cosmos_iter_start(Collection, cosmos_list_iter(0.0, Collection)) :- is_list(Collection), !.
cosmos_iter_start(Collection, cosmos_table_iter(Pairs)) :- is_assoc(Collection), !, assoc_to_list(Collection, Pairs).
cosmos_iter_start(Collection, cosmos_string_iter(0.0, Collection)) :- string(Collection), !.
cosmos_iter_start(Collection, cosmos_provider_iter(Provider, Iterator)) :-
	getmeta(Collection, Provider), get_(Provider, "iter", Iter), call_cl(Iter, [Collection, Iterator]), !.
% `it` is the legacy spelling used by the reference provider tables.
cosmos_iter_start(Collection, cosmos_provider_iter(Provider, Iterator)) :-
	getmeta(Collection, Provider), get_(Provider, "it", Iter), call_cl(Iter, [Collection, Iterator]), !.
cosmos_iter_start(Collection, _) :- throw(error(cosmos_iteration_provider(Collection), cosmos_iter_start/2)).

cosmos_iter_next(cosmos_list_iter(Key, []), cosmos_list_iter(Key, []), _, _, 0.0) :- !.
cosmos_iter_next(cosmos_list_iter(Key, [Value|Rest]), cosmos_list_iter(NextKey, Rest), Key, Value, 1.0) :- !,
	NextKey is Key + 1.
cosmos_iter_next(cosmos_table_iter([]), cosmos_table_iter([]), _, _, 0.0) :- !.
cosmos_iter_next(cosmos_table_iter([Key-Value|Rest]), cosmos_table_iter(Rest), Key, Value, 1.0) :- !.
cosmos_iter_next(cosmos_string_iter(Key, String), cosmos_string_iter(Key, String), _, _, 0.0) :-
	string_length(String, Length), Key >= Length, !.
cosmos_iter_next(cosmos_string_iter(Key, String), cosmos_string_iter(NextKey, String), Key, Value, 1.0) :-
	string_length(String, Length), Key < Length, !, int(Key, HostKey), sub_string(String, HostKey, 1, _, Value), NextKey is Key + 1.
cosmos_iter_next(cosmos_provider_iter(Provider, Iterator), cosmos_provider_iter(Provider, Next), Key, Value, Status) :-
	get_(Provider, "next", NextClosure), call_cl(NextClosure, [Iterator, Next, Key, Value, Status]), !.
cosmos_iter_next(Iterator, _, _, _, _) :- throw(error(cosmos_iteration_provider(Iterator), cosmos_iter_next/5)).

%
makeobj(O,O2) :- O2=obj(O).
get_obj(T, Key, Value) :- get_(T, Key, Value),!.
get_obj(T, Key, Value) :- get_(T, "_prototype", T1),get_obj(T1, Key, Value),!.
get_obj(T, Key, Value) :- write("> "),write("#obj"),write("["),write_(Key),write("]"),nl,cthrow(": could not find field in object").
obj_set(TO, X, V, O2) :- T=obj(O1),put_assoc(X, T, V, T2),O2=obj(T2).
%objcall(T1, X, Args, T2) :- T=obj(T1),put_assoc(X, T, V, T2).

get_tablenil2(T, Key, Value) :- (get_assoc(Key, T, Value) -> true ; Value=fc_null).
get_tablenil(T, Key, Value) :- freeze(Key,get_tablenil2(T, Key, Value)).
get_table(T, Key, Value) :- freeze(Key,get_assoc(Key, T, Value)).

call_(O, Key, Args) :- O=obj(T),!,(var(T)->errorget(T, Key, Value);true),get_obj(T, Key, Value),call_cl(Value, [O|Args]).
call_(T, Key, Args) :- get_table(T, Key, Value),call_cl(Value, Args).
call_(T, X, Args, T2) :- throw(1).

% records %

new(T) :- empty_assoc(T).
set_(T, X, V, T2) :- put_assoc(X, T, V, T2).

% Mutable library cells. The public object remains a Cosmos closure table;
% these predicates implement its stateful backing store with a shared compound
% whose assoc argument is replaced non-backtrackably.
table_new(mutable(Assoc)) :- empty_assoc(Assoc).
table_get(mutable(Assoc),Key,Value) :- get_assoc(Key,Assoc,Value).
table_set(Cell,Key,Value,Cell) :-
	Cell=mutable(Assoc),
	put_assoc(Key,Assoc,Value,Updated),
	nb_linkarg(1,Cell,Updated).

length_(L,X) :- assoc_to_list(L,L1),length(L1,I),cosmos_float(I,X).
get_dict(T, Key, Value) :- freeze(Key,get2(T, Key, Value)).
%get__(T, Key, Value) :- (get_assoc(Key, T, Value)->true;(writeln(T),concat("CosmosError: cannot find \"",Key,S1),concat(S1,"\" in table",S),throw(S))).
del_(T, X, V, T2) :- del_assoc(X, T, V, T2).

next_pair([K-V|L2],L2,K,V).

%next(T, T2, K, V) :- assoc_to_list(T,L), next_pair(L,T2,K,V).
next_assoc(T, T2, K, V) :- assoc_to_list(T,L), next_pair(L,T2,K,V).

next(t(K,V,_,X1,X2), T2, K, V) :- T2=t1(X1,X2).
%next(t1(t,X2), T2, K, V) :- next(X2,T2,K,V).
%next(t1(X1,t), T2, K, V) :- next(X1,T2,K,V).
%next(t, T2, K, V) :- next(X1,T2,K,V).
%next(t(X1,X2), T2, K, V) :- next(X1,T2,K,V);next(X2,T2,K,V).

%
is_dict(T) :- is_assoc(T).
dict_new(T) :- T=t{}.
dict_set(T,X,V,T2) :- put_dict([X=V],T,T2).
dict_get(T,X,V,T2) :- get_dict(X, T, V).%t{X=V}.

n_le(X,Y) :- X =< Y.
n_ge(X,Y) :- X >= Y.
n_lt(X,Y) :- X < Y.
n_gt(X,Y) :- X > Y.
n_neq(X,Y) :- X \== Y.

r_mul(X,Y,Z) :- {Z = X*Y}.
r_div(X,Y,Z) :- {Z = X/Y}.
r_sub(X,Y,Z) :- {Z = X-Y}.
r_add(X,Y,Z) :- {Z = X+Y}.
r_mod(X,Y,Z) :- var(X), !, freeze(X,r_mod(X,Y,Z)).
r_mod(X,Y,Z) :- var(Y), !, freeze(Y,r_mod(X,Y,Z)).
r_mod(X,Y,Z) :- Z is X - floor(X/Y)*Y.
mod(X,Y,Z) :- r_mod(X,Y,Z).

r_le(X,Y) :- {X =< Y}.
r_ge(X,Y) :- {X >= Y}.
r_lt(X,Y) :- {X < Y}.
r_gt(X,Y) :- {X > Y}.

le(X,Y) :- {X =< Y}.
ge(X,Y) :- {X >= Y}.
lt(X,Y) :- {X < Y}.
gt(X,Y) :- {X > Y}.

ceq(X,X).%todo

%base?
list_atom_string([], []).
list_atom_string(L1, L2) :-
	L1 = [H | T],
	%atom_string(H, H2),%don't ask me why but this fails and returns char codes on 8.4.wtf?
	string_to_atom(H2, H),
	L2 = [H2 | T2],
	list_atom_string(T, T2).

def(X) :- def(X,"def").

def(X,S) :- (var(X)->writeln(X),cthrow(S);true).

cthrow(S) :- write("RuntimeError: "),write(S),nl,nl,backtrace(10),throw(error).

%display
print(X) :- writeln(X).
writeln(X) :- write_(X),nl.
writeln_(X) :- writeln(X).

folds([X|L2],Sep) :- X=A-B,write_(A),write(": "),write_(B),(L2=[]->true;write(Sep),folds(L2,Sep)).
folds([],Sep).
assoc_str(X) :- assoc_to_list(X,L),write("{"),folds(L,", "),write("}"),!.

write_(X) :- write_(X,full).
write_(X,minimal) :-
	(is_assoc(X) ->
		write("dict#")
		;	
		(functor(X,A,B) ->
			write(A) ;
			%string?
			(string(X)->write("str#");write_(X,full))
		)
	).%( var(X) -> write("var#"), write(X)	; is_rel(X) -> write("#rel")	; is_list(X) -> write_list(X)	; is_assoc(X) -> assoc_str(X)	; compound(X), functor(X,A,B), atom(A), atom_concat("fc_",Clean,A) -> write_functor(X,Clean,B)	; compound(X) -> writeq(X) ; writeq(X)	).

write_(X,full) :- var(X),!, write("var#"), write(X).
write_(X,full) :- X=obj(T),!, write("obj#"),write_(T,full).
write_(X,full) :- is_rel(X),!, write("rel#").
write_(X,full) :- is_assoc(X),!, assoc_str(X).
write_(X,full) :- functor(X,A,B),!, write(X).
write_(X,full) :- is_string(X),!, write("str#").
write_(X,full) :- !, write(X).

write_(X,legacyfull) :-
	(var(X) -> (write("var#"), write(X))
		;
		(is_rel(X) ->
		write("rel#") ;
		(is_assoc(X) ->
		%write("dict#")
		%writeq(X)
		assoc_str(X)
		;
			(functor(X,A,B), atom(A), atom_concat("fc_",Clean,A) ->
				write_functor(X,Clean,B) ;
				(functor(X,A,B) ->
				(writeq(X)) ;
				%string?
				(write("\""),writeq(X),write("\""))))
		))
	).

write_single_functor(X) :- functor(X,A,B), atom(A), atom_concat("fc_",Clean,A), !,write_functor(X,Clean,B).
	
write_functor(X,Name,Arity) :-
	write(Name),
	(Arity=:=0 -> true ; write("("),write_functor_args(X,1,Arity),write(")")).
write_functor_args(_,I,Arity) :- I>Arity, !.
write_functor_args(X,I,Arity) :-
	arg(I,X,Value),write_(Value),
	(I=:=Arity -> true ; write(", "),J is I+1,write_functor_args(X,J,Arity)).

write_list([]) :- write("[]").
write_list([Head|Tail]) :-
	write("["),write_(Head),write_list_tail(Tail),write("]").
write_list_tail([]).
write_list_tail([Head|Tail]) :- write(", "),write_(Head),write_list_tail(Tail).
write_list_tail(Tail) :- write("| "),write_(Tail).

%
is_rel(X) :- X=clos(_,_).

:- nb_setval(call,0).

enter_hook(L,I) :-
	nb_getval(call,Cl),%writeln(Cl),
	(Cl=clos(X,Y)->call_cl(Z,L);true).
	
exit_db(Z,L,I) :-
	I=[Name],
	write(Name),write(''),write_(L,full),%debug exit
	nl.
	
enter_db(Z,L,I) :-
	I=[Name],%debug rel
	write("| "), write(Name),write(''),write_(L,full), 
	nl.
	
freeze2(X,Z,L) :- freeze(X,call_cl(Z,L)).

call_db(Z,L,I) :-
	enter_db(Z,L,I),enter_hook(L,I),
	(call_cl(Z,L),write("- ");write("x ")),
	exit_db(Z,L,I).

% Trace a statically named Cosmos relation. Unlike call_db/3, its first
% argument is a predicate atom rather than a closure value.
call_dbs(P,L,I) :-
	enter_db(P,L,I),enter_hook(L,I),
	(apply(P,L),write("- ");write("x "),exit_db(P,L,I),false),
	exit_db(P,L,I).
	
%(X;list of upval-args,Y;predicate)
call_cl(method_cl(O,Z),L) :- !, call_cl(Z,[O|L]).
call_cl(cosmos_protocol_method(Object,Protocol,Schemas,Key),Args) :- !,
    cosmos_protocol_invoke(Object,Protocol,Schemas,Key,Args).
call_cl(Z,L) :- Z=clos(X,P), %write("clos: "), writeln(X),
	%def(X,"undefined closure"),
	append(L,[X],X2),
	%write("|"), write(P),write(';'),writeq(L),nl,
	apply(P,X2).

call_simple(Z,Args) :- Z=clos(X,P), %write("clos: "), writeln(X),
	%def(X,"undefined closure"),
	append(L,[X],X2),
	%write("|"), write(P),write(';'),writeq(L),nl,
	apply(P,X2).

apply2(Z,L) :- call_cl(Z,L).
apply_cl(Z,L) :- call_cl(Z,L).

%delay
both(X,Y,P) :- when((ground(X),ground(Y)),P).

%math (deprecated?)
%calc(X+Y,Z) :- ((string(X);string(Y))->s_concat(X,Y,Z);((number(X);number(Y))->{Z = X+Y};Z = X+Y)),!.
calc(X+Y,Z) :- ((string(X),string(Y))->s_concat(X,Y,Z);((number(X),number(Y))->{Z = X+Y};Z = X+Y)).
str_calc(X+Y,Z) :- ((string(X),string(Y))->s_concat(X,Y,Z);Z = X+Y).

str(S,S2) :- number(S),!,number_string(S,S2).
str(S,S2) :- string(S),!,S2=S.
str(S,S2) :-
	def(S,"string is an unbound variable (In)"),
	(S='+'(X,Y) ->
	(%writeq(X),nl, writeq(Y),nl,writeln("-"),
	str(X,X1),	str(Y,Y1),
	(number(X1),number(Y1) -> S2 is X1+Y1 ; s_concat(X1,Y1,S2))
	) ; S2=S).
	
%math
real(X,Y) :- {Y=X}.
cfloor(X,Y) :- freeze(X,(I is floor(X),cosmos_float(I,Y))).
int(X,Y) :- Y is floor(X). %{Y1=X},freeze(Y1,Y is floor(Y1)).
num(X,Y) :- number(X),!,cosmos_float(X,Y).
num(X,Y) :- string(X),!,number_string(I,X),cosmos_float(I,Y).
num(X,_) :- throw(error(type_error(number_or_string,X),num/2)).
int_(X,Y) :- {Y1=X},Y is floor(Y1).

delay_calc(Y,X) :- when(ground(Y),is(X,Y)).%calc(X+Y,Z) :- (number(X)->{Z = X+Y};((string(X),string(Y))->s_concat(X,Y,Z);Z = X+Y)).
%delay_add(Y,X) :- when(ground(Y),calc(Y,X)).
%delay_add(Y,X) :- Y=X1+X2,add_(X1,X2,X).
add1(X,Y,Z) :- string(X)->freeze(Y,s_concat(X,Y,Z));freeze(Y,is(Z,X+Y)).
delay_add(X,Y,Z) :- freeze(X,add1(X,Y,Z)).

% strings
% SWI-Prolog supplies atom_string/2.  Do not redefine it: newer SWI releases
% reject a second consult of this legacy shim, which broke multi-query sessions.
%string_length(S,N) :- throw(string_length),atom_length(S,N).
%string_code(1, S, N) :- true.
%s_get(L,N,Element) :- nth0(N,L,Element).
%s_get2(S,N,C) :- int(C,C1),sub_string(S,N,1,_,C1).
%s_get(S,N,C) :- freeze(C,freeze(S,s_get2(S,N,C))).

%s_get(S,N,C) :- freeze(S,s_get0(S,N,C)).
%s_get0(S1,I,S2) :- _i is integer(I),sub_string(S1,_i,1,S2).
%s_get0(S1,I,S2) :- _i is integer(I),sub_atom(S1,_i,1,S2).

s_get(S,N,C) :- freeze(S,(int(N,HostKey),sub_string(S,HostKey,1,_,C))).
s_at(S,N,C) :- s_get(S,N,C).
s_first(S1,S2) :- s_get(S1, 0, S2).
%s_concat(S,S1,S2) :- atomic_concat(S,S1,_x),atom_string(_x,S2).%in 8.2.3, string_concat sometimes fails
s_concat(S,S1,S2) :- when((ground(S),ground(S1)),string_concat(S,S1,S2)).%atom_concat(S,S1,S2).
s_size2(S,N) :- atom_length(S,I),cosmos_float(I,N).
s_size(S,N) :- freeze(S,s_size2(S,N)).
s_slice(S1,I,J,S2) :- freeze(S1,both(I,J,s_slice2(S1,I,J,S2))).
s_slice2(S1,I,J,S2) :- s_size(S1,L), (lt(J, L) -> End=J ; End=L),
    JJ is End-I, int(I,HostI), int(JJ,HostLength),
    %sub_atom(S1,_i,_j,_,S2),
	sub_string(S1,HostI,HostLength,_,S2).
slice(List,I,J,Result) :- int(I,HostI),int(J,HostJ),slice_host(List,HostI,HostJ,Result).
slice_host(_,I,J,[]) :- I >= J, !.
slice_host([],_,_,[]) :- !.
slice_host([Head|Tail],0,J,[Head|Rest]) :- J > 0,!,NextJ is J-1,slice_host(Tail,0,NextJ,Rest).
slice_host([_|Tail],I,J,Result) :- I > 0,!,NextI is I-1,NextJ is J-1,slice_host(Tail,NextI,NextJ,Result).

cosmos_codes(String, Codes) :- string_codes(String, HostCodes), cosmos_float_codes(HostCodes, Codes).
cosmos_float_codes([], []).
cosmos_float_codes([Code|Rest], [Float|Floats]) :- cosmos_float(Code,Float),cosmos_float_codes(Rest,Floats).
cosmos_code(String, Code) :- string_codes(String,[HostCode]),cosmos_float(HostCode,Code).

fcsize(Functor, Size) :- functor(Functor,_,HostSize),cosmos_float(HostSize,Size).
fcget(Functor, Index, Value) :- int(Index,HostIndex),arg(HostIndex,Functor,Value).

write8(Stream, Value) :- int(Value,Byte),put_byte(Stream,Byte).
write16(Stream, Value) :- int(Value,Word),Low is Word /\ 255,High is (Word >> 8) /\ 255,put_byte(Stream,Low),put_byte(Stream,High).
write32(Stream, Value) :- int(Value,Word),B0 is Word /\ 255,B1 is (Word >> 8) /\ 255,B2 is (Word >> 16) /\ 255,B3 is (Word >> 24) /\ 255,put_byte(Stream,B0),put_byte(Stream,B1),put_byte(Stream,B2),put_byte(Stream,B3).
%s_replace(Old, New, S, S2) :- string_concat(Split, Old, S), string_concat(Split, New, S2).
s_split(S,Word,S2) :- split_string(S,Word,"",S2).
%s_replace(Source, Old, New, Target) :- s_split(Source, Old, List), s_split(Target, New, List).
%atom_replace(Source, Old, New, Target) :- atom_split(Source, Old, List), atom_split(Target, New, List).

% used only for require; do not use in general cases
find_index(S,C,I,I2) :- s_size(S,N),I<N,((s_get(S,I,C), I2=I) ; (I1 is I+1,find_index(S,C,I1,I2))).
find_index(S,C,I) :- find_index(S,C,0,I).

replace(S, Old, New, Final) :- find_index(S,Old,I), !, %writeln(I),
	s_slice(S,0,I,S0),s_size(S,N),s_slice(S,I+1,N,S1),%writeln(S0),writeln(S1),
	s_concat(S0,New,Temp),s_concat(Temp,S1,Final),!.
replace(S, Old, New, S).

% sys %

val(X,Y) :- nb_getval(X,Y).

:- table tload/1. %swi=8.4
tload(F) :- exists_source(F), %write("file:"),writeln(F),
	ensure_loaded(F).
cload(F) :- exists_source(F), ensure_loaded(F).

load_any([X|L],Mod) :- replace(X,"?",Mod,F),(tload(F) -> true ; load_any(L,Mod)).

crequire(Mod,Y,_) :-
	% search PATH; standalone compiler invocations may not set it
	( nb_current(path,Path) -> true ; Path="src/?;libs/?;userlibs/?;?" ),
	split_string(Path,";","",X),
	%load module; Mod=module name
	%(load_any(X,Mod)->writeln("could not load module "+Mod);cthrow(S)),
	(load_any(X,Mod)->true;str("could not load module '"+Mod+"'",S),cthrow(S)),
	%call loaded module
	atom_string(ModP,Mod), call(ModP,Y),
	%write("out:"),writeln(Y),
	true.

% Default Cosmos libraries are lazy and process-cached. The compiler emits
% default_lib/2 when io, list, or table is used as a library object, while raw
% Prolog code may call the same predicate directly.
cosmos_default_library("io").
cosmos_default_library("list").
cosmos_default_library("table").
cosmos_default_library("math").
cosmos_default_library("string").
cosmos_default_library("debug").
cosmos_default_library("logic").
cosmos_default_library("mutable").

default_lib(Name0,Value) :-
	( string(Name0) ->
	  Name=Name0,
	  string_codes(Name,Codes),
	  atom_codes(NameAtom,Codes)
	; atom(Name0) ->
	  NameAtom=Name0,
	  atom_codes(NameAtom,Codes),
	  string_codes(Name,Codes)
	),
	cosmos_default_library(Name),
	atomic_list_concat(['$cosmos_default_',NameAtom],CacheKey),
	( nb_current(CacheKey,Cached) -> Value=Cached
	; crequire(Name,Loaded,_),
	  nb_setval(CacheKey,Loaded),
	  nb_getval(CacheKey,Value)
	).

clock(X) :- get_time(X).
args(L) :- current_prolog_flag(os_argv,L).

% internal % (deprecated)

require(S,F) :- loaded(S,F);[S].

cread(X).
creadFile(F,S).
cmodule(F,X) :- ensure_loaded(F), call(F,X).

%io
ioread(S) :- read_string(user_input,"\n","\r",_,S).%ioread(X) :- true.

fread(F,S) :- read_string(F,"\n","\r",_,S).
fread_all(F,S) :- read_string(F,"","",_,S).
fread_char(F,S) :- read_string(F,1,S).
fread_custom(F,A,B,C,S) :- read_string(F,A,B,C,S).

fopen(Filename,Mode,File) :-
	(Mode="read" -> open(Filename,read,File) ;
		(Mode="write" -> open(Filename,write,File) ;
			(Mode="update" -> open(Filename,update,File) ; throw("not a correct mode for 'open'.")))).
	
fopen_binary(Filename,Mode,File) :-
	(Mode="read" -> open(Filename,read,File,[type(binary)]) ;
		(Mode="write" -> open(Filename,write,File,[type(binary), encoding(octet)]) ;
			(Mode="update" -> open(Filename,update,File,[type(binary)]) ; throw("not a correct mode for 'open'.")))).

fopen_(Filename,Mode,File) :-
	atom_string(_mode,Mode),
	catch(open(Filename,read,File),_,false).

%
safeNot(C) :- when(ground(C),\+call(C)).

strrep(S,S2) :- re_replace("\"*","\\\"",S,S2).
s_le(S1,S2) :- S1 @=< S2.

pure_comp(X,Y,S) :- when(ground(X),when(ground(Y),(compare(Z,X,Y),atom_string(Z,S)))).
