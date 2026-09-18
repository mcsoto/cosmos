% Null
% Op Functor;TList Functor Functor;Func Functor;ObjGet2 Functor;ObjGet Functor;Id Functor;Str Functor;Num Functor;Fact Functor;Rel Functor;Size Functor;Mutable Functor;Declaration Functor;Once Functor;Host Functor;Op Functor;SoftCut Functor;Cond Functor;If Functor;ObjPred Functor;Bracket Functor;Or Functor;And Functor;Pred Functor;False Functor;True Functor;Inequality Functor;Stm2 Functor;Stm Functor;Neq Functor;Eq Functor;T Functor;Pair Functor;Info Functor;Token Functor;Cons Functor
% lug
% custom_throw
lug_custom_throw(_msg,_info,_upvals):-_upvals=[],(((ground(_info))->(_info = fc_Info(_line,_col),calc("(line "+_line,T10),calc(T10+", col ",T11),calc(T11+_col,T12),calc(T12+") ",T13),calc(T13+_msg,T14),str(T14,T15),throw(T15));(throw(_msg)))).
% debug
lug_debug(_x,_upvals):-_upvals=[],(writeln_(_x)).
% debug_write
lug_debug_write(_x,_upvals):-_upvals=[],(get_(_io,"write",T2),_T1 = T2,call_cl(_T1,[_x])).
% main
lug(X):-_debug_write = clos([],lug_debug_write),_debug = clos([],lug_debug),creq1("logic",_logic,T3),call(T3,_logic),creq1("table",_table,T4),call(T4,_table),creq1("list",_list,T5),call(T5,_list),creq1("string",_string,T6),call(T6,_string),creq1("env4",_Env,T7),call(T7,_Env),creq1("types2",_types,T8),call(T8,_types),creq1("mutable",_mutable,T9),call(T9,_mutable),_custom_throw = clos([],lug_custom_throw),get_(_logic,"path",T18),_T17 = T18,call_cl(_T17,[_T16]),writeln_(_T16).