:- style_check(-singleton).
cosmos_test2__y(_x, _out) :- _out = _x.
cosmos_test2__value_y(V1, V2, _upvals) :- cosmos_test2__y(V1, V2).
test2(_) :- print(_s), _f = fc_F(1.0), _f = fc_z(1.0), _f = fc_z, _f = fc_z(1.0,2.0), cosmos_test2__y("", T1), _f = T1, _f = fc_F(1.0).
