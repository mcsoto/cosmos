%toListValues Relation Table Functor;toListKeys Relation Table Functor;set Relation Table Any Any Table;get Relation Table Any Table
:- style_check([-singleton,-no_effect]), ensure_loaded("core.pl").
table_get(Env0,_t,_i,_t2) :- get(_t,_i,_t2).
table_set(Env0,_t,_i,_x,_t2) :- set(_t,_i,_x,_t2).
table_toListKeys(Env0,_t,_l) :- assoc_to_keys(_t,_l).
table_toListValues(Env0,_t,_l) :- assoc_to_values(_t,_l).
table_env(X) :- new(X0),set(X0,"toListValues",table_toListValues,X1),set(X1,"toListKeys",table_toListKeys,X2),set(X2,"set",table_set,X3),set(X3,"get",table_get,X4),set(X4,"Some",table_Some,X5),set(X5,"None",table_None,X6),set(X6,"Left",table_Left,X7),set(X7,"Right",table_Right,X8),X=X8.