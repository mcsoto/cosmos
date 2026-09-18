:- style_check(-singleton).
cosmos_table__new(_t) :- new(_t).
cosmos_table__get(_t, _o, _o2) :- get_(_t, _o, _o2).
cosmos_table__set(_t, _o, _o2, _t2) :- set_(_t, _o, _o2, _t2).
cosmos_table__remove(_t, _k, _v, _t2) :- del_(_t, _k, _v, _t2).
cosmos_table__next_(_t, _t2, _k, _v) :- next_pair(_t, _t2, _k, _v), true.
cosmos_table__concat2(_t, _t2, _t3) :- (cosmos_table__next_(_t2, _t1, _k, _v), true, cosmos_table__set(_t, _k, _v, _t_), cosmos_table__concat2(_t_, _t1, _t3) ; _t3 = _t).
cosmos_table__concat_(_t, _t2, _t3) :- (cosmos_table__next_(_t, _t1, _k, _v), true, cosmos_table__set(_t2, _k, _v, _t_), cosmos_table__concat_(_t1, _t_, _t3) ; _t3 = _t2).
cosmos_table__next(_l, _l2, _k, _v, _i) :- if_(_l = [], (_i = 0.0), (_l = [_a|_l2], _a = fc_Pair(_k,_v), _i = 1.0)).
cosmos_table__toList(_t, _l) :- assoc_to_list2(_t, _l).
cosmos_table__iter(_t, _l) :- cosmos_table__toList(_t, _l).
cosmos_table__join(_l, _sep, _s2, _debug) :- cosmos_table__next(_l, _l1, _k, _s, _i), if_(_i = 1.0, (call_cl(_debug, [_s]), add_(_s, _sep, T1), add_(T1, _s1, T2), _s2 = T2, call_cl(_debug, [_s2]), cosmos_table__join(_l1, _sep, _s1, _debug)), (_s2 = "")).
cosmos_table__sub(_t, _l, _t2) :- cosmos_table__next(_l, _l1, _k, _s, _i), if_(_i = 1.0, (cosmos_table__remove(_t, _k, _, _t1), cosmos_table__sub(_t1, _l1, _t2)), (_t2 = _t)).
cosmos_table__map(_t, _p, _l, _debug) :- cosmos_table__next(_t, _t1, _k, _v, _i), if_(_i = 1.0, (call_cl(_debug, [[_k|[_v|[]]]]), call_cl(_p, [_k, _v, _x]), _l = [_x|_l2], cosmos_table__map(_t1, _p, _l2, _debug)), (call_cl(_debug, [["end"|[_i|[_k|[_v|[]]]]]]), _l = [])).
cosmos_table__fold(_l, _p, _a, _result) :- cosmos_table__next(_l, _l1, _k, _b, _i), if_(_i = 1.0, (call_cl(_p, [_a, _k, _b, _c]), cosmos_table__fold(_l1, _p, _c, _result)), (_a = _result)).
cosmos_table__concat(_t, _t2, _t3) :- assoc_to_list(_t, _l), cosmos_table__concat_(_l, _t2, _t3).
cosmos_table__update(_t, _t2, _t3) :- assoc_to_list(_t2, _l), cosmos_table__concat2(_t, _l, _t3).
cosmos_table__nothas(_t, _o) :- Collection1 = _t, cosmos_iter_start(Collection1, Iterator2), cosmos_table__loop_1(Iterator2, _, _o).
cosmos_table__notget(_t, _o, _o2) :- false.
cosmos_table___get(_t, _o, _o2) :- false.
cosmos_table__map_(_t, _l, _t2) :- true.
cosmos_table__imap_(_t, _l, _t2) :- true.
cosmos_table__value_new(V1, _upvals) :- cosmos_table__new(V1).
cosmos_table__value_get(V1, V2, V3, _upvals) :- cosmos_table__get(V1, V2, V3).
cosmos_table__value_set(V1, V2, V3, V4, _upvals) :- cosmos_table__set(V1, V2, V3, V4).
cosmos_table__value_remove(V1, V2, V3, V4, _upvals) :- cosmos_table__remove(V1, V2, V3, V4).
cosmos_table__value_next_(V1, V2, V3, V4, _upvals) :- cosmos_table__next_(V1, V2, V3, V4).
cosmos_table__value_concat2(V1, V2, V3, _upvals) :- cosmos_table__concat2(V1, V2, V3).
cosmos_table__value_concat_(V1, V2, V3, _upvals) :- cosmos_table__concat_(V1, V2, V3).
cosmos_table__value_next(V1, V2, V3, V4, V5, _upvals) :- cosmos_table__next(V1, V2, V3, V4, V5).
cosmos_table__value_toList(V1, V2, _upvals) :- cosmos_table__toList(V1, V2).
cosmos_table__value_iter(V1, V2, _upvals) :- cosmos_table__iter(V1, V2).
cosmos_table__value_join(V1, V2, V3, _upvals) :- cosmos_table__join(V1, V2, V3, C1).
cosmos_table__value_sub(V1, V2, V3, _upvals) :- cosmos_table__sub(V1, V2, V3).
cosmos_table__value_map(V1, V2, V3, _upvals) :- cosmos_table__map(V1, V2, V3, C1).
cosmos_table__value_fold(V1, V2, V3, V4, _upvals) :- cosmos_table__fold(V1, V2, V3, V4).
cosmos_table__value_concat(V1, V2, V3, _upvals) :- cosmos_table__concat(V1, V2, V3).
cosmos_table__value_update(V1, V2, V3, _upvals) :- cosmos_table__update(V1, V2, V3).
cosmos_table__value_nothas(V1, V2, _upvals) :- cosmos_table__nothas(V1, V2).
cosmos_table__value_notget(V1, V2, V3, _upvals) :- cosmos_table__notget(V1, V2, V3).
cosmos_table__value__get(V1, V2, V3, _upvals) :- cosmos_table___get(V1, V2, V3).
cosmos_table__value_map_(V1, V2, V3, _upvals) :- cosmos_table__map_(V1, V2, V3).
cosmos_table__value_imap_(V1, V2, V3, _upvals) :- cosmos_table__imap_(V1, V2, V3).
table(_t) :- _debug = clos(upvals, cosmos_table__closure_1), new(T3), set_(T3, "new", clos(upvals, cosmos_table__value_new), T4), set_(T4, "get", clos(upvals, cosmos_table__value_get), T5), set_(T5, "set", clos(upvals, cosmos_table__value_set), T6), set_(T6, "iter", clos(upvals, cosmos_table__value_iter), T7), set_(T7, "next", clos(upvals, cosmos_table__value_next_), T8), _has = clos(upvals, cosmos_table__closure_2), set_(T8, "has", _has, T9), _toList = clos(upvals, cosmos_table__closure_3), set_(T9, "toList", _toList, T10), _toKeys = clos(upvals, cosmos_table__closure_4), set_(T10, "toKeys", _toKeys, T11), _toValues = clos(upvals, cosmos_table__closure_5), set_(T11, "toValues", _toValues, T12), _map = clos(upvals, cosmos_table__closure_6), set_(T12, "map", _map, T14), _join = clos(upvals, cosmos_table__closure_7), set_(T14, "join", _join, T16), _fold = clos(upvals, cosmos_table__closure_8), set_(T16, "fold", _fold, T18), _sub = clos(upvals, cosmos_table__closure_9), set_(T18, "sub", _sub, T20), _imap = clos(upvals, cosmos_table__closure_10), set_(T20, "imap", _imap, T21), _empty = clos(upvals, cosmos_table__closure_11), set_(T21, "empty", _empty, T22), _mixin = clos(upvals, cosmos_table__closure_12), set_(T22, "mixin", _mixin, T23), set_(T23, "update", clos(upvals, cosmos_table__value_update), T24), set_(T24, "remove", clos(upvals, cosmos_table__value_remove), T25), set_(T25, "concat", clos(upvals, cosmos_table__value_concat), T26), _t = T26, setmeta("table", _t).
cosmos_table__loop_1(C1, F1, K1) :- cosmos_iter_next(C1, IterNext3, _, IterValue5, IterStatus6), ((IterStatus6 = 1.0), (dif(IterValue5, K1), N1 = IterNext3), cosmos_table__loop_1(N1, F1, K1) ; (dif(IterStatus6, 1.0)), F1 = C1).
cosmos_table__closure_1(_x, _upvals) :- _upvals = upvals, true.
cosmos_table__closure_2(_t, _o, _upvals) :- _upvals = upvals, cosmos_table__get(_t, _o, _).
cosmos_table__closure_3(_t, _l, _upvals) :- _upvals = upvals, assoc_to_list(_t, _l).
cosmos_table__closure_4(_t, _l, _upvals) :- _upvals = upvals, assoc_to_keys(_t, _l).
cosmos_table__closure_5(_t, _l, _upvals) :- _upvals = upvals, assoc_to_values(_t, _l).
cosmos_table__closure_6(_t, _l, _t2, _upvals) :- _upvals = upvals, cosmos_table__iter(_t, T13), cosmos_table__map(T13, _l, _t2, _debug).
cosmos_table__closure_7(_t, _l, _t2, _upvals) :- _upvals = upvals, cosmos_table__iter(_t, T15), cosmos_table__join(T15, _l, _t2, _debug).
cosmos_table__closure_8(_t, _l, _c, _t2, _upvals) :- _upvals = upvals, cosmos_table__iter(_t, T17), cosmos_table__fold(T17, _l, _c, _t2).
cosmos_table__closure_9(_t, _l, _t2, _upvals) :- _upvals = upvals, cosmos_table__iter(_l, T19), cosmos_table__sub(_t, T19, _t2).
cosmos_table__closure_10(_t, _l, _t2, _upvals) :- _upvals = upvals, true.
cosmos_table__closure_11(_t, _upvals) :- _upvals = upvals, empty_assoc(_t).
cosmos_table__closure_12(_t, _Properties, _t2, _upvals) :- _upvals = upvals, cosmos_table__concat(_Properties, _t, _t2).
