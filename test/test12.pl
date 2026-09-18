:- style_check(-singleton).
test12(_) :- crequire("list", _list, _), crequire("table", _table, _), setmeta("list", _list), setmeta("table", _table), new(T1), set_(T1, 0.0, 2.0, T2), set_(T2, 1.0, 3.0, T3), set_(T3, 2.0, 1.0, T4), _t = T4, Collection1 = _t, cosmos_iter_start(Collection1, Iterator2), cosmos_test12__loop_1(Iterator2, _).
cosmos_test12__loop_1(C1, F1) :- cosmos_iter_next(C1, IterNext3, _, IterValue5, IterStatus6), ((IterStatus6 = 1.0), (print(IterValue5), N1 = IterNext3), cosmos_test12__loop_1(N1, F1) ; (dif(IterStatus6, 1.0)), F1 = C1).
