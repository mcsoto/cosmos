:- style_check(-singleton).
test16(_) :- new(T1), _next = clos(upvals, cosmos_test16__closure_1), set_(T1, "next", _next, T2), _iter = clos(upvals, cosmos_test16__closure_2), set_(T2, "iter", _iter, T3), _list2 = T3.
cosmos_test16__closure_1(_l, _l2, _k, _v, _i, _upvals) :- _upvals = upvals, if_(_l = [], (_i = 0.0), (_l = [_v|_l2], _i = 1.0)).
cosmos_test16__closure_2(_l, _l, _upvals) :- _upvals = upvals, true.
