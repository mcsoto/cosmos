:- style_check(-singleton).
test26(_) :- print(_board), _i = 0.0, cosmos_test26__loop_1(_i, T2).
cosmos_test26__loop_1(C1, F1) :- true, (({C1 < 3.0}), (print(C1), add_(C1, 1.0, T1), N1 = T1), cosmos_test26__loop_1(N1, F1) ; ({C1 >= 3.0}), F1 = C1).
