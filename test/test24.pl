:- style_check(-singleton).
cosmos_test24__istwo(_x) :- (_x = 1.0 ; _x = 2.0).
cosmos_test24__p(_x) :- default_lib("math", _math), getnil(_math, "range", T2), call_cl(T2, [1.0, 2.0, T1]), Collection1 = T1, cosmos_iter_start(Collection1, Iterator2), cosmos_test24__loop_1(Iterator2, _, _x).
cosmos_test24__value_istwo(V1, _upvals) :- cosmos_test24__istwo(V1).
cosmos_test24__value_p(V1, _upvals) :- cosmos_test24__p(V1).
test24(_) :- cosmos_test24__p(3.0).
cosmos_test24__loop_1(C1, F1, K1) :- cosmos_iter_next(C1, IterNext3, _, IterValue5, IterStatus6), (IterStatus6 = 1.0 -> (print(IterValue5), cosmos_test24__istwo(K1), N1 = IterNext3), cosmos_test24__loop_1(N1, F1, K1) ; F1 = C1).
