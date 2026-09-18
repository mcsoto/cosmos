:- style_check(-singleton).
cosmos_list__get(_L, _N, _Element) :- int(_N, _HostN), nth0(_HostN, _L, _Element).
cosmos_list__size(_l, _n) :- if_(_l = [], (_n = 0.0), (_l = [_|_tail], add_(_j, 1.0, T1), _n = T1, cosmos_list__size(_tail, _j))).
cosmos_list__filter(_l, _p, _l2) :- (_l = [], _l2 = [] ; _l = [_head|_tail], (call_cl(_p, [_head]), _l2 = [_head|_tail2], cosmos_list__filter(_tail, _p, _tail2) ; cosmos_list__filter(_tail, _p, _l2))).
cosmos_list__removeAll(_l, _p, _l2) :- if_(_l = [], (_l2 = []), (_l = [_head|_tail], (call_cl(_p, [_head]), cosmos_list__removeAll(_tail, _p, _l2) ; _l2 = [_head|_tail2], cosmos_list__removeAll(_tail, _p, _tail2)))).
cosmos_list__remove2(_l, _i, _n, _l2) :- (_l = [], _l2 = _l ; _l = [_e1|_tail], if_(_i = _n, (_l2 = _tail), (add_(_i, 1.0, T2), _i2 = T2, _l2 = [_e1|_l3], cosmos_list__remove2(_tail, _i2, _n, _l3)))).
cosmos_list__removeIndex(_l, _i, _l2) :- type(_i, "int"), cosmos_list__remove2(_l, 0.0, _i, _l2).
cosmos_list__remove(_l, _n, _l2) :- (_l = [], _l2 = _l ; _l = [_e|_tail], if_(_e = _n, (_l2 = _tail), (_l2 = [_e|_l3], cosmos_list__remove(_tail, _n, _l3)))).
cosmos_list__has2(_l, _e) :- if_(_l = [_e|_], (true), (_l = [_|_tail], cosmos_list__has2(_tail, _e))).
cosmos_list__has(_l, _e) :- memberd_t(_e, _l, _).
cosmos_list__concat(_l, _l2, _l3) :- append(_l, _l2, _l3).
cosmos_list__push(_l, _x, _l2) :- _l2 = [_x|_l].
cosmos_list__pop(_l, _l2) :- _l = [_x|_l2], _l2 = _tail.
cosmos_list__set(_t, _o, _o2, _t2) :- (_t = fc_T(_e,_v,_tail), if_(_e = _o, (_t2 = fc_T(_o,_o2,_tail)), (cosmos_list__set(_tail, _o, _o2, _t3), _t2 = fc_T(_e,_v,_t3))) ; _t2 = fc_T(_o,_o2,_t)).
cosmos_list__last(_l, _a) :- cosmos_list__size(_l, T3), r_sub(T3, 1.0, T4), cosmos_list__get(_l, T4, _a).
cosmos_list__reverse(_l, _l2) :- if_(_l = [_a|_tail], (cosmos_list__reverse(_tail, _ltemp), cosmos_list__concat(_ltemp, [_a|fc_Cons], _l2)), (_l = fc_Cons, _l2 = fc_Cons)).
cosmos_list__eachIndex(_l, _p, _i, _l2) :- if_(_l = fc_Cons, (_l2 = fc_Cons), (_l = [_head|_tail], _l2 = [_head2|_tail2], call_cl(_p, [_i, _head, _head2]), add_(_i, 1.0, T5), cosmos_list__eachIndex(_tail, _p, T5, _tail2))).
cosmos_list__each(_l, _p, _l2) :- cosmos_list__eachIndex(_l, _p, 0.0, _l2).
cosmos_list__join(_l, _sep, _s) :- if_(_l = [_a|fc_Cons], (_s = _a), (if_(_l = [_s1|_tail], (add_(_s1, _sep, T6), add_(T6, _s2, T7), _s = T7, cosmos_list__join(_tail, _sep, _s2)), (_l = fc_Cons, _s = "")))).
cosmos_list__join5(_l, _sep, _s) :- if_(_l = [_a|fc_Cons], (_s = _a), (if_(_l = [_s1|_tail], (add_(_s1, _sep, T8), add_(T8, _s2, T9), _s = T9, cosmos_list__join(_tail, _sep, _s2)), (_l = fc_Cons, _s = "")))).
cosmos_list__fold(_l, _pred, _s, _result) :- if_(_l = [_b|_tail], (call_cl(_pred, [_s, _b, _c]), cosmos_list__fold(_tail, _pred, _c, _result)), (_l = fc_Cons, _result = _s)).
cosmos_list__join2(_l, _sep, _s, _s2) :- if_(_l = [_b|_tail], (add_(_s, _sep, T10), add_(T10, _b, T11), _s1 = T11, cosmos_list__join2(_tail, _sep, _s1, _s2)), (_l = fc_Cons, _s = _s2)).
cosmos_list__join_string(_l, _sep, _s, _s2) :- if_(_l = [_b|_tail], (default_lib("string", _string), getnil(_string, "concat", T12), call_cl(T12, [_s, _sep, _sa]), default_lib("string", _string), getnil(_string, "concat", T13), call_cl(T13, [_sa, _b, _s1]), cosmos_list__join_string(_tail, _sep, _s1, _s2)), (_l = [], _s = _s2)).
cosmos_list__join3(_l, _sep, _s2) :- if_(_l = [_sa|_tail], (cosmos_list__join_string(_tail, _sep, _sa, _s2)), (_s2 = "", _l = [])).
cosmos_list__unique_(_l, _l2, _dup) :- (_l = [], _l2 = _l ; _l = [_e|_tail], (default_lib("list", _list), getnil(_list, "has", T14), call_cl(T14, [_dup, _e]), _l2 = _tail2, cosmos_list__unique_(_tail, _tail2, _dup) ; _dup1 = [_e|_dup], _l2 = [_e|_tail2], cosmos_list__unique_(_tail, _tail2, _dup1))).
cosmos_list__unique(_l, _l2, _dup) :- cosmos_list__unique_(_l2, _l, []).
cosmos_list__first(_l, _a) :- _l = [_a|_].
cosmos_list__findOnce(_l, _e, _i) :- _l = [_x|_tail], (_e = _x -> _i = 0.0 ; add_(_j, 1.0, T15), _i = T15, cosmos_list__findOnce(_tail, _e, _j)).
cosmos_list__every(_l, _p) :- if_(_l = fc_Cons, (_l2 = fc_Cons), (_l = [_head|_tail], call_cl(_p, [_head]), cosmos_list__every(_tail, _p))).
cosmos_list__map(_l, _p, _l2) :- if_(_l = fc_Cons, (_l2 = fc_Cons), (_l = [_head|_tail], _l2 = [_head2|_tail2], call_cl(_p, [_head, _head2]), cosmos_list__map(_tail, _p, _tail2))).
cosmos_list__iterate(_p, _n, _x, _y) :- if_(_n = 0.0, (_y = _x), (call_cl(_p, [_x, _x2]), r_sub(_n, 1.0, T16), cosmos_list__iterate(_p, T16, _x2, _y))).
cosmos_list__find(_l, _e, _i) :- _l = [_e1|_tail], if_(_e = _e1, (_i = 0.0), (cosmos_list__find(_tail, _e, _j), add_(_j, 1.0, T17), _i = T17)).
cosmos_list__value_get(V1, V2, V3, _upvals) :- cosmos_list__get(V1, V2, V3).
cosmos_list__value_size(V1, V2, _upvals) :- cosmos_list__size(V1, V2).
cosmos_list__value_filter(V1, V2, V3, _upvals) :- cosmos_list__filter(V1, V2, V3).
cosmos_list__value_removeAll(V1, V2, V3, _upvals) :- cosmos_list__removeAll(V1, V2, V3).
cosmos_list__value_remove2(V1, V2, V3, V4, _upvals) :- cosmos_list__remove2(V1, V2, V3, V4).
cosmos_list__value_removeIndex(V1, V2, V3, _upvals) :- cosmos_list__removeIndex(V1, V2, V3).
cosmos_list__value_remove(V1, V2, V3, _upvals) :- cosmos_list__remove(V1, V2, V3).
cosmos_list__value_has2(V1, V2, _upvals) :- cosmos_list__has2(V1, V2).
cosmos_list__value_has(V1, V2, _upvals) :- cosmos_list__has(V1, V2).
cosmos_list__value_concat(V1, V2, V3, _upvals) :- cosmos_list__concat(V1, V2, V3).
cosmos_list__value_push(V1, V2, V3, _upvals) :- cosmos_list__push(V1, V2, V3).
cosmos_list__value_pop(V1, V2, _upvals) :- cosmos_list__pop(V1, V2).
cosmos_list__value_set(V1, V2, V3, V4, _upvals) :- cosmos_list__set(V1, V2, V3, V4).
cosmos_list__value_last(V1, V2, _upvals) :- cosmos_list__last(V1, V2).
cosmos_list__value_reverse(V1, V2, _upvals) :- cosmos_list__reverse(V1, V2).
cosmos_list__value_eachIndex(V1, V2, V3, V4, _upvals) :- cosmos_list__eachIndex(V1, V2, V3, V4).
cosmos_list__value_each(V1, V2, V3, _upvals) :- cosmos_list__each(V1, V2, V3).
cosmos_list__value_join(V1, V2, V3, _upvals) :- cosmos_list__join(V1, V2, V3).
cosmos_list__value_join5(V1, V2, V3, _upvals) :- cosmos_list__join5(V1, V2, V3).
cosmos_list__value_fold(V1, V2, V3, V4, _upvals) :- cosmos_list__fold(V1, V2, V3, V4).
cosmos_list__value_join2(V1, V2, V3, V4, _upvals) :- cosmos_list__join2(V1, V2, V3, V4).
cosmos_list__value_join_string(V1, V2, V3, V4, _upvals) :- cosmos_list__join_string(V1, V2, V3, V4).
cosmos_list__value_join3(V1, V2, V3, _upvals) :- cosmos_list__join3(V1, V2, V3).
cosmos_list__value_unique_(V1, V2, V3, _upvals) :- cosmos_list__unique_(V1, V2, V3).
cosmos_list__value_unique(V1, V2, V3, _upvals) :- cosmos_list__unique(V1, V2, V3).
cosmos_list__value_first(V1, V2, _upvals) :- cosmos_list__first(V1, V2).
cosmos_list__value_findOnce(V1, V2, V3, _upvals) :- cosmos_list__findOnce(V1, V2, V3).
cosmos_list__value_every(V1, V2, _upvals) :- cosmos_list__every(V1, V2).
cosmos_list__value_map(V1, V2, V3, _upvals) :- cosmos_list__map(V1, V2, V3).
cosmos_list__value_iterate(V1, V2, V3, V4, _upvals) :- cosmos_list__iterate(V1, V2, V3, V4).
cosmos_list__value_find(V1, V2, V3, _upvals) :- cosmos_list__find(V1, V2, V3).
list(_t) :- crequire("string", _string, _), new(T18), _new = clos(upvals, cosmos_list__closure_1), set_(T18, "new", _new, T19), _next = clos(upvals, cosmos_list__closure_2), set_(T19, "next", _next, T20), _iter = clos(upvals, cosmos_list__closure_3), set_(T20, "iter", _iter, T21), set_(T21, "size", clos(upvals, cosmos_list__value_size), T22), set_(T22, "length", clos(upvals, cosmos_list__value_size), T23), set_(T23, "filter", clos(upvals, cosmos_list__value_filter), T24), set_(T24, "removeIndex", clos(upvals, cosmos_list__value_removeIndex), T25), set_(T25, "remove", clos(upvals, cosmos_list__value_remove), T26), set_(T26, "push", clos(upvals, cosmos_list__value_push), T27), set_(T27, "pop", clos(upvals, cosmos_list__value_pop), T28), set_(T28, "has", clos(upvals, cosmos_list__value_has2), T29), set_(T29, "has2", clos(upvals, cosmos_list__value_has2), T30), set_(T30, "at", clos(upvals, cosmos_list__value_get), T31), set_(T31, "concat", clos(upvals, cosmos_list__value_concat), T32), set_(T32, "removeAll", clos(upvals, cosmos_list__value_removeAll), T33), set_(T33, "join", clos(upvals, cosmos_list__value_join3), T34), set_(T34, "joinString", clos(upvals, cosmos_list__value_join_string), T35), set_(T35, "fold", clos(upvals, cosmos_list__value_fold), T36), set_(T36, "each", clos(upvals, cosmos_list__value_each), T37), set_(T37, "eachIndex", clos(upvals, cosmos_list__value_eachIndex), T38), set_(T38, "iterate", clos(upvals, cosmos_list__value_iterate), T39), set_(T39, "reverse", clos(upvals, cosmos_list__value_reverse), T40), set_(T40, "first", clos(upvals, cosmos_list__value_first), T41), set_(T41, "last", clos(upvals, cosmos_list__value_last), T42), _slice = clos(upvals, cosmos_list__closure_4), set_(T42, "slice", _slice, T43), _t = T43, setmeta("list", _t).
cosmos_list__closure_1(_x, _upvals) :- _upvals = upvals, _x = [].
cosmos_list__closure_2(_l, _l2, _k, _v, _i, _upvals) :- _upvals = upvals, if_(_l = [], (_i = 0.0), (_l = [_v|_l2], _i = 1.0)).
cosmos_list__closure_3(_l, _l, _upvals) :- _upvals = upvals, true.
cosmos_list__closure_4(_l, _i, _j, _l2, _upvals) :- _upvals = upvals, slice(_l, _i, _j, _l2).
