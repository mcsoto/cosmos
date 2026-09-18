:- style_check(-singleton).
loop3([]):-A=0.0,cosmos_while(clos(upvals([]),'loop3::$closure_0.0'),clos(upvals([B]),'loop3::$closure_1.0'),[A],[C]),print(C).
'loop3::$closure_0.0'([A],upvals([])):-A=0.0.
'loop3::$closure_1.0'([A],B,upvals([C])):-((D=5.0,E=D),print(A)),B=[D],E=D.
