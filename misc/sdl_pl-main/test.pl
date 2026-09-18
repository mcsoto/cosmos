% Null
%
% module
% 8
test_8(_w,_w2,_upvals):-_upvals=[_set,_set,_sp,_img,_sp,_sp,_clear],(get_(_w,"player",T45),T45 = _o,get_(_w,"dir",T46),T46 = _dir,get_(_w,"entities",T47),T47 = _ents,((_dir = "left")->(get_(_o,"x",T48),{T48-1.0=T49},_nx = T49);(get_(_o,"x",T50),calc(T50+1.0,T51),_nx = T51)),call_cl(_clear,[]),get_(_sp,"setRGB",T53),_T52 = T53,call_cl(_T52,[0.0,0.0,0.0]),get_(_sp,"drawImage",T55),_T54 = T55,get_(_o,"x",T56),call_cl(_T54,[_img,T56,100.0]),get_(_sp,"refresh",T58),_T57 = T58,call_cl(_T57,[]),call_cl(_set,[_o,"x",_nx,_o2]),call_cl(_set,[_w,"player",_o2,_w2]),true).
% 7
test_7(_key,_s,_s2,_upvals):-_upvals=[_set,_set],(writeln_(_key),writeln_('[|]'("state",'[|]'(_s,'[|]'(_s2,[])))),((_key = "right",call_cl(_set,[_s,"dir",_key,_s2]),writeln_("key"),true);(dif(_key,"right"),(_key = "left",call_cl(_set,[_s,"dir",_key,_s2]));(dif(_key,"left"),(_key = "escape",halt);(dif(_key,"escape"),_s2 = _s))))).
% 6
test_6(_x,_y,_s,_s,_upvals):-_upvals=[],(writeln_('[|]'(_x,'[|]'(_y,[]))),writeln_('[|]'("state",'[|]'(_s,'[|]'(_s2,[]))))).
% load
test_load(_o,_upvals):-_upvals=[_makeball,_player],(call_cl(_makeball,[0.0,0.0,_T27]),_o = '[|]'(_player,'[|]'(_T27,'[|]'("right",[])))).
% makeball
test_makeball(_x,_y,_o,_upvals):-_upvals=[],(new(T24),set_(T24,"x",10.0,T26),set_(T26,"y",0.0,T25),_o = T25).
% 5
test_5(_x,_nx,_upvals):-_upvals=[],(true).
% move
test_move(_o,_o2,_upvals):-_upvals=[_set],(((_dir = "left")->(get_(_o,"x",T14),{T14-1.0=T15},_nx = T15);(get_(_o,"x",T16),calc(T16+1.0,T17),_nx = T17)),call_cl(_set,[_o,"x",_nx,_o2])).
% clear
test_clear(_upvals):-_upvals=[_sp,_sp],(get_(_sp,"setRGBA",T11),_T10 = T11,call_cl(_T10,[255.0,255.0,255.0,255.0]),get_(_sp,"clear",T13),_T12 = T13,call_cl(_T12,[])).
% 4
test_4(_o,_y,_upvals):-_upvals=[],(get_(_o,"name",T8),nb_getval(T8,_y)).
% 3
test_3(_o,_y,_upvals):-_upvals=[],(get_(_o,"name",T7),nb_setval(T7,_y)).
% 2
test_2(_val,_o,_upvals):-_upvals=[],(gensym("var",_x),new(T4),set_(T4,"name",_x,T5),_o = T5,nb_setval(_x,_val)).
% main
test(X):-creq("space",_sp),creq("mutable",_mutable),creq("table",_table),creq("list",_list),new(T1),set_(T1,"new",clos([],test_2),T3),set_(T3,"set",clos([],test_3),T6),set_(T6,"get",clos([],test_4),T2),_Var = T2,writeln_(_img),get_(_table,"set",T9),_set = T9,_clear = clos([_sp,_sp],test_clear),_move = clos([_set],test_move),new(T18),set_(T18,"move",clos([],test_5),T19),_Entity = T19,new(T20),set_(T20,"x",10.0,T22),set_(T22,"y",0.0,T23),set_(T23,"speed",1.0,T21),_player = T21,_makeball = clos([],test_makeball),_load = clos([_makeball,_player],test_load),call_cl(_load,[_T28]),_entities = _T28,new(T29),set_(T29,"entities",_entities,T31),set_(T31,"player",_player,T32),set_(T32,"dir","right",T30),_world = T30,get_(_sp,"init",T33),writeln_(T33),get_(_sp,"init",T35),_T34 = T35,call_cl(_T34,[600.0,450.0]),writeln_("-"),get_(_sp,"loadImage",T38),_T37 = T38,call_cl(_T37,["b1.png",_T36]),_img = _T36,writeln_(_list),get_(_sp,"start",T40),_T39 = T40,new(T41),set_(T41,"mouseup",clos([],test_6),T43),set_(T43,"keypressed",clos([_set,_set],test_7),T44),set_(T44,"update",clos([_set,_set,_sp,_img,_sp,_sp,_clear],test_8),T42),call_cl(_T39,[500.0,T42,_world]),writeln_("-").