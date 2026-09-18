% Table {generate.Relation Any Any Any Functor String;generate_body.Any;generate_world.Any;header.Any;new_env.Any;run.Relation Any Any Any Any Any Any}
% Op Functor;TList Functor Functor;Func Functor;ObjGet2 Functor;ObjGet Functor;Id Functor;Str Functor;Num Functor;Fact Functor;Rel Functor;Size Functor;Mutable Functor;Declaration Functor;Once Functor;Host Functor;Op Functor;SoftCut Functor;Cond Functor;If Functor;ObjPred Functor;Bracket Functor;Or Functor;And Functor;Pred Functor;False Functor;True Functor;Inequality Functor;Stm2 Functor;Stm Functor;Neq Functor;Eq Functor;T Functor;Pair Functor;Info Functor;Token Functor;Cons Functor
% genlug
% generate_
genlug_generate_(_fname,_env,_env2,_f,_code,_upvals):-_upvals=[_generate],(call_cl(_generate,[_f,_code,_fname,_env,_env2,_module])).
% run
genlug_run(_e,_e2,_module,_fname,_f2,_s2,_upvals):-_upvals=[_generate],(call_cl(_generate,[_f2,_s2,_fname,_e,_e2,_x]),_module = _x).
% eval
genlug_eval(_fname,_upvals):-_upvals=[_debug,_debug],(_module = _fname,call_cl(_debug,["--"]),ensure_loaded(_fname),atom_string(_X,_fname),call_cl(_debug,[_X]),call(_X,_)).
% generate_body
genlug_generate_body(_env,_env2,_f,_code,_upvals):-_upvals=[_custom_throw,_debug,_debug_write],(call_cl(_debug_write,["- "]),call_cl(_debug,[_f]),def(_f),((_f = fc_And(_a,_b,_line))->(call(genlug_generate_body(_a,_s1,_env,_temp),_upvals),call(genlug_generate_body(_b,_s2,_temp,_env2),_upvals));((_f = fc_And(_a,_b))->(call(genlug_generate_body(_a,_s1,_env,_temp),_upvals),call(genlug_generate_body(_b,_s2,_temp,_env2),_upvals),calc(_s1+",",T38),calc(T38+_s2,T39),_code = T39);((_f = fc_Or(_a,_b))->(call(genlug_generate_body(_a,_s1,_env,_env_a),_upvals),call(genlug_generate_body(_b,_s2,_env_a,_env2),_upvals),calc("("+_s1,T40),calc(T40+";",T41),calc(T41+_s2,T42),calc(T42+")",T43),_code = T43);((_f = fc_Fact(_name,_args,_info))->(true);(call_cl(_custom_throw,["cannot compile code (could not find the above term)",_info]))))))).
% generate
genlug_generate(_f,_code,_fname,_env,_env2,_module,_upvals):-_upvals=[],(true).
% notblank
genlug_notblank(_s,_upvals):-_upvals=[],(dif(_s,"")).
% sym
genlug_sym(_c,_upvals):-_upvals=[_gensym],(call_cl(_gensym,["T",_c])).
% genstr
genlug_genstr(_o,_s2,_upvals):-_upvals=[_gensym],(call_cl(_gensym,["T",_s]),_o = fc_Id(_s,[]),calc("_"+_s,T37),_s2 = T37).
% genvar
genlug_genvar(_x,_upvals):-_upvals=[_gensym],(call_cl(_gensym,["T",_c]),_x = fc_Id(_c,[])).
% gensym
genlug_gensym(_prefix,_x,_upvals):-_upvals=[],(gensym(_prefix,_x)).
% double_string
genlug_double_string(_s1,_s2,_upvals):-_upvals=[_str,_string],(get_(_string,"slice",T34),_T33 = T34,{_s1-1.0=T36},size_(T36,_T35),call_cl(_T33,[_s1,1.0,_T35,_sa]),call_cl(_str,[_sa,_s2])).
% remove_double_string
genlug_remove_double_string(_s1,_sa,_upvals):-_upvals=[_string,_string],(get_(_string,"slice",T28),_T27 = T28,get_(_string,"size",T31),_T30 = T31,call_cl(_T30,[_s1,_T29]),{_T29-1.0=T32},call_cl(_T27,[_s1,1.0,T32,_sa])).
% str
genlug_str(_s,_s1,_upvals):-_upvals=[_double_quote],(call_cl(_double_quote,[_c]),calc(_c+_s,T25),calc(T25+_c,T26),_s1 = T26).
% double_quote
genlug_double_quote(_c,_upvals):-_upvals=[_string],(get_(_string,"code",T24),_T23 = T24,call_cl(_T23,[_c,34.0])).
% single_quote
genlug_single_quote(_c,_upvals):-_upvals=[_string],(get_(_string,"code",T22),_T21 = T22,call_cl(_T21,[_c,39.0])).
% custom_throw
genlug_custom_throw(_msg,_info,_upvals):-_upvals=[],(((ground(_info))->(_info = fc_Info(_line,_col),calc("(line "+_line,T10),calc(T10+", col ",T11),calc(T11+_col,T12),calc(T12+") ",T13),calc(T13+_msg,T14),str(T14,T15),throw(T15));(throw(_msg)))).
% debug
genlug_debug(_s,_upvals):-_upvals=[_debug_write,_debug_write],(call_cl(_debug_write,[_s]),call_cl(_debug_write,["\n"])).
% debug
genlug_debug(_x,_upvals):-_upvals=[],(writeln_(_x)).
% debug_write
genlug_debug_write(_x,_upvals):-_upvals=[],(get_(_io,"write",T2),_T1 = T2,call_cl(_T1,[_x])).
% main
genlug(X):-_debug_write = clos([],genlug_debug_write),_debug = clos([],genlug_debug),_debug = clos([_debug_write,_debug_write],genlug_debug),creq1("logic",_logic,T3),call(T3,_logic),creq1("table",_table,T4),call(T4,_table),creq1("list",_list,T5),call(T5,_list),creq1("string",_string,T6),call(T6,_string),creq1("env4",_Env,T7),call(T7,_Env),creq1("types2",_types,T8),call(T8,_types),creq1("mutable",_mutable,T9),call(T9,_mutable),_custom_throw = clos([],genlug_custom_throw),get_(_table,"set",T16),_set = T16,get_(_table,"get",T17),_get = T17,get_(_list,"has",T18),_has = T18,get_(_logic,"halt",T19),_halt = T19,new(T20),_nil = T20,_single_quote = clos([_string],genlug_single_quote),_double_quote = clos([_string],genlug_double_quote),_str = clos([_double_quote],genlug_str),_remove_double_string = clos([_string,_string],genlug_remove_double_string),_double_string = clos([_str,_string],genlug_double_string),_gensym = clos([],genlug_gensym),_genvar = clos([_gensym],genlug_genvar),_genstr = clos([_gensym],genlug_genstr),_sym = clos([_gensym],genlug_sym),_notblank = clos([],genlug_notblank),_generate = clos([],genlug_generate),_generate_body = clos([_custom_throw,_debug,_debug_write],genlug_generate_body),_eval = clos([_debug,_debug],genlug_eval),_run = clos([_generate],genlug_run),_generate_ = clos([_generate],genlug_generate_),new(T44),set_(T44,"generate_body",_generate_body_,T46),set_(T46,"generate_world",_generate_world,T47),set_(T47,"run",_run,T48),set_(T48,"generate",_generate_,T49),set_(T49,"new_env",_new_env,T50),set_(T50,"header",_header,T45),_t = T45,call_cl(_debug,[_t]),X=_t.