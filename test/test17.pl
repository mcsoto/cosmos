:- style_check(-singleton).
test17(_) :- _x = 1.0, cosmos_test17__loop_1(_x, T2), print(T2).
cosmos_test17__loop_1(C1, F1) :- true, (({C1 < 6.0}), (print(C1), add_(1.0, C1, T1), N1 = T1), cosmos_test17__loop_1(N1, F1) ; ({C1 >= 6.0}), F1 = C1).
