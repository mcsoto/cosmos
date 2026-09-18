:- style_check(-singleton).
ship([]):-cosmos_require("table",A),cosmos_require("object",B),(cosmos_get(B,"update",C),D=C),(new(E),set_(E,"x",1.0,F),set_(F,"y",1.0,G),set_(G,"move",clos(upvals([D]),'ship::$closure_0.0'),H),I=H),(cosmos_method_value(B,"create",[I],J),K=J),((cosmos_receiver("math",L),cosmos_method_value(L,"range",[1.0,4.0],M)),cosmos_for(M,clos(upvals([N]),'ship::$closure_1.0'),[K],[O])),(cosmos_method_value(B,"create",[I],P),O=P),(cosmos_get(O,"y",Q),print(Q)),print(O).
'ship::$closure_0.0'(A,B,C,D,upvals([E])):-once((new(F),set_(F,"x",B,G),set_(G,"y",C,H),call_cl(E,[A,H,D]))).
'ship::$closure_1.0'(A,B,[C],D,upvals([E])):-((cosmos_get(C,"x",F),print(F)),((cosmos_get(C,"x",G),add_(G,1.0,H),cosmos_method_value(C,"move",[H,1.0],I),J=I),K=J),print(C)),D=[J],K=J.
