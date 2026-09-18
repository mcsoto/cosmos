:- style_check(-singleton).
cosmos_game__size(_l, _n) :- if_(_l = [], (_n = 0.0), (_l = [_|_tail], add_(_j, 1.0, T1), _n = T1, cosmos_game__size(_tail, _j))).
cosmos_game__array(_t, _z, _i) :- _z = fc_Pair(_t,_it), new(T2), _next = clos(upvals(_t), cosmos_game__closure_1), set_(T2, "next", _next, T5), _iter = clos(upvals(_t), cosmos_game__closure_2), set_(T5, "iter", _iter, T7), _it = T7.
cosmos_game__main() :- true.
cosmos_game__value_size(V1, V2, _upvals) :- cosmos_game__size(V1, V2).
cosmos_game__value_array(V1, V2, _upvals) :- cosmos_game__array(V1, V2, C1).
cosmos_game__value_main(_upvals) :- cosmos_game__main().
game(_) :- crequire("io", _io, _), crequire("table", _table, _), crequire("list", _list, _), crequire("math", _math, _), default_lib("io", _io), getnil(_io, "pause", T8), _pause = T8, default_lib("math", _math), getnil(_math, "range", T9), _range = T9, _debug = clos(upvals, cosmos_game__closure_3), new(T10), set_(T10, "piece", "X", T11), set_(T11, "ai", __default, T12), _p1 = T12, new(T13), set_(T13, "piece", "O", T14), set_(T14, "ai", __default, T15), _p2 = T15, new(T16), set_(T16, 0.0, _, T17), set_(T17, 1.0, _, T18), set_(T18, 2.0, _, T19), _t = T19, cosmos_game__array(_t, T20, _i), Collection1 = T20, cosmos_iter_start(Collection1, Iterator2), cosmos_game__loop_1(Iterator2, _, _t), print(_t).
cosmos_game__closure_1(_l, _l2, _k, _v, _i, _upvals) :- _upvals = upvals(_t), _l = fc_T(_t,_k,_n), if_(_n = _k, (_i = 0.0), (default_lib("table", _table), getnil(_table, "get", T3), call_cl(T3, [_t, _k, _v]), add_(_k, 1.0, T4), _l2 = fc_T(_t,T4,_n), _i = 1.0)).
cosmos_game__closure_2(_fc, _fc2, _upvals) :- _upvals = upvals(_t), _fc = fc_Pair(_t,_), assoc_to_list(_t, _l), default_lib("list", _list), getnil(_list, "size", T6), call_cl(T6, [_l, _n]), _fc2 = fc_T(_t,0.0,_n).
cosmos_game__closure_3(_x, _upvals) :- _upvals = upvals, true.
cosmos_game__loop_1(C1, F1, K1) :- cosmos_iter_next(C1, IterNext3, IterKey4, _, IterStatus6), ((IterStatus6 = 1.0), (getnil(K1, IterKey4, T21), T21 = 1.0, N1 = IterNext3), cosmos_game__loop_1(N1, F1, K1) ; (dif(IterStatus6, 1.0)), F1 = C1).
