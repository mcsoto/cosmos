:- style_check(-singleton).
'time1::$impl_fact'(A,B):-C=A,cosmos_trace_call("pl::cosmos_while",[clos(upvals([]),'time1::$closure_0.0'),clos(upvals([]),'time1::$closure_1.0'),[C],[D]],cosmos_while(clos(upvals([]),'time1::$closure_0.0'),clos(upvals([]),'time1::$closure_1.0'),[C],[D])),true.
time1([]):-cosmos_trace_call("::main",[],(cosmos_trace_call("fact",[2.0,A],'time1::fact'(2.0,A)),cosmos_trace_call("print",[A],print(A)))).
'time1::$closure_0.0'([A],upvals([])):-fail.
'time1::$closure_1.0'([A],B,upvals([])):-(A=0.0,(C=1.0,D=C),E=C;dif(A,0.0),((r_sub(A,1.0,F),cosmos_trace_call("fact",[F,G],'time1::fact'(F,G)),r_mul(A,G,H),I=H),D=I),E=I),B=[E],D=E.
'time1::fact'(A,B):-'time1::$impl_fact'(A,B).
'time1::$value_fact'(A,B,upvals([])):-'time1::fact'(A,B).
