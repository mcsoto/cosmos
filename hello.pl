%main Relation Any
:- style_check([-singleton,-no_effect]), ensure_loaded("core.pl").
hello_main(Env0,_x) :- obj_call2(Env0,"io","writeln",["hello"]),fd_neq(_x,2),eq(_x,3).
hello_env(X) :- new(X0),set(X0,"main",hello_main,X1),list_env(Y1),set(X1,"list",Y1,X2),string_env(Y2),set(X2,"string",Y2,X3),math_env(Y3),set(X3,"math",Y3,X4),io_env(Y4),set(X4,"io",Y4,X5),logic_env(Y5),set(X5,"logic",Y5,X6),set(X6,"Some",hello_Some,X7),set(X7,"None",hello_None,X8),set(X8,"Left",hello_Left,X9),set(X9,"Right",hello_Right,X10),X=X10.