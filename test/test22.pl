:- style_check(-singleton).
test22(_) :- crequire("table", _table, _), crequire("object", _object, _), default_lib("table", _table), getnil(_table, "set", T1), _set = T1, default_lib("table", _table), getnil(_table, "mixin", T2), _update = T2, new(T3), _new = clos(upvals(_update), cosmos_test22__closure_1), set_(T3, "new", _new, T6), _inc = clos(upvals, cosmos_test22__closure_2), set_(T6, "inc", _inc, T8), _Env = T8, getnil(_Env, "new", T9), call_cl(T9, [_Env, _e, _o]).
cosmos_test22__closure_1(_env, _o, _upvals) :- _upvals = upvals(_update), new(T4), set_(T4, "x", 1.0, T5), call_cl(_update, [_env, T5, _o]).
cosmos_test22__closure_2(_this, _x, _o, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "set", T7), call_cl(T7, [_this, "x", 2.0, _o]).
