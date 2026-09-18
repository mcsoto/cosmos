:- style_check(-singleton).
'mutable::$impl_createCell'(A):-table_new(A).
'mutable::$impl_readCell'(A,B,C):-table_get(A,B,C).
'mutable::$impl_writeCell'(A,B,C):-table_set(A,B,C,D).
mutable(A):-new(B),set_(B,"new",clos(upvals([]),'mutable::$value_createCell'),C),set_(C,"get",clos(upvals([]),'mutable::$value_readCell'),D),set_(D,"set",clos(upvals([]),'mutable::$value_writeCell'),E),A=E.
'mutable::createCell'(A):-'mutable::$impl_createCell'(A).
'mutable::$value_createCell'(A,upvals([])):-'mutable::createCell'(A).
'mutable::readCell'(A,B,C):-'mutable::$impl_readCell'(A,B,C).
'mutable::$value_readCell'(A,B,C,upvals([])):-'mutable::readCell'(A,B,C).
'mutable::writeCell'(A,B,C):-'mutable::$impl_writeCell'(A,B,C).
'mutable::$value_writeCell'(A,B,C,upvals([])):-'mutable::writeCell'(A,B,C).
