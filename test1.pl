:- style_check(-singleton).
'test1::$impl_p'(A,B):-((add_(A,1.0,C),D=C),E=22.0),B=E.
'test1::$impl_said'(A,B,C):-call_cl(C,[A,B,D]).
'test1::$impl_saidAt'(A,B,C,D):-call_cl(D,[A,B,C]).
'test1::$impl_say'(A,B,C,D,E,F,G):-B=[H,G],call_cl(C,[A,H,D]),(add_(D,1.0,I),size_(A,J),cosmos_receiver("string",F),cosmos_method(F,"slice",[A,I,J,G])),print(G);B=[H],call_cl(C,[A,H,K]).
test1([]):-('test1::p'(1.0,A),print(A)),cosmos_for([1.0,2.0,3.0],clos(upvals([B]),'test1::$closure_0.0'),[],[]),cosmos_for("[1,2,3]",clos(upvals([B]),'test1::$closure_1.0'),[],[]),(cosmos_receiver("string",C),cosmos_get(C,"find",D),E=D),F=1.0,cosmos_while(clos(upvals([]),'test1::$closure_2.0'),clos(upvals([E,G,H,B,I,C,J]),'test1::$closure_3.0'),[F],[K]),(true,(cosmos_receiver("string",C),cosmos_method(C,"find",["a-",I,G])),(add_(">",G,L),print(L)),I="-",(add_(">",G,M),print(M)),(size_(N,O),add_("",O,P),print(P)),cosmos_receiver("list",H),cosmos_method(H,"choice",[[1.0,2.0,3.0],J]);\+true,true).
'test1::p'(A,B):-'test1::$impl_p'(A,B).
'test1::$value_p'(A,B,upvals([])):-'test1::p'(A,B).
'test1::said'(A,B,C):-'test1::$impl_said'(A,B,C).
'test1::$value_said'(A,B,upvals([C])):-'test1::said'(A,B,C).
'test1::saidAt'(A,B,C,D):-'test1::$impl_saidAt'(A,B,C,D).
'test1::$value_saidAt'(A,B,C,upvals([D])):-'test1::saidAt'(A,B,C,D).
'test1::say'(A,B,C,D,E,F,G):-'test1::$impl_say'(A,B,C,D,E,F,G).
'test1::$value_say'(A,B,upvals([C,D,E,F,G])):-'test1::say'(A,B,C,D,E,F,G).
'test1::$closure_0.0'(A,B,[],C,upvals([D])):-print(B),C=[].
'test1::$closure_1.0'(A,B,[],C,upvals([D])):-print(B),C=[].
'test1::$closure_2.0'([A],upvals([])):-A=1.0.
'test1::$closure_4.0'(A,B,[],C,upvals([D,E])):-(add_(B,"=",F),(cosmos_receiver("math",D),cosmos_method_value(D,"random",[1.0,10.0],G)),add_(F,G,H),print(H)),C=[].
'test1::$closure_3.0'([A],B,upvals([C,D,E,F,G,H,I])):-((cosmos_receiver("io",J),cosmos_method(J,"write",["> "])),((cosmos_receiver("io",J),cosmos_method_value(J,"read",[],K)),L=K),(L="random",((cosmos_receiver("math",M),cosmos_method_value(M,"range",[1.0,20.0],N)),cosmos_for(N,clos(upvals([M,F]),'test1::$closure_4.0'),[],[])),O=A;dif(L,"random"),(((cosmos_receiver("string",H),cosmos_method(H,"find",[L,G,D])),has_(["+","-","="],G)),(print("maths"),((cosmos_receiver("string",H),cosmos_method_value(H,"slice",[L,0.0,D],P)),Q=P),(add_(D,1.0,R),size_(L,S),(cosmos_receiver("string",H),cosmos_method_value(H,"slice",[L,R,S],T)),U=T),print(Q),print(U)),V=A;\+ ((cosmos_receiver("string",H),cosmos_method(H,"find",[L,G,D])),has_(["+","-","="],G)),('test1::say'(L,["say ",I],C,D,F,H,I),true,W=A;\+'test1::say'(L,["say ",I],C,D,F,H,I),('test1::said'(L,"random",C),((cosmos_receiver("list",E),cosmos_method(E,"choice",[[1.0,2.0,3.0],I])),print(I)),X=A;\+'test1::said'(L,"random",C),(Y=0.0,Z=Y),X=Y),W=X),V=W),O=V)),B=[O],Z=O.
