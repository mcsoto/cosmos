:- style_check(-singleton).
cosmos_prototype__new(_o, _prop, __o) :- default_lib("table", _table), getnil(_table, "update", T1), call_cl(T1, [_o, _prop, _o2]).
cosmos_prototype__get(_t, _o, _o2) :- (get_(_t, _o, _o2) -> true ; (getnil(_t, "_prototype", T2), cosmos_prototype__get(T2, _o, _o2) -> true ; add_("cannot access field ", _o, T3), add_(T3, " of object", T4), call_cl(_throw, [T4]))).
cosmos_prototype__set(_t, _o, _o2, _t2) :- set_(_t, _o, _o2, _t2).
cosmos_prototype__value_new(V1, V2, V3, _upvals) :- cosmos_prototype__new(V1, V2, V3).
cosmos_prototype__value_get(V1, V2, V3, _upvals) :- cosmos_prototype__get(V1, V2, V3).
cosmos_prototype__value_set(V1, V2, V3, V4, _upvals) :- cosmos_prototype__set(V1, V2, V3, V4).
prototype(_t) :- crequire("table", _table, _), new(T5), _nil = T5, default_lib("table", _table), getnil(_table, "toList", T6), _list = T6, default_lib("table", _table), getnil(_table, "update", T7), _update = T7, new(T8), set_(T8, "new", clos(upvals, cosmos_prototype__value_new), T9), set_(T9, "get", clos(upvals, cosmos_prototype__value_get), T10), set_(T10, "set", clos(upvals, cosmos_prototype__value_set), T11), set_(T11, "create", clos(upvals, cosmos_prototype__closure_1), T12), set_(T12, "createFrom", clos(upvals, cosmos_prototype__closure_2), T13), set_(T13, "toString", clos(upvals, cosmos_prototype__closure_3), T16), set_(T16, "_write", clos(upvals, cosmos_prototype__closure_4), T17), set_(T17, "map", clos(upvals, cosmos_prototype__closure_5), T19), set_(T19, "imap", clos(upvals, cosmos_prototype__closure_6), T21), _t = T21, new(T22), set_(T22, "x", 1, T23), set_(T23, "p", clos(upvals, cosmos_prototype__closure_7), T24), getnil(_t, "create", T25), call_cl(T25, [T24, _o]), getnil(_o, "p", T26), call_cl(T26, [_x]).
cosmos_prototype__closure_1(_o, _o2, _upvals) :- _upvals = upvals, cosmos_prototype__set(_o, "_prototype", _nil, _o1), makeobj(_o1, _o2).
cosmos_prototype__closure_2(_o, __o, _o2, _upvals) :- _upvals = upvals, cosmos_prototype__set(_o, "_prototype", __o, _o2).
cosmos_prototype__closure_3(_o, _s, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "remove", T14), call_cl(T14, [_o, "_prototype", _o2]), default_lib("table", _table), getnil(_table, "toString", T15), call_cl(T15, [_o, _o2]).
cosmos_prototype__closure_4(_o, _s, _upvals) :- _upvals = upvals, true.
cosmos_prototype__closure_5(_t, _l, _t2, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "map", T18), call_cl(T18, [_t, _l, _t2]).
cosmos_prototype__closure_6(_t, _l, _t2, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "imap", T20), call_cl(T20, [_t, _l, _t2]).
cosmos_prototype__closure_7(_x, _upvals) :- _upvals = upvals, true.
