:- style_check(-singleton).
cosmos_test21__p(_y, _a, _x) :- if_(_y = 1.0, (true), (if_(_y = 3.0, (true), (if_(_y = 2.0, (true), (_x = 3.0)))))), _a = 10.0.
cosmos_test21__value_p(V1, _upvals) :- cosmos_test21__p(V1, C1, C2).
test21(_) :- if_(_y = 1.0, (_a = 2.0), (_x = 3.0)), cosmos_test21__p(4.0, _a, _x).
