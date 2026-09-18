:- style_check(-singleton).
'test7::$impl_p'(A,B):-A=2.0,C=clos(upvals([B]),'test7::$closure_0.0'),call_cl(C,[A]).
test7([]):-A=1.0,'test7::p'(B,A).
'test7::$closure_0.0'(A,upvals([B])):-print(B).
'test7::p'(A,B):-'test7::$impl_p'(A,B).
'test7::$value_p'(A,upvals([B])):-'test7::p'(A,B).
