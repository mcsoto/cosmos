:- use_module(library(clpfd)).
:- use_module(library(clpr)).
:- use_module(library(assoc)).

add(X,Y,Z) :- fd_add(X,Y,Z).
sub(X,Y,Z) :- fd_sub(X,Y,Z).
mul(X,Y,Z) :- fd_mul(X,Y,Z).
div(X,Y,Z) :- fd_div(X,Y,Z).
inc(X,Y) :- fd_inc(X,Y).
dec(X,Y) :- fd_dec(X,Y).

r_add(X,Y,Z) :- {Z = X+Y}.
r_sub(X,Y,Z) :- {Z = X-Y}.
r_mul(X,Y,Z) :- {Z = X*Y}.
r_div(X,Y,Z) :- {Z = X / Y}.
r_inc(X,Y) :- {X+1 = Y}.
r_dec(X,Y) :- {X-1 = Y}.

fd_mul(X,Y,Z) :- Z #= X*Y.
fd_div(X,Y,Z) :- Z #= X/Y.
fd_sub(X,Y,Z) :- Z #= X-Y.
fd_add(X,Y,Z) :- Z #= X+Y.
fd_inc(X,Y) :- X+1 #= Y.
fd_dec(X,Y) :- X-1 #= Y.

dynamic_add(X,Y,Z) :- (number(X) -> add(X,Y,Z) ; string_concat(X,Y,Z)).

r_le(X,Y) :- {X =< Y}.
r_ge(X,Y) :- {X >= Y}.
r_lt(X,Y) :- {X < Y}.
r_gt(X,Y) :- {X > Y}.
r_neq(X,Y) :- {X =\= Y}.

fd_le(X,Y) :- X #=< Y.
fd_ge(X,Y) :- X #>= Y.
fd_lt(X,Y) :- X #< Y.
fd_gt(X,Y) :- X #> Y.
fd_neq(X,Y) :- X #\= Y.

n_le(X,Y) :- X #=< Y.
n_ge(X,Y) :- X #>= Y.
n_lt(X,Y) :- X #< Y.
n_gt(X,Y) :- X #> Y.
n_neq(X,Y) :- X \== Y.

eq(X,Y) :- X = Y.
neq(X,Y) :- (number(X) -> n_neq(X,Y) ; X \== Y).

integer_float(N,X) :- X is float(N).
float_integer(N,X) :- X is integer(N).

apply_id(P, A) :- apply(P, A).
apply_forall(G1, A1, G2, A2) :- forall(apply(G1, A1), apply(G2, A2)).
apply_catch(C1,A1,C2) :- C1=closure(P,T1),C2=closure(Q,T2),catch(apply(P,[T1|A1]),E,apply(Q,[T2,E])).

list_of(X, Closure, Args, L) :- Closure = closure(Pred, Env), bagof(X, apply(Pred, [Env | Args]), L).
list_of_atom(X, Pred, Args, L) :- bagof(X, apply(Pred, Args), L).

list_atom_string([], []).
list_atom_string(L1, L2) :-
	L1 = [H | T],
	atom_string(H, H2),
	L2 = [H2 | T2],
	list_atom_string(T, T2).

apply_once(Closure, Args) :-
	Closure=closure(Pred, Env),
	Args2=[Env|Args],
	once(apply(Pred, Args2)).

number_to_string(N,S) :- number_string(N,S).
string_to_number(S,N) :- number_string(N,S).

s_get(L,N,Element) :- nth0(N,L,Element).
s_at(S,N,C) :- sub_string(S,N,1,_,C).
s_size(S,N) :- string_length(S,N).
s_code(S,N) :- var(N) -> (string_code(1, S, N)) ; nonvar(N) -> (_i is integer(N), string_codes(S, [_i])) ; true.
s_codes(S,N) :- string_codes(S, N).
s_slice(S1,I,J,S2) :- s_size(S1,L), (J < L -> End=J ; End=L), sub(End,I,JJ), _i is integer(I), _j is integer(JJ), sub_string(S1,_i,_j,_,S2).
s_first(S1,S2) :- s_at(S1, 0, S2).
s_le(S1,S2) :- S1 @=< S2.

