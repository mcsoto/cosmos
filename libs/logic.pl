:- style_check(-singleton).
cosmos_logic__instantiated(_x) :- def(_x).
cosmos_logic__size(_f, _n) :- fcsize(_f, _n).
cosmos_logic__get(_f, _i, _o2) :- fcget(_f, _i, _o2).
cosmos_logic__logic_iterate(_p, _n, _x, _y) :- if_(_n = 0.0, (_y = _x), (call_cl(_p, [_x, _x2]), r_sub(_n, 1.0, T1), cosmos_logic__logic_iterate(_p, T1, _x2, _y))).
cosmos_logic__apply(_p, _l) :- apply2(_p, _l).
cosmos_logic__applyOnce(_p, _l) :- apply_once(_p, _l).
cosmos_logic__eval(_fname) :- ensure_loaded(_fname), atom_string(_X, _fname), call(_X, _).
cosmos_logic__type(_x, _kind) :- cosmos_type(_x, _kind).
cosmos_logic__value_instantiated(V1, _upvals) :- cosmos_logic__instantiated(V1).
cosmos_logic__value_size(V1, V2, _upvals) :- cosmos_logic__size(V1, V2).
cosmos_logic__value_get(V1, V2, V3, _upvals) :- cosmos_logic__get(V1, V2, V3).
cosmos_logic__value_logic_iterate(V1, V2, V3, V4, _upvals) :- cosmos_logic__logic_iterate(V1, V2, V3, V4).
cosmos_logic__value_apply(V1, V2, _upvals) :- cosmos_logic__apply(V1, V2).
cosmos_logic__value_applyOnce(V1, V2, _upvals) :- cosmos_logic__applyOnce(V1, V2).
cosmos_logic__value_eval(V1, _upvals) :- cosmos_logic__eval(V1).
cosmos_logic__value_type(V1, V2, _upvals) :- cosmos_logic__type(V1, V2).
logic(_t) :-
    new(T0),
    set_(T0, "type", clos(upvals, cosmos_logic__value_type), T1),
    set_(T1, "instantiated", clos(upvals, cosmos_logic__value_instantiated), T2),
    set_(T2, "size", clos(upvals, cosmos_logic__value_size), T3),
    set_(T3, "get", clos(upvals, cosmos_logic__value_get), T4),
    set_(T4, "apply", clos(upvals, cosmos_logic__value_apply), T5),
    set_(T5, "applyOnce", clos(upvals, cosmos_logic__closure_1), T6),
    set_(T6, "applyCatch", clos(upvals, cosmos_logic__closure_2), T7),
    set_(T7, "listOf", clos(upvals, cosmos_logic__closure_3), T8),
    set_(T8, "forall", clos(upvals, cosmos_logic__closure_4), T9),
    set_(T9, "range", clos(upvals, cosmos_logic__closure_5), T10),
    set_(T10, "toString", clos(upvals, cosmos_logic__closure_9), T11),
    set_(T11, "throw", clos(upvals, cosmos_logic__closure_12), T12),
    set_(T12, "functor", clos(upvals, cosmos_logic__closure_13), _t).
cosmos_logic__closure_1(_p, _l, _q, _upvals) :- _upvals = upvals, apply_catch(_p, _l, _q).
cosmos_logic__closure_2(_p, _l, _q, _upvals) :- _upvals = upvals, apply_catch(_p, _l, _q).
cosmos_logic__closure_3(_x, _p, _args, _l, _upvals) :- _upvals = upvals, list_of(_x, _p, _args, _l).
cosmos_logic__closure_4(_p, _l, _p2, _l2, _upvals) :- _upvals = upvals, forall_cl(_p, _l, _p2, _l2).
cosmos_logic__closure_5(_i, _j, _x, _upvals) :- _upvals = upvals, default_lib("math", _math), getnil(_math, "range", T11), call_cl(T11, [_i, _j, _x]).
cosmos_logic__closure_6(_x, _p, _l, _upvals) :- _upvals = upvals, forall_cl(_p, _l, _p2, _l2).
cosmos_logic__closure_7(_upvals) :- _upvals = upvals, halt().
cosmos_logic__closure_8(_upvals) :- _upvals = upvals, halt().
cosmos_logic__closure_9(_x, _s, _upvals) :- _upvals = upvals, str(_x, _s).
cosmos_logic__closure_10(_upvals) :- _upvals = upvals, read(_x).
cosmos_logic__closure_11(_s, _upvals) :- _upvals = upvals, shell(_s).
cosmos_logic__closure_12(_x, _upvals) :- _upvals = upvals, throw(_x).
cosmos_logic__closure_13(_x, _name, _n, _upvals) :- _upvals = upvals, functor(_x, _name2, _n), atom_string(_name2, _name), cosmos_float(_n, _floatN), _n = _floatN.
cosmos_logic__closure_14(_p, _n, _x, _y, _upvals) :- _upvals = upvals, if_(_n = 0.0, (_y = _x), (cosmos_logic__logic_iterate(_p, _n, _x, _y))).
cosmos_logic__closure_15(_x, _upvals) :- _upvals = upvals, atom_string(_name, "cosmos"), file_search_path(_name, _x).
