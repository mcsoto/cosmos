% Null
%
% module
% 7
test1_7(_x,_y,_upvals):-_upvals=[_sp,_sp,_sp,_img,_sp,_sp,_clear],(calc(_x+1.0,T29),_y = T29,call_cl(_clear,[]),get_(_sp,"setRGBA",T31),_T30 = T31,call_cl(_T30,[0.0,0.0,0.0,255.0]),get_(_sp,"drawImage",T33),_T32 = T33,call_cl(_T32,[_img,_x,100.0]),get_(_sp,"rect",T35),_T34 = T35,call_cl(_T34,[_x,0.0,50.0,50.0]),get_(_sp,"test",T37),_T36 = T37,call_cl(_T36,[_a]),get_(_sp,"refresh",T39),_T38 = T39,call_cl(_T38,[]),true).
% 6
test1_6(_key,_s,_s,_upvals):-_upvals=[],(writeln_(_key),((_key = "escape",halt);(dif(_key,"escape"),true)),true).
% 5
test1_5(_x,_y,_s,_s,_upvals):-_upvals=[],(writeln_('[|]'(_x,'[|]'(_y,'[|]'(_s,'[|]'(_s2,[])))))).
% clear
test1_clear(_upvals):-_upvals=[_sp,_sp],(get_(_sp,"setRGBA",T20),_T19 = T20,call_cl(_T19,[255.0,255.0,255.0,255.0]),get_(_sp,"clear",T22),_T21 = T22,call_cl(_T21,[])).
% 4
test1_4(_o,_y,_upvals):-_upvals=[],(get_(_o,"name",T8),nb_getval(T8,_y)).
% 3
test1_3(_o,_y,_upvals):-_upvals=[],(get_(_o,"name",T7),nb_setval(T7,_y)).
% 2
test1_2(_val,_o,_upvals):-_upvals=[],(gensym("var",_x),new(T4),set_(T4,"name",_x,T5),_o = T5,nb_setval(_x,_val)).
% main
test1(X):-creq("space",_sp),creq("mutable",_mutable),creq("table",_table),new(T1),set_(T1,"new",clos([],test1_2),T3),set_(T3,"set",clos([],test1_3),T6),set_(T6,"get",clos([],test1_4),T2),_Var = T2,get_(_Var,"new",T11),_T10 = T11,call_cl(_T10,['[|]'(1.0,'[|]'(2.0,[])),_T9]),_pos = _T9,get_(_Var,"new",T14),_T13 = T14,call_cl(_T13,["right",_T12]),_dir = _T12,get_(_sp,"init",T16),_T15 = T16,call_cl(_T15,[600.0,450.0]),get_(_sp,"loadImage",T18),_T17 = T18,call_cl(_T17,["b1.png",_img]),writeln_(_img),_clear = clos([_sp,_sp],test1_clear),get_(_sp,"start",T24),_T23 = T24,new(T25),set_(T25,"mouseup",clos([],test1_5),T27),set_(T27,"keypressed",clos([],test1_6),T28),set_(T28,"update",clos([_sp,_sp,_sp,_img,_sp,_sp,_clear],test1_7),T26),call_cl(_T23,[500.0,T26,10.0]).