functor_info(F, Name, Terms) :- F =.. [Name|Terms].

slice1([H|_], 1, 1, [H]).
slice1([H|T], 1, To, [H|X]) :-
        N #= To - 1,
        slice1(T, 1, N, X).

slice1([_|T], From, To, L) :-
        N #= From - 1,
        M #= To - 1,
        slice1(T, N, M, L).

slice([H|_], 0, 0, []).
slice([H|_], 0, 1, [H]).
slice([H|T], 0, To, L2) :-
	N #= To - 1,
	slice(T, 0, N, X),
	L2=[H|X].

slice([_|T], From, To, L) :-
	N #= From - 1,
	M #= To - 1,
	slice(T, N, M, L).

replace_word(Old, New, Orig, Replaced) :-
    atomic_list_concat(Split, Old, Orig),
    atomic_list_concat(Split, New, Replaced).
	
% records %

new(T) :-
	empty_assoc(T).

get(T, Key, Value) :-
	get_assoc(Key, T, Value).
	
get_binding(B, Key, Value) :-
	B=Key-Value.
	
set(T, Key, Value, T2) :-
	put_assoc(Key, T, Value, T2).

each(T, P, T2) :-
	map_assoc(P, T2).

fopen(Filename,Mode,File) :-
	(Mode="read" -> open(Filename,read,File) ;
		(Mode="write" -> open(Filename,write,File) ;
			(Mode="update" -> open(Filename,update,File) ; throw("not a correct mode for 'open'.")))).
	
ioread(S) :- read_string(user_input,"\n","\r",_,S).
fread(F,S) :- read_string(F,"\n","\r",_,S).
fread_all(F,S) :- read_string(F,"","",_,S).
fread_char(F,S) :- read_string(F,1,S).
fread_custom(F,A,B,C,S) :- read_string(F,A,B,C,S).

% global(X) :- new(G1), G1=X.

% generic_call(Env,Obj,Method,Arg) :- global_call(Obj,Method,Arg) -> true ; get(Env,Obj,_t2),Arg2=[_t2|Arg],obj_call(Env,Obj,Method,Arg2).
obj_call2(Env,Obj,Method,Arg) :- get(Env,Obj,_t1), get(_t1,Method,_t2), apply(_t2, [_t1|Arg]).
obj_call(Env,Obj,Method,Arg) :- get(Env,Obj,_t1), get(_t1,Method,_t2), apply(_t2, Arg).
env_call(Env,Method,Arg) :- get(Env,Method,_t2), apply(_t2, Arg).
obj_get(Env,Obj,Method,X) :- get(Env,Obj,_t1), get(_t1,Method,X).
env_get(Env,Method,X) :- get(Env,Method,X).

% global_call(Obj,Method,Arg) :- global(G), get(G,Obj,_t1), get(_t1,Method,_t2), apply(_t2, Arg).
closure_call(Env,Closure,Arg) :- closure(Method,MethodEnv)=Closure, _t2=Method, Arg2=[MethodEnv|Arg], apply(_t2, Arg2).
% closure_name_call(Env,ClosureName,Arg) :- get(Env,ClosureName,C), closure(Method,MethodEnv)=C, _t2=Method, writeln(_t2), append([MethodEnv],Arg,Arg2), writeln(Arg2), apply(_t2, Arg2).

:- ensure_loaded("list.pl").
:- ensure_loaded("string.pl").
:- ensure_loaded("math.pl").
:- ensure_loaded("io.pl").
:- ensure_loaded("logic.pl").
:- ensure_loaded("table.pl").

custom_var(Name, X) :- (write(Name), write(" = "), (logic_env(T),logic_toString(T,X,S), write(S))).
custom_vars(N,A) :- A = [] -> write("true") ;
	(A = [H] -> (N=[NH|_], custom_var(NH,H), write("")) ; 
		(A = [H|T], N=[NH|NT], custom_var(NH,H), write(" and "), custom_vars(NT,T))).
custom_vars0(N,A) :- write("| "), custom_vars(N,A), writeln("").
apply_forall_custom_vars(G1, N, A1) :- forall(apply(G1, A1), apply(custom_vars0, [N,A1])).