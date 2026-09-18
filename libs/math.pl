:- style_check(-singleton).
math(_t) :- new(T1), _sqrt = clos(upvals, cosmos_math__closure_1), set_(T1, "sqrt", _sqrt, T2), _random = clos(upvals, cosmos_math__closure_2), set_(T2, "random", _random, T3), _rand = clos(upvals, cosmos_math__closure_3), set_(T3, "rand", _rand, T4), _abs = clos(upvals, cosmos_math__closure_4), set_(T4, "abs", _abs, T5), _floor = clos(upvals, cosmos_math__closure_5), set_(T5, "floor", _floor, T6), _ceil = clos(upvals, cosmos_math__closure_6), set_(T6, "ceil", _ceil, T7), _min = clos(upvals, cosmos_math__closure_7), set_(T7, "min", _min, T8), _max = clos(upvals, cosmos_math__closure_8), set_(T8, "max", _max, T9), _range = clos(upvals, cosmos_math__closure_9), set_(T9, "range", _range, T15), _add = clos(upvals, cosmos_math__closure_12), set_(T15, "add", _add, T17), _sub = clos(upvals, cosmos_math__closure_13), set_(T17, "sub", _sub, T19), _mul = clos(upvals, cosmos_math__closure_14), set_(T19, "mul", _mul, T21), _div = clos(upvals, cosmos_math__closure_15), set_(T21, "div", _div, T23), _inc = clos(upvals, cosmos_math__closure_16), set_(T23, "inc", _inc, T25), _dec = clos(upvals, cosmos_math__closure_17), set_(T25, "dec", _dec, T27), _stringToNumber = clos(upvals, cosmos_math__closure_18), set_(T27, "stringToNumber", _stringToNumber, T28), _integerToString = clos(upvals, cosmos_math__closure_19), set_(T28, "integerToString", _integerToString, T29), _realToString = clos(upvals, cosmos_math__closure_20), set_(T29, "realToString", _realToString, T30), _t = T30.
cosmos_math__closure_1(_x, _y, _upvals) :- _upvals = upvals, sqrt(_x, _y).
cosmos_math__closure_2(_i, _j, _x, _upvals) :- _upvals = upvals, int(_i, _hostI), int(_j, _hostJ), random_between(_hostI, _hostJ, _hostX), cosmos_float(_hostX, _x).
cosmos_math__closure_3(_x, _upvals) :- _upvals = upvals, random(_x).
cosmos_math__closure_4(_x, _y, _upvals) :- _upvals = upvals, abs(_x, _y).
cosmos_math__closure_5(_x, _y, _upvals) :- _upvals = upvals, cfloor(_x, _y).
cosmos_math__closure_6(_x, _y, _upvals) :- _upvals = upvals, ceiling(_x, _hostY), cosmos_float(_hostY, _y).
cosmos_math__closure_7(_x, _y, _upvals) :- _upvals = upvals, inf(_x, _y).
cosmos_math__closure_8(_x, _y, _upvals) :- _upvals = upvals, sup(_x, _y).
cosmos_math__closure_10(_l, _l2, _k, _v, _i, _upvals) :- _upvals = upvals, _l = fc_T(_v,_b,_k), (({_v > _b}), (_i = 0.0) ; ({_v =< _b}), (add_(_v, 1.0, T11), add_(_k, 1.0, T12), _l2 = fc_T(T11,_b,T12), _i = 1.0)).
cosmos_math__closure_11(_pair, _l, _upvals) :- _upvals = upvals, _pair = fc_Pair(fc_T(_a,_b),_), _l = fc_T(_a,_b,0.0).
cosmos_math__closure_9(_x, _y, _z, _upvals) :- _upvals = upvals, _z = fc_Pair(fc_T(_x,_y),_it), new(T10), _next = clos(upvals, cosmos_math__closure_10), set_(T10, "next", _next, T13), _iter = clos(upvals, cosmos_math__closure_11), set_(T13, "iter", _iter, T14), _it = T14.
cosmos_math__closure_12(_x, _y, _z, _upvals) :- _upvals = upvals, add_(_x, _y, T16), _z = T16.
cosmos_math__closure_13(_x, _y, _z, _upvals) :- _upvals = upvals, r_sub(_x, _y, T18), _z = T18.
cosmos_math__closure_14(_x, _y, _z, _upvals) :- _upvals = upvals, r_mul(_x, _y, T20), _z = T20.
cosmos_math__closure_15(_x, _y, _z, _upvals) :- _upvals = upvals, r_div(_x, _y, T22), _z = T22.
cosmos_math__closure_16(_x, _y, _upvals) :- _upvals = upvals, add_(_x, 1.0, T24), _y = T24.
cosmos_math__closure_17(_x, _y, _upvals) :- _upvals = upvals, r_sub(_x, 1.0, T26), _y = T26.
cosmos_math__closure_18(_s, _n, _upvals) :- _upvals = upvals, number_string(_n, _s).
cosmos_math__closure_19(_n, _s, _upvals) :- _upvals = upvals, number_string(_n, _s).
cosmos_math__closure_20(_n, _s, _upvals) :- _upvals = upvals, number_string(_n, _s).
