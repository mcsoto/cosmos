%main Relation Any;z Relation Any Any;q Relation String;p Relation Integer
:- style_check([-singleton,-no_effect]), ensure_loaded("core.pl").
:- ensure_loaded("test1.pl").
test0_p(Env0,_x) :- eq(_x,1).
test0_q(Env0,_x) :- eq(_x,"1").
test0_z(Env0,_fn,_x) :- closure_call(Env0,_fn,[_x]).
test0_main(Env0,_x) :- eq(_x,1).
test0_env(X) :- new(X0),set(X0,"main",test0_main,X1),set(X1,"z",test0_z,X2),set(X2,"q",test0_q,X3),set(X3,"p",test0_p,X4),test1_env(Y4),set(X4,"t1",Y4,X5),list_env(Y5),set(X5,"list",Y5,X6),string_env(Y6),set(X6,"string",Y6,X7),math_env(Y7),set(X7,"math",Y7,X8),io_env(Y8),set(X8,"io",Y8,X9),logic_env(Y9),set(X9,"logic",Y9,X10),set(X10,"Some",test0_Some,X11),set(X11,"None",test0_None,X12),set(X12,"Left",test0_Left,X13),set(X13,"Right",test0_Right,X14),X=X14.