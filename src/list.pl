%fold Relation Functor (Relation Any Any Any) Any Any;join Relation Functor String String;filter Relation Functor (Relation Any) Functor;every Relation Functor (Relation Any);map Relation Functor (Relation Any Any) Functor;each Relation Functor (Relation Integer Any Any) Functor;eachIndex Relation Any Any Any Any;reverse Relation Functor Functor;concat Relation Functor Functor Functor;has Relation Functor Any;find Relation Functor Any Integer;slice Relation Functor Integer Integer Functor;pop Relation Functor Functor;push Relation Functor Any Functor;last Relation Functor Any;size Relation Functor Integer;rest Relation Functor Any;first Relation Functor Any;get Relation Functor Integer Any
:- style_check([-singleton,-no_effect]), ensure_loaded("core.pl").
:- ensure_loaded("string.pl").
list_get(Env0,_L,_N,_Element) :- nth0(_N,_L,_Element).
list_first(Env0,_l,_a) :- eq(_l, '[|]'(_a,_)).
list_rest(Env0,_l,_b) :- eq(_l, '[|]'(_,_b)).
list_size(Env0,_l,_n) :- length(_l,_n).
list_last(Env0,_l,_a) :- env_call(Env0,"size",[Env0,_l,T2]),fd_sub(T2,1,T1),env_call(Env0,"get",[Env0,_l,T1,_a]).
list_push(Env0,_l,_x,_l2) :- eq(_l2, '[|]'(_x,_l)).
list_pop(Env0,_l,_l2) :- eq(_l, '[|]'(_x,_tail)),eq(_l2,_tail).
list_slice(Env0,_l,_i,_j,_l2) :- once(slice(_l,_i,_j,_l2)).
list_find(Env0,_l,_element,_i) :- (((env_call(Env0,"first",[Env0,_l,_element])),eq(_i,0));(env_call(Env0,"rest",[Env0,_l,_tail]),env_call(Env0,"find",[Env0,_tail,_element,_j]),fd_add(_j,1,T3),eq(_i,T3))).
list_has(Env0,_l,_x) :- env_call(Env0,"find",[Env0,_l,_x,_]).
list_concat(Env0,_l,_l2,_l3) :- append(_l,_l2,_l3).
list_reverse(Env0,_l,_l2) :- (((eq(_l, '[|]'(_a,_tail))),env_call(Env0,"reverse",[Env0,_tail,_ltemp]),env_call(Env0,"concat",[Env0,_ltemp, '[|]'(_a,[]),_l2]));(eq(_l,[]),eq(_l2,[]))).
list_eachIndex(Env0,_l,_p,_i,_l2) :- (((eq(_l,[])),eq(_l2,[]));(eq(_l, '[|]'(_head,_tail)),eq(_l2, '[|]'(_head2,_tail2)),closure_call(Env0,_p,[_i,_head,_head2]),fd_add(_i,1,T4),env_call(Env0,"eachIndex",[Env0,_tail,_p,T4,_tail2]))).
list_each(Env0,_l,_p,_l2) :- env_call(Env0,"eachIndex",[Env0,_l,_p,0,_l2]).
list_map(Env0,_l,_p,_l2) :- (((eq(_l,[])),eq(_l2,[]));(eq(_l, '[|]'(_head,_tail)),eq(_l2, '[|]'(_head2,_tail2)),closure_call(Env0,_p,[_head,_head2]),env_call(Env0,"map",[Env0,_tail,_p,_tail2]))).
list_every(Env0,_l,_p) :- (((eq(_l,[])),eq(_l2,[]));(eq(_l, '[|]'(_head,_tail)),closure_call(Env0,_p,[_head]),env_call(Env0,"every",[Env0,_tail,_p]))).
list_filter(Env0,_l,_p,_l2) :- (((eq(_l,[])),eq(_l2,[]));(eq(_l, '[|]'(_head,_tail)),(((closure_call(Env0,_p,[_head])),eq(_l2, '[|]'(_head,_tail2)),env_call(Env0,"filter",[Env0,_tail,_p,_tail2]));(env_call(Env0,"filter",[Env0,_tail,_p,_l2]))))).
list_join(Env0,_l,_sep,_s) :- (((eq(_l, '[|]'(_a,[]))),eq(_s,_a));((eq(_l, '[|]'(_s1,_tail))),env_call(Env0,"join",[Env0,_tail,_sep,_s2]),obj_call2(Env0,"string","concat",[_s1,_sep,_temp]),obj_call2(Env0,"string","concat",[_temp,_s2,_s]));(eq(_l,[]),eq(_s,""))).
list_fold(Env0,_l,_pred,_a,_result) :- (((eq(_l, '[|]'(_b,_tail))),closure_call(Env0,_pred,[_a,_b,_c]),env_call(Env0,"fold",[Env0,_tail,_pred,_c,_result]));(eq(_l,[]),eq(_result,_a))).
list_env(X) :- new(X0),set(X0,"fold",list_fold,X1),set(X1,"join",list_join,X2),set(X2,"filter",list_filter,X3),set(X3,"every",list_every,X4),set(X4,"map",list_map,X5),set(X5,"each",list_each,X6),set(X6,"eachIndex",list_eachIndex,X7),set(X7,"reverse",list_reverse,X8),set(X8,"concat",list_concat,X9),set(X9,"has",list_has,X10),set(X10,"find",list_find,X11),set(X11,"slice",list_slice,X12),set(X12,"pop",list_pop,X13),set(X13,"push",list_push,X14),set(X14,"last",list_last,X15),set(X15,"size",list_size,X16),set(X16,"rest",list_rest,X17),set(X17,"first",list_first,X18),set(X18,"get",list_get,X19),string_env(Y19),set(X19,"string",Y19,X20),table_env(Y20),set(X20,"table",Y20,X21),list_env(Y21),set(X21,"list",Y21,X22),string_env(Y22),set(X22,"string",Y22,X23),math_env(Y23),set(X23,"math",Y23,X24),io_env(Y24),set(X24,"io",Y24,X25),logic_env(Y25),set(X25,"logic",Y25,X26),set(X26,"Some",list_Some,X27),set(X27,"None",list_None,X28),set(X28,"Left",list_Left,X29),set(X29,"Right",list_Right,X30),X=X30.