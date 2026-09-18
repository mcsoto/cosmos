:- style_check(-singleton).
cosmos_test8__balance(_f, _f2) :- true.
cosmos_test8__value_balance(V1, V2, _upvals) :- cosmos_test8__balance(V1, V2).
test8(_) :- if_(_s = "<", (cosmos_test8__balance(fc_Tuple(_color,_a2,_y,_b), _f2)), (cosmos_test8__balance(fc_Tuple(_color,_a,_y,_b2), _f2))).
