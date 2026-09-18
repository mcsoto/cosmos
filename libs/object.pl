:- style_check(-singleton).
cosmos_object__new(_o, _prop, __o) :- default_lib("table", _table), getnil(_table, "update", T1), call_cl(T1, [_o, _prop, _o2]).
cosmos_object__get(_t, _o, _o2) :- (get_(_t, _o, _o2) -> true ; (getnil(_t, "_prototype", T2), cosmos_object__get(T2, _o, _o2) -> true ; add_("cannot access field ", _o, T3), add_(T3, " of object", T4), throw(T4))).
cosmos_object__set(_t, _o, _o2, _t2) :- obj_set(_t, _o, _o2, _t2).
cosmos_object__value_new(V1, V2, V3, _upvals) :- cosmos_object__new(V1, V2, V3).
cosmos_object__value_get(V1, V2, V3, _upvals) :- cosmos_object__get(V1, V2, V3).
cosmos_object__value_set(V1, V2, V3, V4, _upvals) :- cosmos_object__set(V1, V2, V3, V4).
object(_t) :- crequire("table", _table, _), new(T5), _nil = T5, default_lib("table", _table), getnil(_table, "toList", T6), _list = T6, default_lib("table", _table), getnil(_table, "update", T7), _update_ = T7, default_lib("table", _table), getnil(_table, "set", T8), _set_ = T8, new(T9), set_(T9, "new", clos(upvals, cosmos_object__value_new), T10), set_(T10, "get", clos(upvals, cosmos_object__value_get), T11), set_(T11, "set", clos(upvals, cosmos_object__value_set), T12), _create = clos(upvals(_nil, _set_), cosmos_object__closure_1), set_(T12, "create", _create, T13), _createFrom = clos(upvals(_set_), cosmos_object__closure_2), set_(T13, "createFrom", _createFrom, T14), _update = clos(upvals(_update_), cosmos_object__closure_3), set_(T14, "update", _update, T15), _toString = clos(upvals, cosmos_object__closure_4), set_(T15, "toString", _toString, T18), __write = clos(upvals, cosmos_object__closure_5), set_(T18, "_write", __write, T19), _getTable = clos(upvals, cosmos_object__closure_6), set_(T19, "getTable", _getTable, T20), _map = clos(upvals, cosmos_object__closure_7), set_(T20, "map", _map, T22), _imap = clos(upvals, cosmos_object__closure_8), set_(T22, "imap", _imap, T24), _t = T24.
cosmos_object__closure_1(_t, _obj, _upvals) :- _upvals = upvals(_nil, _set_), call_cl(_set_, [_t, "_prototype", _nil, _t2]), makeobj(_t2, _obj).
cosmos_object__closure_2(_t, __o, _o2, _upvals) :- _upvals = upvals(_set_), call_cl(_set_, [_t, "_prototype", __o, _t2]), makeobj(_t2, _o2).
cosmos_object__closure_3(_o1, _t2, _o3, _upvals) :- _upvals = upvals(_update_), makeobj(_t1, _o1), call_cl(_update_, [_t1, _t2, _t3]), makeobj(_t3, _o3).
cosmos_object__closure_4(_o, _s, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "remove", T16), call_cl(T16, [_o, "_prototype", _o2]), default_lib("table", _table), getnil(_table, "toString", T17), call_cl(T17, [_o, _o2]).
cosmos_object__closure_5(_o, _s, _upvals) :- _upvals = upvals, true.
cosmos_object__closure_6(_o, _t, _upvals) :- _upvals = upvals, makeobj(_o, _t).
cosmos_object__closure_7(_t, _l, _t2, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "map", T21), call_cl(T21, [_t, _l, _t2]).
cosmos_object__closure_8(_t, _l, _t2, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "imap", T23), call_cl(T23, [_t, _l, _t2]).
