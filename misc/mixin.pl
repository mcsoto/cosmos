:- style_check(-singleton).
mixin(_t) :- crequire("table", _table, _), new(T1), _nil = T1, default_lib("table", _table), getnil(_table, "concat", T2), _concat = T2, new(T3), set_(T3, "new", _new, T4), set_(T4, "get", _get, T5), set_(T5, "set", _set, T6), set_(T6, "mixin", clos(upvals, cosmos_mixin__closure_1), T7), set_(T7, "createFrom", clos(upvals, cosmos_mixin__closure_2), T8), set_(T8, "toString", clos(upvals, cosmos_mixin__closure_3), T11), set_(T11, "_write", clos(upvals, cosmos_mixin__closure_4), T12), set_(T12, "map", clos(upvals, cosmos_mixin__closure_5), T14), set_(T14, "imap", clos(upvals, cosmos_mixin__closure_6), T16), _t = T16.
cosmos_mixin__closure_1(_o1, _o2, _o, _upvals) :- _upvals = upvals, call_cl(_concat, [_o1, _o2, _o]).
cosmos_mixin__closure_2(_o, __o, _o2, _upvals) :- _upvals = upvals, call_cl(_set, [_o, "_prototype", __o, _o2]).
cosmos_mixin__closure_3(_o, _s, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "remove", T9), call_cl(T9, [_o, "_prototype", _o2]), default_lib("table", _table), getnil(_table, "toString", T10), call_cl(T10, [_o, _o2]).
cosmos_mixin__closure_4(_o, _s, _upvals) :- _upvals = upvals, true.
cosmos_mixin__closure_5(_t, _l, _t2, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "map", T13), call_cl(T13, [_t, _l, _t2]).
cosmos_mixin__closure_6(_t, _l, _t2, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "imap", T15), call_cl(T15, [_t, _l, _t2]).
