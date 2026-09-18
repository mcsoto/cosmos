:- style_check(-singleton).
cosmos_prev__p(_x) :- _y = 2.0, _temp = clos(upvals(_y), cosmos_prev__closure_1), call_cl(_temp, [_x]).
cosmos_prev__value_p(V1, _upvals) :- cosmos_prev__p(V1).
prev(_) :- crequire("io", _io, _), crequire("math", _math, _), crequire("list", _list, _), cosmos_prev__p(_x).
cosmos_prev__closure_1(_x, _upvals) :- _upvals = upvals(_y), _x = _y.
