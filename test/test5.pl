:- style_check(-singleton).
test5(_) :- _p = clos(upvals, cosmos_test5__closure_1), call_cl(_p, []), new(T1), set_(T1, 1.0, 2.0, T2), set_(T2, "x", 1.0, T3), set_(T3, "y", _i, T4), _t = T4, print(_t), getnil(_t, "y", T5), print(T5), getnil(_t, 1.0, T6), _b = T6, getnil(_t, 1.0, T7), print(T7), getnil(_t, "y", T8), print(T8).
cosmos_test5__closure_1(_upvals) :- _upvals = upvals, true, print(2.0).
