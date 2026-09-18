:- style_check(-singleton).
cosmos_utils__custom_throw(_msg, _info) :- print(_info), throw(_msg).
cosmos_utils__value_custom_throw(V1, V2, _upvals) :- cosmos_utils__custom_throw(V1, V2).
utils(_t) :- crequire("string", _string, _), crequire("io", _io, _), new(T1), set_(T1, "custom_throw", clos(upvals, cosmos_utils__value_custom_throw), T2), _t = T2.
