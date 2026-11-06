:- style_check(-singleton).
'pathfinder::$impl_horizontal'(A,B,C,D):-if_(A=B,(new(E),set_(E,"x",A,F),set_(F,"y",C,G),D=[G]),(r_lt(A,B),(add_(A,1.0,H),'pathfinder::horizontal'(H,B,C,I)),new(J),set_(J,"x",A,K),set_(K,"y",C,L),D=[L|I];r_ge(A,B),(r_sub(A,1.0,M),'pathfinder::horizontal'(M,B,C,I)),new(N),set_(N,"x",A,O),set_(O,"y",C,P),D=[P|I])).
'pathfinder::$impl_vertical'(A,B,C,D):-if_(B=C,(new(E),set_(E,"x",A,F),set_(F,"y",B,G),D=[G]),(r_lt(B,C),(add_(B,1.0,H),'pathfinder::vertical'(A,H,C,I)),new(J),set_(J,"x",A,K),set_(K,"y",B,L),D=[L|I];r_ge(B,C),(r_sub(B,1.0,M),'pathfinder::vertical'(A,M,C,I)),new(N),set_(N,"x",A,O),set_(O,"y",B,P),D=[P|I])).
'pathfinder::$impl_find'(A,B,C,D,E,F):-'pathfinder::horizontal'(A,C,B,G),'pathfinder::vertical'(C,B,D,H),(add_(G,H,I),E=I),(r_sub(C,A,J),K=J),(r_sub(D,B,L),M=L),(r_lt(K,0.0),r_sub(0.0,K,N),K=N;r_ge(K,0.0),true),(r_lt(M,0.0),r_sub(0.0,M,O),M=O;r_ge(M,0.0),true),add_(K,M,P),F=P.
'pathfinder::$impl_point_at'(A,B,C):-int(B,D),nth0(D,A,C).
pathfinder(A):-new(B),set_(B,"find",clos(upvals([]),'pathfinder::$value_find'),C),set_(C,"pointAt",clos(upvals([]),'pathfinder::$value_point_at'),D),A=D.
'pathfinder::horizontal'(A,B,C,D):-'pathfinder::$impl_horizontal'(A,B,C,D).
'pathfinder::$value_horizontal'(A,B,C,D,upvals([])):-'pathfinder::horizontal'(A,B,C,D).
'pathfinder::vertical'(A,B,C,D):-'pathfinder::$impl_vertical'(A,B,C,D).
'pathfinder::$value_vertical'(A,B,C,D,upvals([])):-'pathfinder::vertical'(A,B,C,D).
'pathfinder::find'(A,B,C,D,E,F):-'pathfinder::$impl_find'(A,B,C,D,E,F).
'pathfinder::$value_find'(A,B,C,D,E,F,upvals([])):-'pathfinder::find'(A,B,C,D,E,F).
'pathfinder::point_at'(A,B,C):-'pathfinder::$impl_point_at'(A,B,C).
'pathfinder::$value_point_at'(A,B,C,upvals([])):-'pathfinder::point_at'(A,B,C).
