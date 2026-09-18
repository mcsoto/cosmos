:- style_check(-singleton).
cosmos_string__get(_s, _x, _c) :- s_get(_s, _x, _c).
cosmos_string__size(_s, _n) :- s_size(_s, _n).
cosmos_string__slice(_S1, _I, _J, _S2) :- s_slice2(_S1, _I, _J, _S2).
cosmos_string__findIndex(_s1, _s2, _i, _pos) :- (cosmos_string__size(_s2, T1), add_(_i, T1, T2), cosmos_string__slice(_s1, _i, T2, _s2), _i = _pos ; cosmos_string__size(_s1, T3), {_i < T3}, add_(_i, 1.0, T4), cosmos_string__findIndex(_s1, _s2, T4, _pos)).
cosmos_string__splitIndex(_s, _sep, _i, _l) :- (cosmos_string__findIndex(_s, _sep, _i, _pos), add_(_pos, 1.0, T5), _pos2 = T5, cosmos_string__size(_s, _len), cosmos_string__slice(_s, _i, _pos, _part1), _l = [_part1|_l2], cosmos_string__splitIndex(_s, _sep, _pos2, _l2) ; cosmos_string__size(_s, _len), cosmos_string__slice(_s, _i, _len, _part1), _l = [_part1|fc_Cons]).
cosmos_string__concat(_s1, _s2, _s3) :- add_(_s1, _s2, T6), _s3 = T6.
cosmos_string__last(_s, _c) :- cosmos_string__size(_s, _n), r_sub(_n, 1.0, T7), cosmos_string__get(_s, T7, _c).
cosmos_string__at(_s, _x, _c) :- cosmos_string__get(_s, _x, _c).
cosmos_string__main() :- _s = "sdf", cosmos_string__size(_s, _s2), print(_s2), cosmos_string__last(_s, T8), print(T8).
cosmos_string__value_get(V1, V2, V3, _upvals) :- cosmos_string__get(V1, V2, V3).
cosmos_string__value_size(V1, V2, _upvals) :- cosmos_string__size(V1, V2).
cosmos_string__value_slice(V1, V2, V3, V4, _upvals) :- cosmos_string__slice(V1, V2, V3, V4).
cosmos_string__value_findIndex(V1, V2, V3, V4, _upvals) :- cosmos_string__findIndex(V1, V2, V3, V4).
cosmos_string__value_splitIndex(V1, V2, V3, V4, _upvals) :- cosmos_string__splitIndex(V1, V2, V3, V4).
cosmos_string__value_concat(V1, V2, V3, _upvals) :- cosmos_string__concat(V1, V2, V3).
cosmos_string__value_last(V1, V2, _upvals) :- cosmos_string__last(V1, V2).
cosmos_string__value_at(V1, V2, V3, _upvals) :- cosmos_string__at(V1, V2, V3).
cosmos_string__value_main(_upvals) :- cosmos_string__main().
string(_t) :- new(T9), _first = clos(upvals, cosmos_string__closure_1), set_(T9, "first", _first, T10), _rest = clos(upvals, cosmos_string__closure_2), set_(T10, "rest", _rest, T11), set_(T11, "get", clos(upvals, cosmos_string__value_get), T12), set_(T12, "at", clos(upvals, cosmos_string__value_at), T13), set_(T13, "size", clos(upvals, cosmos_string__value_size), T14), set_(T14, "length", clos(upvals, cosmos_string__value_size), T15), set_(T15, "findIndex", clos(upvals, cosmos_string__value_findIndex), T16), set_(T16, "slice", clos(upvals, cosmos_string__value_slice), T17), _find = clos(upvals, cosmos_string__closure_3), set_(T17, "find", _find, T18), _has = clos(upvals, cosmos_string__closure_4), set_(T18, "has", _has, T19), _upper = clos(upvals, cosmos_string__closure_5), set_(T19, "upper", _upper, T20), _lower = clos(upvals, cosmos_string__closure_6), set_(T20, "lower", _lower, T21), _split = clos(upvals, cosmos_string__closure_7), set_(T21, "split", _split, T22), _toCodes = clos(upvals, cosmos_string__closure_8), set_(T22, "toCodes", _toCodes, T23), _code = clos(upvals, cosmos_string__closure_9), set_(T23, "code", _code, T24), _lessOrEqual = clos(upvals, cosmos_string__closure_10), set_(T24, "lessOrEqual", _lessOrEqual, T25), __add = clos(upvals, cosmos_string__closure_11), set_(T25, "_add", __add, T26), set_(T26, "concat", clos(upvals, cosmos_string__value_concat), T27), _t = T27.
cosmos_string__closure_1(_S1, _S2, _upvals) :- _upvals = upvals, s_at(_S1, 0.0, _S2).
cosmos_string__closure_2(_S1, _S2, _upvals) :- _upvals = upvals, s_size(_S1, _L), s_slice(_S1, 1.0, _L, _S2).
cosmos_string__closure_3(_s1, _s2, _pos, _upvals) :- _upvals = upvals, cosmos_string__findIndex(_s1, _s2, 0.0, _pos).
cosmos_string__closure_4(_s1, _s2, _upvals) :- _upvals = upvals, cosmos_string__findIndex(_s1, _s2, 0.0, _).
cosmos_string__closure_5(_s1, _s2, _upvals) :- _upvals = upvals, string_upper(_s1, _s2).
cosmos_string__closure_6(_s1, _s2, _upvals) :- _upvals = upvals, string_lower(_s1, _s2).
cosmos_string__closure_7(_s, _sep, _l, _upvals) :- _upvals = upvals, cosmos_string__splitIndex(_s, _sep, 0.0, _l).
cosmos_string__closure_8(_s, _l, _upvals) :- _upvals = upvals, cosmos_codes(_s, _l).
cosmos_string__closure_9(_s, _n, _upvals) :- _upvals = upvals, cosmos_code(_s, _n).
cosmos_string__closure_10(_S1, _S2, _upvals) :- _upvals = upvals, s_le(_S1, _S2).
cosmos_string__closure_11(_s1, _s2, _s3, _upvals) :- _upvals = upvals, cosmos_string__concat(_s1, _s2, _s3).
