:- style_check(-singleton).
loop1([]):-A=0.0,cosmos_while(clos(upvals([]),'loop1::$closure_0.0'),clos(upvals([]),'loop1::$closure_1.0'),[A],[B]).
'loop1::$closure_0.0'([A],upvals([])):-true.
'loop1::$closure_1.0'([A],B,upvals([])):-((C=2.0,D=C),A=0.0,true),B=[C],D=C.
