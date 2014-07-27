%main Relation Any;z Relation Any Any;q Relation String;p Relation Integer
:- style_check([-singleton,-no_effect]), ensure_loaded("core.pl").
:- ensure_loaded("test1.pl").
test0_p(Env0,_x) :- eq(_x,1).
test0_q(Env0,_x) :- eq(_x,"abc").
test0_z(Env0,_fn,_x) :- closure_call(Env0,_fn,[_x]).
test0_main(Env0,_x) :- new(T1),eq(_t,T1),obj_call2(Env0,"table","set",[_t,"a",1,T3]),obj_call2(Env0,"table","set",[T3,"b",2,T2]),eq(_t2,T2),env_get(Env0,"t1",T4),obj_call2(Env0,"io","writeln",[T4]),obj_call2(Env0,"io","writeln",[_t]),obj_call2(Env0,"io","writeln",[_t2]).
test0_env(X) :- new(X0),set(X0,"main",test0_main,X1),set(X1,"z",test0_z,X2),set(X2,"q",test0_q,X3),set(X3,"p",test0_p,X4),test1_env(Y4),set(X4,"t1",Y4,X5),table_env(Y5),set(X5,"table",Y5,X6),list_env(Y6),set(X6,"list",Y6,X7),string_env(Y7),set(X7,"string",Y7,X8),math_env(Y8),set(X8,"math",Y8,X9),io_env(Y9),set(X9,"io",Y9,X10),logic_env(Y10),set(X10,"logic",Y10,X11),set(X11,"Some",test0_Some,X12),set(X12,"None",test0_None,X13),set(X13,"Left",test0_Left,X14),set(X14,"Right",test0_Right,X15),X=X15.