:- style_check(-singleton).
test9(_) :- _write = clos(upvals, cosmos_test9__closure_1), new(T1), _p = clos(upvals, cosmos_test9__closure_2), set_(T1, "p", _p, T2), set_(T2, "length", 2.0, T3), _t = T3.
cosmos_test9__closure_1(_upvals) :- _upvals = upvals, true.
cosmos_test9__closure_2(_f, _upvals) :- _upvals = upvals, true, write(_f).
