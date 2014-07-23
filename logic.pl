%toString Relation Any String;instantied Relation Any;type Relation Any Any;throw Relation Any;iterate Relation Relation Integer Any Any;applyCatch Relation Relation Functor Relation;applyOnce Relation Relation Functor;apply Relation Relation Functor;listOf Relation Any Relation Any Functor
:- style_check([-singleton,-no_effect]), ensure_loaded("core.pl").
logic0(Env0,_b,_s) :- get_binding(_b,_key,_value),env_call(Env0,"toString",[Env0,_key,_s1]),env_call(Env0,"toString",[Env0,_value,_s2]),dynamic_add(_s1," = ",T11),dynamic_add(T11,_s2,T10),eq(_s,T10).
:- ensure_loaded("list.pl").
:- ensure_loaded("string.pl").
:- ensure_loaded("math.pl").
logic_listOf(Env0,_x,_p,_args,_l) :- list_of(_x,_p,_args,_l).
logic_apply(Env0,_p,_l) :- apply(_p,_l).
logic_applyOnce(Env0,_p,_l) :- apply_once(_p,_l).
logic_applyCatch(Env0,_p,_l,_q) :- apply_catch(_p,_l,_q).
logic_iterate(Env0,_p,_n,_x,_y) :- (((eq(_n,0)),eq(_y,_x));(closure_call(Env0,_p,[_x,_x2]),fd_sub(_n,1,T1),env_call(Env0,"iterate",[Env0,_p,T1,_x2,_y]))).
logic_throw(Env0,_x) :- throw(_x).
logic_type(Env0,_x,_y) :- nonvar(_x),(((number(_x)),eq(_y,"Number"));((string(_x)),eq(_y,"String"));((is_list(_x)),eq(_y,"List"));((compound(_x);atom(_x);eq(_x,[])),eq(_y,"Functor"));((nonvar(_x),is_assoc(_x)),eq(_y,"Record"));(eq(_y,"Any"))).
logic_instantied(Env0,_x) :- var(_x).
logic_toString(Env0,_x,_s) :- once((((is_list(_x)),env_get(Env0,"toString",T2),obj_call2(Env0,"list","map",[_x,closure(T2,Env0),_l2]),obj_call2(Env0,"list","join",[_l2,", ",_s0]),string_concat("[",_s0,T4),dynamic_add(T4,"]",T3),eq(_s,T3));((compound(_x),atom_string(_atom,"closure"),functor(_x,_atom,_)),eq(_s,"#relation"));((var(_x)),eq(_s,"#var"));((is_assoc(_x)),eq(_bindingToString,closure(logic0,Env0)),assoc_to_list(_x,_l),obj_call2(Env0,"list","map",[_l,_bindingToString,_l2]),obj_call2(Env0,"list","join",[_l2," and ",_s0]),string_concat("{ ",_s0,T6),dynamic_add(T6," }",T5),eq(_s,T5));((atom(_x)),atom_string(_x,_s0),(((obj_call2(Env0,"string","slice",[_s0,0,2,"fc"])),obj_call2(Env0,"string","size",[_s0,T7]),obj_call2(Env0,"string","slice",[_s0,2,T7,_s]));(eq(_s,"#relation"))));((compound(_x)),functor(_x,_s0,_),obj_call2(Env0,"string","size",[_s0,T8]),obj_call2(Env0,"string","slice",[_s0,2,T8,_name]),dynamic_add(_name,"(~)",T9),eq(_s,T9));(eq(_s,_x)))).
logic_env(X) :- new(X0),set(X0,"toString",logic_toString,X1),set(X1,"instantied",logic_instantied,X2),set(X2,"type",logic_type,X3),set(X3,"throw",logic_throw,X4),set(X4,"iterate",logic_iterate,X5),set(X5,"applyCatch",logic_applyCatch,X6),set(X6,"applyOnce",logic_applyOnce,X7),set(X7,"apply",logic_apply,X8),set(X8,"listOf",logic_listOf,X9),math_env(Y9),set(X9,"math",Y9,X10),string_env(Y10),set(X10,"string",Y10,X11),list_env(Y11),set(X11,"list",Y11,X12),set(X12,"Some",logic_Some,X13),set(X13,"None",logic_None,X14),set(X14,"Left",logic_Left,X15),set(X15,"Right",logic_Right,X16),X=X16.