% Null
%
% module
% load
test3_load(_o,_upvals):-_upvals=[_makeball,_player,_x],(writeln_(_x),call_cl(_makeball,[0.0,0.0,_T33]),_o = '[|]'(_player,'[|]'(_T33,[]))).
% makeball
test3_makeball(_x,_y,_o,_upvals):-_upvals=[_y,_x],(new(T30),set_(T30,"x",10.0,T32),set_(T32,"y",0.0,T31),_o = T31).
% move
test3_move(_o,_o2,_upvals):-_upvals=[_dir,_Var],(get_(_Var,"get",T21),_T20 = T21,call_cl(_T20,[_dir,_T19]),_s = _T19,new(T22),set_(T22,"x",T25,T23),_o2 = T23).
% clear
test3_clear(_upvals):-_upvals=[_sp,_sp],(get_(_sp,"setRGBA",T16),_T15 = T16,call_cl(_T15,[255.0,255.0,255.0,255.0]),get_(_sp,"clear",T18),_T17 = T18,call_cl(_T17,[])).
% 4
test3_4(_o,_y,_upvals):-_upvals=[],(get_(_o,"name",T8),nb_getval(T8,_y)).
% 3
test3_3(_o,_y,_upvals):-_upvals=[],(get_(_o,"name",T7),nb_setval(T7,_y)).
% 2
test3_2(_val,_o,_upvals):-_upvals=[],(gensym("var",_x),new(T4),set_(T4,"name",_x,T5),_o = T5,nb_setval(_x,_val)).
% main
test3(X):-creq("space",_sp),creq("mutable",_mutable),creq("table",_table),new(T1),set_(T1,"new",clos([],test3_2),T3),set_(T3,"set",clos([],test3_3),T6),set_(T6,"get",clos([],test3_4),T2),_Var = T2,get_(_Var,"new",T11),_T10 = T11,call_cl(_T10,['[|]'(1.0,'[|]'(2.0,[])),_T9]),_pos = _T9,get_(_Var,"new",T14),_T13 = T14,call_cl(_T13,["right",_T12]),_dir = _T12,writeln_(_img),_clear = clos([_sp,_sp],test3_clear),_move = clos([_dir,_Var],test3_move),new(T26),set_(T26,"x",10.0,T28),set_(T28,"y",0.0,T29),set_(T29,"speed",1.0,T27),_player = T27,_makeball = clos([_y,_x],test3_makeball),_load = clos([_makeball,_player,_x],test3_load),call_cl(_load,[_T34]),_entities = _T34,writeln_(_entities),_world = _entities,writeln_(1.0).