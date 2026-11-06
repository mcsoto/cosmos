:- style_check(-singleton).
protoship([]):-cosmos_require("table",A),cosmos_require("object",B),(cosmos_receiver("table",A),cosmos_get(A,"update",C),D=C),(new(E),set_(E,"x",1.0,F),set_(F,"y",1.0,G),set_(G,"move",clos(upvals([]),'protoship::$closure_0.0'),H),I=H),J=I,(cosmos_receiver("math",K),cosmos_method_value(K,"range",[1.0,4.0],L)),cosmos_for(L,clos(upvals([I]),'protoship::$closure_1.0'),[J],[M]).
'protoship::$closure_0.0'(A,B,C,D,upvals([])):-new(E),set_(E,"x",B,F),set_(F,"y",C,G),add_(A,G,H),D=H.
'protoship::$closure_1.0'(A,B,[C],D,upvals([E])):-((cosmos_get(C,"x",F),print(F)),((cosmos_get(C,"x",G),add_(G,1.0,H),cosmos_method_value(E,"move",[C,H,1.0],I),J=I),K=J),print(C)),D=[J],K=J.
