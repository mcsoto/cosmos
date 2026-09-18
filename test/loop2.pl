:- style_check(-singleton).
loop2([]):-A=0.0,cosmos_while(clos(upvals([]),'loop2::$closure_0.0'),clos(upvals([B]),'loop2::$closure_1.0'),[A],[C]),print(C).
'loop2::$closure_0.0'([A],upvals([])):-A=0.0.
'loop2::$closure_2.0'([A,B],upvals([])):-B=2.0.
'loop2::$closure_3.0'([A,B],C,upvals([D])):-((E=5.0,F=E),(G=1.0,H=G),print("|"),print(A),print(B)),C=[E,G],F=E,H=G.
'loop2::$closure_1.0'([A],B,upvals([C])):-(D=2.0,cosmos_while(clos(upvals([]),'loop2::$closure_2.0'),clos(upvals([C]),'loop2::$closure_3.0'),[E,D],[A,F]),print("-"),print(A)),B=[A],G=A.
