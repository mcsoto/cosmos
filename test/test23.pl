:- style_check(-singleton).
test23(_) :- print(fc_T(2.0)), new(T1), set_(T1, 0.0, 1.0, T2), _t = T2, new(T3), add_(T3, _t, T4), _t2 = T4, print(_t2), _l = [1.0|[2.0|[]]], add_([], _l, T5), _l2 = T5, print(_l2).
