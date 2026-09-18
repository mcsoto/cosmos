:- style_check(-singleton).
'math-swi'(_t) :- new(T1), set_(T1, "sqrt", clos(upvals, cosmos_math_swi__closure_1), T2), set_(T2, "random", clos(upvals, cosmos_math_swi__closure_2), T3), set_(T3, "abs", clos(upvals, cosmos_math_swi__closure_3), T4), set_(T4, "floor", clos(upvals, cosmos_math_swi__closure_4), T5), set_(T5, "ceil", clos(upvals, cosmos_math_swi__closure_5), T6), set_(T6, "add", clos(upvals, cosmos_math_swi__closure_6), T7), set_(T7, "sub", clos(upvals, cosmos_math_swi__closure_7), T8), set_(T8, "mul", clos(upvals, cosmos_math_swi__closure_8), T9), set_(T9, "div", clos(upvals, cosmos_math_swi__closure_9), T10), set_(T10, "inc", clos(upvals, cosmos_math_swi__closure_10), T12), set_(T12, "dec", clos(upvals, cosmos_math_swi__closure_11), T13), set_(T13, "stringToNumber", clos(upvals, cosmos_math_swi__closure_12), T14), set_(T14, "integerToString", clos(upvals, cosmos_math_swi__closure_13), T15), set_(T15, "realToString", clos(upvals, cosmos_math_swi__closure_14), T16), set_(T16, "integerToReal", clos(upvals, cosmos_math_swi__closure_15), T17), set_(T17, "realToInteger", clos(upvals, cosmos_math_swi__closure_16), T18), _t = T18.
cosmos_math_swi__closure_1(_x, _y, _upvals) :- _upvals = upvals, sqrt(_x, _y).
cosmos_math_swi__closure_2(_x, _upvals) :- _upvals = upvals, random(_x).
cosmos_math_swi__closure_3(_x, _y, _upvals) :- _upvals = upvals, abs(_x, _y).
cosmos_math_swi__closure_4(_x, _y, _upvals) :- _upvals = upvals, floor(_x, _y).
cosmos_math_swi__closure_5(_x, _y, _upvals) :- _upvals = upvals, ceiling(_x, _y).
cosmos_math_swi__closure_6(_x, _y, _z, _upvals) :- _upvals = upvals, add(_x, _y, _z).
cosmos_math_swi__closure_7(_x, _y, _z, _upvals) :- _upvals = upvals, sub(_x, _y, _z).
cosmos_math_swi__closure_8(_x, _y, _z, _upvals) :- _upvals = upvals, mul(_x, _y, _z).
cosmos_math_swi__closure_9(_x, _y, _z, _upvals) :- _upvals = upvals, div(_x, _y, _z).
cosmos_math_swi__closure_10(_x, _y, _upvals) :- _upvals = upvals, add_(_x, 1.0, T11), _y = T11.
cosmos_math_swi__closure_11(_x, _y, _upvals) :- _upvals = upvals, dec(_x, _y).
cosmos_math_swi__closure_12(_s, _n, _upvals) :- _upvals = upvals, number_string(_n, _s).
cosmos_math_swi__closure_13(_n, _s, _upvals) :- _upvals = upvals, number_string(_n, _s).
cosmos_math_swi__closure_14(_n, _s, _upvals) :- _upvals = upvals, number_string(_n, _s).
cosmos_math_swi__closure_15(_n, _x, _upvals) :- _upvals = upvals, integer_float(_n, _x).
cosmos_math_swi__closure_16(_n, _x, _upvals) :- _upvals = upvals, integer_float(_n, _x).
