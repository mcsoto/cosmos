:- style_check(-singleton).
test18(_) :- _x = 2.0, cosmos_test18__loop_1(_x, T2), print(T2).
cosmos_test18__loop_1(C1, F1) :- true, (({C1 < 3.0}), (((C1 = 2.0), (add_(1.0, C1, T1), N1 = T1) ; (dif(C1, 2.0)), (true, N1 = C1))), cosmos_test18__loop_1(N1, F1) ; ({C1 >= 3.0}), F1 = C1).
