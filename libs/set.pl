:- style_check(-singleton).
cosmos_set__new(_t) :- new(T1), _t = T1.
cosmos_set__value_new(V1, _upvals) :- cosmos_set__new(V1).
set(_t) :- crequire("logic", _logic, _), new(T2), set_(T2, "new", clos(upvals, cosmos_set__value_new), T3), set_(T3, "has", clos(upvals, cosmos_set__closure_1), T5), set_(T5, "push", clos(upvals, cosmos_set__closure_2), T7), set_(T7, "set", clos(upvals, cosmos_set__closure_3), T8), _t = T8.
cosmos_set__closure_1(_t, _e, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "get", T4), call_cl(T4, [_t, _e, _x]).
cosmos_set__closure_2(_t, _e, _l2, _upvals) :- _upvals = upvals, default_lib("table", _table), getnil(_table, "set", T6), call_cl(T6, [_t, _e, 1.0, _l2]).
cosmos_set__closure_3(_t, _e, _l2, _upvals) :- _upvals = upvals, true.
