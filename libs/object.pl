:- style_check(-singleton).
'object::$impl__new'(A,B,C,D):-cosmos_receiver("table",D),cosmos_method(D,"update",[A,B,E]).
'object::$impl_get'(A,B,C):-get_(A,B,C)->true;cosmos_get(A,"_prototype",D),'object::get'(D,B,C)->true;add_("cannot access field ",B,E),add_(E," of object",F),throw(F).
'object::$impl_set'(A,B,C,D):-obj_set(A,B,C,D).
object(A):-cosmos_require("table",B),(new(C),D=C),(cosmos_receiver("table",B),cosmos_get(B,"toList",E),F=E),(cosmos_receiver("table",B),cosmos_get(B,"update",G),H=G),(cosmos_receiver("table",B),cosmos_get(B,"set",I),J=I),print("-obj"),(new(K),set_(K,"new",clos(upvals([B]),'object::$value__new'),L),set_(L,"get",clos(upvals([]),'object::$value_get'),M),set_(M,"set",clos(upvals([]),'object::$value_set'),N),set_(N,"create",clos(upvals([D,J]),'object::$closure_0.0'),O),set_(O,"createFrom",clos(upvals([J]),'object::$closure_1.0'),P),set_(P,"update",clos(upvals([H]),'object::$closure_2.0'),Q),set_(Q,"toString",clos(upvals([B]),'object::$closure_3.0'),R),set_(R,"_write",clos(upvals([]),'object::$closure_4.0'),S),set_(S,"getTable",clos(upvals([]),'object::$closure_5.0'),T),set_(T,"map",clos(upvals([B]),'object::$closure_6.0'),U),set_(U,"imap",clos(upvals([B]),'object::$closure_7.0'),V),A=V),print("-obj").
'object::_new'(A,B,C,D):-'object::$impl__new'(A,B,C,D).
'object::$value__new'(A,B,C,upvals([D])):-'object::_new'(A,B,C,D).
'object::get'(A,B,C):-'object::$impl_get'(A,B,C).
'object::$value_get'(A,B,C,upvals([])):-'object::get'(A,B,C).
'object::set'(A,B,C,D):-'object::$impl_set'(A,B,C,D).
'object::$value_set'(A,B,C,D,upvals([])):-'object::set'(A,B,C,D).
'object::$closure_0.0'(A,B,upvals([C,D])):-call_cl(D,[A,"_prototype",C,E]),makeobj(E,B).
'object::$closure_1.0'(A,B,C,upvals([D])):-call_cl(D,[A,"_prototype",B,E]),makeobj(E,C).
'object::$closure_2.0'(A,B,C,upvals([D])):-makeobj(E,A),call_cl(D,[E,B,F]),makeobj(F,C).
'object::$closure_3.0'(A,B,upvals([C])):-(cosmos_receiver("table",C),cosmos_method(C,"remove",[A,"_prototype",D])),cosmos_receiver("table",C),cosmos_method(C,"toString",[A,D]).
'object::$closure_4.0'(A,B,upvals([])):-true.
'object::$closure_5.0'(A,B,upvals([])):-makeobj(A,B).
'object::$closure_6.0'(A,B,C,upvals([D])):-cosmos_receiver("table",D),cosmos_method(D,"map",[A,B,C]).
'object::$closure_7.0'(A,B,C,upvals([D])):-cosmos_receiver("table",D),cosmos_method(D,"imap",[A,B,C]).
