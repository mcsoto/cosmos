:- style_check(-singleton).
'board::$impl_win'(A,B,C,D):-(call_cl(D,[0.0,2.0,E]),cosmos_each(E,F,G),(add_("col",G,H),call_cl(C,[H])),cosmos_method(A,"get",[0.0,G,B]),cosmos_method(A,"get",[1.0,G,B]),cosmos_method(A,"get",[2.0,G,B]),add_("piece",B,I),call_cl(C,[I]);call_cl(D,[0.0,2.0,J]),cosmos_each(J,K,L),(add_("line",L,M),call_cl(C,[M])),cosmos_method(A,"get",[L,0.0,B]),cosmos_method(A,"get",[L,1.0,B]),cosmos_method(A,"get",[L,2.0,B]),call_cl(C,[B]);call_cl(D,[0.0,2.0,N]),cosmos_for(N,clos(upvals([A,C,L,B]),'board::$closure_0.0'),[],[]);cosmos_method(A,"get",[2.0,0.0,B]),cosmos_method(A,"get",[1.0,1.0,B]),cosmos_method(A,"get",[0.0,2.0,B])),dif(B," ").
board([]):-(cosmos_receiver("math",A),cosmos_get(A,"range",B),C=B),(cosmos_receiver("table",D),cosmos_get(D,"set",E),F=E),G=clos(upvals([]),'board::$closure_1.0'),new(H),set_(H,0.0," ",I),set_(I,1.0," ",J),set_(J,2.0," ",K),set_(K,3.0," ",L),set_(L,4.0," ",M),set_(M,5.0," ",N),set_(N,6.0," ",O),set_(O,7.0," ",P),set_(P,8.0," ",Q),R=Q.
'board::$closure_0.0'(A,B,[],C,upvals([D,E,F,G])):-((add_("line",F,H),call_cl(E,[H])),cosmos_method(D,"get",[B,B,G]),call_cl(E,[G])),C=[].
'board::win'(A,B,C,D):-'board::$impl_win'(A,B,C,D).
'board::$value_win'(A,B,upvals([C,D])):-'board::win'(A,B,C,D).
'board::$closure_1.0'(A,upvals([])):-true.
