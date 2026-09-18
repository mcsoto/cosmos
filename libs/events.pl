:- style_check(-singleton).
'events::$impl_insertListener'(A,B,C):-B=[],C=[A];dif(B,[]),B=[D|E],((cosmos_get(A,"priority",F),cosmos_get(D,"priority",G),r_gt(F,G)),C=[A|B];(cosmos_get(A,"priority",H),cosmos_get(D,"priority",I),r_le(H,I)),C=[D|J],'events::insertListener'(A,E,J)).
'events::$impl_removeListener'(A,B,C):-B=[],C=[];dif(B,[]),B=[D|E],(cosmos_set_or_unify(D,"id",A),C=E;(cosmos_get(D,"id",F),dif(F,A)),C=[D|G],'events::removeListener'(A,E,G)).
'events::$impl_clearEvent'(A,B,C,D,E):-B=[],C=[],D=0.0;dif(B,[]),B=[F|G],(cosmos_set_or_unify(F,"event",A),(cosmos_get(F,"active",H),cosmos_receiver("mutable",E),cosmos_method(E,"set",[H,"value",0.0])),'events::clearEvent'(A,G,C,I,E),add_(I,1.0,J),D=J;(cosmos_get(F,"event",K),dif(K,A)),C=[F|L],'events::clearEvent'(A,G,L,D,E)).
'events::$impl_deactivateAll'(A,B,C):-A=[],B=0.0;dif(A,[]),A=[D|E],(cosmos_get(D,"active",F),cosmos_receiver("mutable",C),cosmos_method(C,"get",[F,"value",G])),'events::deactivateAll'(E,H,C),(G=1.0,(cosmos_get(D,"active",I),cosmos_receiver("mutable",C),cosmos_method(C,"set",[I,"value",0.0])),add_(H,1.0,J),B=J;dif(G,1.0),B=H).
'events::$impl_countEvent'(A,B,C,D):-B=[],C=0.0;dif(B,[]),B=[E|F],'events::countEvent'(A,F,G,D),(cosmos_get(E,"active",H),cosmos_receiver("mutable",D),cosmos_method(D,"get",[H,"value",I])),((cosmos_set_or_unify(E,"event",A),I=1.0),add_(G,1.0,J),C=J;\+ (cosmos_set_or_unify(E,"event",A),I=1.0),C=G).
'events::$impl_dispatch'(A,B,C,D,E,F):-B=[],E=0.0;dif(B,[]),B=[G|H],(cosmos_get(G,"active",I),cosmos_receiver("mutable",F),cosmos_method(F,"get",[I,"value",J])),((cosmos_set_or_unify(G,"event",C),J=1.0),(cosmos_set_or_unify(G,"once",1.0),(cosmos_get(G,"active",K),cosmos_receiver("mutable",F),cosmos_method(F,"set",[K,"value",0.0])),(cosmos_receiver("mutable",F),cosmos_method(F,"get",[A,"listeners",L])),(cosmos_get(G,"id",M),'events::removeListener'(M,L,N)),cosmos_receiver("mutable",F),cosmos_method(F,"set",[A,"listeners",N]);(cosmos_get(G,"once",O),dif(O,1.0)),true),cosmos_method(G,"callback",[D]),'events::dispatch'(A,H,C,D,P,F),add_(P,1.0,Q),E=Q;\+ (cosmos_set_or_unify(G,"event",C),J=1.0),'events::dispatch'(A,H,C,D,E,F)).
'events::$impl_subscribe'(A,B,C,D,E,F,G):-(cosmos_receiver("mutable",G),cosmos_method(G,"get",[A,"nextId",H])),(add_(H,1.0,I),cosmos_receiver("mutable",G),cosmos_method(G,"set",[A,"nextId",I])),((cosmos_receiver("mutable",G),cosmos_method_value(G,"new",[],J)),K=J),(cosmos_receiver("mutable",G),cosmos_method(G,"set",[K,"value",1.0])),(new(L),set_(L,"id",H,M),set_(M,"event",B,N),set_(N,"callback",C,O),set_(O,"priority",D,P),set_(P,"once",E,Q),set_(Q,"active",K,R),F=R),(cosmos_receiver("mutable",G),cosmos_method(G,"get",[A,"listeners",S])),'events::insertListener'(F,S,T),cosmos_receiver("mutable",G),cosmos_method(G,"set",[A,"listeners",T]).
'events::$impl_createEmitter'(A,B):-((cosmos_receiver("mutable",B),cosmos_method_value(B,"new",[],C)),D=C),(cosmos_receiver("mutable",B),cosmos_method(B,"set",[D,"listeners",[]])),(cosmos_receiver("mutable",B),cosmos_method(B,"set",[D,"nextId",1.0])),new(E),set_(E,"on",clos(upvals([B,D]),'events::$closure_0.0'),F),set_(F,"onPriority",clos(upvals([B,D]),'events::$closure_1.0'),G),set_(G,"once",clos(upvals([B,D]),'events::$closure_2.0'),H),set_(H,"oncePriority",clos(upvals([B,D]),'events::$closure_3.0'),I),set_(I,"off",clos(upvals([B,D]),'events::$closure_4.0'),J),set_(J,"emit",clos(upvals([B,D]),'events::$closure_5.0'),K),set_(K,"clear",clos(upvals([B,D]),'events::$closure_6.0'),L),set_(L,"clearAll",clos(upvals([B,D]),'events::$closure_7.0'),M),set_(M,"listenerCount",clos(upvals([B,D]),'events::$closure_8.0'),N),A=N.
events(A):-cosmos_require("mutable",B),new(C),set_(C,"new",clos(upvals([B]),'events::$value_createEmitter'),D),A=D.
'events::insertListener'(A,B,C):-'events::$impl_insertListener'(A,B,C).
'events::$value_insertListener'(A,B,C,upvals([])):-'events::insertListener'(A,B,C).
'events::removeListener'(A,B,C):-'events::$impl_removeListener'(A,B,C).
'events::$value_removeListener'(A,B,C,upvals([])):-'events::removeListener'(A,B,C).
'events::clearEvent'(A,B,C,D,E):-'events::$impl_clearEvent'(A,B,C,D,E).
'events::$value_clearEvent'(A,B,C,D,upvals([E])):-'events::clearEvent'(A,B,C,D,E).
'events::deactivateAll'(A,B,C):-'events::$impl_deactivateAll'(A,B,C).
'events::$value_deactivateAll'(A,B,upvals([C])):-'events::deactivateAll'(A,B,C).
'events::countEvent'(A,B,C,D):-'events::$impl_countEvent'(A,B,C,D).
'events::$value_countEvent'(A,B,C,upvals([D])):-'events::countEvent'(A,B,C,D).
'events::dispatch'(A,B,C,D,E,F):-'events::$impl_dispatch'(A,B,C,D,E,F).
'events::$value_dispatch'(A,B,C,D,E,upvals([F])):-'events::dispatch'(A,B,C,D,E,F).
'events::subscribe'(A,B,C,D,E,F,G):-'events::$impl_subscribe'(A,B,C,D,E,F,G).
'events::$value_subscribe'(A,B,C,D,E,F,upvals([G])):-'events::subscribe'(A,B,C,D,E,F,G).
'events::$closure_0.0'(A,B,C,upvals([D,E])):-'events::subscribe'(E,A,B,0.0,0.0,C,D).
'events::$closure_1.0'(A,B,C,D,upvals([E,F])):-'events::subscribe'(F,A,B,C,0.0,D,E).
'events::$closure_2.0'(A,B,C,upvals([D,E])):-'events::subscribe'(E,A,B,0.0,1.0,C,D).
'events::$closure_3.0'(A,B,C,D,upvals([E,F])):-'events::subscribe'(F,A,B,C,1.0,D,E).
'events::$closure_4.0'(A,B,upvals([C,D])):-(cosmos_get(A,"active",E),cosmos_receiver("mutable",C),cosmos_method(C,"get",[E,"value",F])),(F=1.0,(cosmos_get(A,"active",G),cosmos_receiver("mutable",C),cosmos_method(C,"set",[G,"value",0.0])),(cosmos_receiver("mutable",C),cosmos_method(C,"get",[D,"listeners",H])),(cosmos_get(A,"id",I),'events::removeListener'(I,H,J)),(cosmos_receiver("mutable",C),cosmos_method(C,"set",[D,"listeners",J])),B=1.0;dif(F,1.0),B=0.0).
'events::$closure_5.0'(A,B,C,upvals([D,E])):-(cosmos_receiver("mutable",D),cosmos_method(D,"get",[E,"listeners",F])),'events::dispatch'(E,F,A,B,C,D).
'events::$closure_6.0'(A,B,upvals([C,D])):-(cosmos_receiver("mutable",C),cosmos_method(C,"get",[D,"listeners",E])),'events::clearEvent'(A,E,F,B,C),cosmos_receiver("mutable",C),cosmos_method(C,"set",[D,"listeners",F]).
'events::$closure_7.0'(A,upvals([B,C])):-(cosmos_receiver("mutable",B),cosmos_method(B,"get",[C,"listeners",D])),'events::deactivateAll'(D,A,B),cosmos_receiver("mutable",B),cosmos_method(B,"set",[C,"listeners",[]]).
'events::$closure_8.0'(A,B,upvals([C,D])):-(cosmos_receiver("mutable",C),cosmos_method(C,"get",[D,"listeners",E])),'events::countEvent'(A,E,B,C).
'events::createEmitter'(A,B):-'events::$impl_createEmitter'(A,B).
'events::$value_createEmitter'(A,upvals([B])):-'events::createEmitter'(A,B).
