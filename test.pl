:- style_check(-singleton).
'test::$impl_main'(A):-print(1.0).
test([]):-cosmos_require("test1",A),print(":test:"),B=protocol("Positioned",[],[method("move",[t("mode","Unspecified",>,t,t("type","Any",-,t,t)),t("mode","Unspecified",>,t,t("type","Number",-,t,t)),t("mode","Unspecified",>,t,t("type","Number",-,t,t)),t("mode","Unspecified",>,t,t("type","Any",-,t,t))],deferred)]),(new(C),set_(C,"x",0.0,D),set_(D,"y",0.0,E),set_(E,"new",clos(upvals([]),'test::$closure_0.0'),F),set_(F,"move",clos(upvals([]),'test::$closure_1.0'),G),H=cosmos_class("Point",G)),print(I),(new(J),set_(J,"x",1.0,K),L=K),print(L),(cosmos_update(L,"x",2.0,M),N=M),print(O).
'test::main'(A):-'test::$impl_main'(A).
'test::$value_main'(upvals([A])):-'test::main'(A).
'test::$closure_0.0'(A,B,C,D,upvals([])):-D=A.
'test::$closure_1.0'(A,B,C,D,upvals([])):-new(E),set_(E,"x",B,F),set_(F,"y",C,G),D=G.
