%toString Relation Any String;instantied Relation Any;type Relation Any Any;iterate Relation Relation Integer Any Any;applyCatch Relation Relation Functor Relation;applyOnce Relation Relation Functor;apply Relation Relation Functor;between Relation Any Any Any;listOf Relation Any Relation Any Functor;exit Relation;throw Relation Any
:- style_check([-singleton,-no_effect]), ensure_loaded("core.pl").
logic0(Env0,_b,_s) :- get_binding(_b,_key,_value),env_call(Env0,"toString",[Env0,_key,T19]),string_concat(T19," = ",T18),env_call(Env0,"toString",[Env0,_value,T20]),dynamic_add(T18,T20,T17),eq(_s,T17).
:- ensure_loaded("list.pl").
:- ensure_loaded("string.pl").
:- ensure_loaded("math.pl").
logic_throw(Env0,_x) :- throw(_x).
logic_exit(Env0) :- halt.
logic_listOf(Env0,_x,_p,_args,_l) :- list_of(_x,_p,_args,_l).
logic_between(Env0,_i,_j,_x) :- between(_i,_j,_x).
logic_apply(Env0,_p,_l) :- apply(_p,_l).
logic_applyOnce(Env0,_p,_l) :- apply_once(_p,_l).
logic_applyCatch(Env0,_p,_l,_q) :- apply_catch(_p,_l,_q).
logic_iterate(Env0,_p,_n,_x,_y) :- (((eq(_n,0)),eq(_y,_x));(closure_call(Env0,_p,[_x,_x2]),fd_sub(_n,1,T1),env_call(Env0,"iterate",[Env0,_p,T1,_x2,_y]))).
logic_type(Env0,_x,_y) :- nonvar(_x),(((number(_x)),eq(_y,"Number"));((string(_x)),eq(_y,"String"));((is_list(_x)),eq(_y,"List"));((is_assoc(_x)),eq(_y,"Record"));((compound(_x);atom(_x);eq(_x,[])),eq(_y,"Functor"));(eq(_y,"Any"))).
logic_instantied(Env0,_x) :- var(_x).
logic_toString(Env0,_x,_s) :- once((((is_list(_x)),env_get(Env0,"toString",T2),obj_call2(Env0,"list","map",[_x,closure(T2,Env0),_l2]),obj_call2(Env0,"list","join",[_l2,", ",_s0]),string_concat("[",_s0,T4),dynamic_add(T4,"]",T3),eq(_s,T3));((compound(_x),atom_string(_atom,"closure"),functor(_x,_atom,_)),eq(_s,"#relation"));((var(_x)),eq(_s,"#var"));((is_assoc(_x)),eq(_bindingToString,closure(logic0,Env0)),assoc_to_list(_x,_l),obj_call2(Env0,"list","map",[_l,_bindingToString,T5]),obj_call2(Env0,"list","join",[T5," and ",_s0]),string_concat("{",_s0,T7),dynamic_add(T7,"}",T6),eq(_s,T6));((atom(_x)),atom_string(_x,_s0),(((obj_call2(Env0,"string","slice",[_s0,0,2,"fc"])),obj_call2(Env0,"string","size",[_s0,T8]),obj_call2(Env0,"string","slice",[_s0,2,T8,_s]));(eq(_s,"#relation"))));((compound(_x)),functor_info(_x,_s0,_args),obj_call2(Env0,"string","size",[_s0,T13]),obj_call2(Env0,"string","slice",[_s0,2,T13,T12]),string_concat(T12,"(",T11),env_get(Env0,"toString",T16),obj_call2(Env0,"list","map",[_args,closure(T16,Env0),T15]),obj_call2(Env0,"list","join",[T15,", ",T14]),dynamic_add(T11,T14,T10),dynamic_add(T10,")",T9),eq(_s,T9));((number(_x)),number_string(_x,_s));(eq(_s,_x)))).
logic_env(X) :- new(X0),set(X0,"toString",logic_toString,X1),set(X1,"instantied",logic_instantied,X2),set(X2,"type",logic_type,X3),set(X3,"iterate",logic_iterate,X4),set(X4,"applyCatch",logic_applyCatch,X5),set(X5,"applyOnce",logic_applyOnce,X6),set(X6,"apply",logic_apply,X7),set(X7,"between",logic_between,X8),set(X8,"listOf",logic_listOf,X9),set(X9,"exit",logic_exit,X10),set(X10,"throw",logic_throw,X11),math_env(Y11),set(X11,"math",Y11,X12),string_env(Y12),set(X12,"string",Y12,X13),list_env(Y13),set(X13,"list",Y13,X14),set(X14,"Some",logic_Some,X15),set(X15,"None",logic_None,X16),set(X16,"Left",logic_Left,X17),set(X17,"Right",logic_Right,X18),X=X18.