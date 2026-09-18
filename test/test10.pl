:- style_check(-singleton).
test10(_) :- crequire("table", _table, _), new(T1), set_(T1, "next", clos(upvals, cosmos_test10__closure_1), T2), _iter = clos(upvals, cosmos_test10__closure_2), set_(T2, "iter", _iter, T3), _list = T3, setmeta("list", _list), setmeta("table", _table).
cosmos_test10__closure_1(_l, _l2, _k, _v, _i, _upvals) :- _upvals = upvals, if_(_l = [], (_i = 0.0), (_l = [_v|_l2], _i = 1.0)).
cosmos_test10__closure_2(_l, _l, _upvals) :- _upvals = upvals, true.
