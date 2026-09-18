:- style_check(-singleton).
'compiler::$impl_compile'(A,B,C):-new(D),'compiler::compile_unit'(A,B,D,E),cosmos_get(E,"prolog",F),C=F.
'compiler::$impl_compile_unit'(A,B,C,D):-cosmos_require("parser",E),cosmos_require("resolve",F),cosmos_require("emit_prolog",G),cosmos_require("check",H),cosmos_require("normalize",I),cosmos_method(E,"parse",[A,fc_Program(J)]),cosmos_method(I,"normalize",[J,K]),cosmos_method(H,"imported_functors",[C,L]),append(L,K,M),cosmos_method(H,"analyze",[M,C,N,O]),cosmos_method(F,"analyze",[M,P]),set_(P,"schemas",N,Q),cosmos_method(G,"generate",[Q,B,F,R]),cosmos_method(H,"interface",[M,B,N,O,S]),new(T),set_(T,"prolog",R,U),set_(U,"interface",S,V),D=V.
'compiler::$impl_imports'(A,B):-cosmos_require("parser",C),cosmos_require("check",D),cosmos_method(C,"parse",[A,fc_Program(E)]),cosmos_method(D,"imports",[E,B]).
'compiler::$impl_compile_query'(A,B,C,D):-cc_compile_query(A,B,C,E),new(F),set_(F,"module",C,G),set_(G,"entry",C,H),set_(H,"variables",B,I),set_(I,"source",A,J),set_(J,"prolog",E,K),D=K.
compiler(A):-new(B),set_(B,"compile",clos(upvals([]),'compiler::$value_compile'),C),set_(C,"compile_query",clos(upvals([]),'compiler::$value_compile_query'),D),set_(D,"compile_unit",clos(upvals([]),'compiler::$value_compile_unit'),E),set_(E,"imports",clos(upvals([]),'compiler::$value_imports'),A).
'compiler::compile'(A,B,C):-'compiler::$impl_compile'(A,B,C).
'compiler::$value_compile'(A,B,C,upvals([])):-'compiler::compile'(A,B,C).
'compiler::compile_unit'(A,B,C,D):-'compiler::$impl_compile_unit'(A,B,C,D).
'compiler::$value_compile_unit'(A,B,C,D,upvals([])):-'compiler::compile_unit'(A,B,C,D).
'compiler::imports'(A,B):-'compiler::$impl_imports'(A,B).
'compiler::$value_imports'(A,B,upvals([])):-'compiler::imports'(A,B).
'compiler::compile_query'(A,B,C,D):-'compiler::$impl_compile_query'(A,B,C,D).
'compiler::$value_compile_query'(A,B,C,D,upvals([])):-'compiler::compile_query'(A,B,C,D).
