% Any
%
% module
% 16
space_16(_a0,_upvals):-_upvals=[],(_a0 = 2.0).
% 15
space_15(_a0,_upvals):-_upvals=[],(int(_a0,X17),sdl_delay(X17)).
% 14
space_14(_a,_a2,_a3,_upvals):-_upvals=[],(start(_a,_a2,_a3)).
% 13
space_13(_upvals):-_upvals=[],(refresh).
% 12
space_12(_upvals):-_upvals=[],(clear).
% 11
space_11(_upvals):-_upvals=[],(readkey).
% 10
space_10(_a,_b,_upvals):-_upvals=[],(int(_b,X16),int(_a,X15),init(X15,X16)).
% 9
space_9(_a0,_a1,_a2,_a3,_upvals):-_upvals=[],(circle(_a0,_a1,_a2,_a3)).
% 8
space_8(_a0,_a1,_a2,_upvals):-_upvals=[],(int(255.0,X14),int(_a2,X13),int(_a1,X12),int(_a0,X11),setRGBA(X11,X12,X13,X14)).
% 7
space_7(_a0,_a1,_a2,_a3,_upvals):-_upvals=[],(int(_a3,X10),int(_a2,X9),int(_a1,X8),int(_a0,X7),setRGBA(X7,X8,X9,X10)).
% 6
space_6(_a0,_a1,_a2,_a3,_upvals):-_upvals=[],(int(_a3,X6),int(_a2,X5),int(_a1,X4),int(_a0,X3),rect(X3,X4,X5,X6)).
% 5
space_5(_a0,_a1,_a2,_upvals):-_upvals=[],(int(_a2,X2),int(_a1,X1),drawImage(_a0,X1,X2)).
% 4
space_4(_a0,_a1,_upvals):-_upvals=[],(loadImage(_a0,_a1)).
% 3
space_3(_a0,_a1,_a2,_a3,_upvals):-_upvals=[],(getpixel(_a0,_a1,_a2,_a3)).
% 2
space_2(_a0,_a1,_a2,_a3,_upvals):-_upvals=[],(putpixel(_a0,_a1,_a2,_a3)).
% main
space(X):-ensure_loaded("sdl.pl"),ensure_loaded("callbacks.pl"),new(T1),set_(T1,"putpixel",clos([],space_2),T3),set_(T3,"getpixel",clos([],space_3),T4),set_(T4,"loadImage",clos([],space_4),T5),set_(T5,"drawImage",clos([],space_5),T6),set_(T6,"rect",clos([],space_6),T7),set_(T7,"setRGBA",clos([],space_7),T8),set_(T8,"setRGB",clos([],space_8),T9),set_(T9,"circle",clos([],space_9),T10),set_(T10,"init",clos([],space_10),T11),set_(T11,"readkey",clos([],space_11),T12),set_(T12,"clear",clos([],space_12),T13),set_(T13,"refresh",clos([],space_13),T14),set_(T14,"start",clos([],space_14),T15),set_(T15,"delay",clos([],space_15),T16),set_(T16,"test",clos([],space_16),T2),_sp = T2,X=_sp.