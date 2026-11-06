:- style_check(-singleton).
'game::$impl_size'(A,B):-A=[],B=0.0;dif(A,[]),A=[C|D],true,(add_(E,1.0,F),B=F),'game::size'(D,E).
'game::$impl_array'(A,B,C,D):-B=fc_Pair(A,E),new(F),set_(F,"next",clos(upvals([A,D]),'game::$closure_0.0'),G),set_(G,"iter",clos(upvals([H,C,A]),'game::$closure_1.0'),I),E=I.
'game::$impl_main':-true.
game([]):-cosmos_require("io",A),cosmos_require("table",B),cosmos_require("list",C),cosmos_require("math",D),(cosmos_receiver("io",A),cosmos_get(A,"pause",E),F=E),(cosmos_receiver("math",D),cosmos_get(D,"range",G),H=G),I=clos(upvals([]),'game::$closure_2.0'),(new(J),set_(J,"piece","X",K),set_(K,"ai",L,M),N=M),(new(O),set_(O,"piece","O",P),set_(P,"ai",L,Q),R=Q),(new(S),set_(S,0.0,T,U),set_(U,1.0,V,W),set_(W,2.0,X,Y),Z=Y),('game::array'(Z,A1,C,B),cosmos_for(A1,clos(upvals([Z]),'game::$closure_3.0'),[],[])),print(Z).
'game::size'(A,B):-'game::$impl_size'(A,B).
'game::$value_size'(A,B,upvals([])):-'game::size'(A,B).
'game::$closure_0.0'(A,B,C,D,E,upvals([F,G])):-A=fc_T(F,C,H),(H=C,E=0.0;dif(H,C),(cosmos_receiver("table",G),cosmos_method(G,"get",[F,C,D])),(add_(C,1.0,I),B=fc_T(F,I,H)),E=1.0).
'game::$closure_1.0'(A,B,upvals([C,D,E])):-A=fc_Pair(E,F),assoc_to_list(E,G),(cosmos_receiver("list",D),cosmos_method(D,"size",[G,H])),B=fc_T(E,0.0,H).
'game::array'(A,B,C,D):-'game::$impl_array'(A,B,C,D).
'game::$value_array'(A,B,upvals([C,D])):-'game::array'(A,B,C,D).
'game::main':-cosmos_callable("function","main",'game::$impl_main').
'game::$value_main'(upvals([])):-'game::main'.
'game::$closure_2.0'(A,upvals([])):-true.
'game::$closure_3.0'(A,B,[],C,upvals([D])):-(cosmos_get(D,A,E),E=1.0),C=[].
