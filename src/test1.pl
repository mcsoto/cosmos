%z Relation Relation Any;q Relation String;p Relation Integer
:- style_check([-singleton,-no_effect]), ensure_loaded("core.pl").
test1_p(Env0,_i) :- eq(_i,1).
test1_q(Env0,_i) :- eq(_i,"1").
test1_z(Env0,_fn,_x) :- true.
test1_env(X) :- new(X0),set(X0,"z",test1_z,X1),set(X1,"q",test1_q,X2),set(X2,"p",test1_p,X3),list_env(Y3),set(X3,"list",Y3,X4),string_env(Y4),set(X4,"string",Y4,X5),math_env(Y5),set(X5,"math",Y5,X6),io_env(Y6),set(X6,"io",Y6,X7),logic_env(Y7),set(X7,"logic",Y7,X8),set(X8,"Some",test1_Some,X9),set(X9,"None",test1_None,X10),set(X10,"Left",test1_Left,X11),set(X11,"Right",test1_Right,X12),X=X12.