:- style_check(-singleton).
'test1-2'(_) :- _x = 0, cosmos_test1_2__loop_1(_x, _y), print(_x).
cosmos_test1_2__loop_2(C1, C2, F1, F2) :- true, ((C2 = 2), (N1 = 5, N2 = 1, print("|"), print(C1), print(C2)), cosmos_test1_2__loop_2(N1, N2, F1, F2) ; (dif(C2, 2)), F1 = C1, F2 = C2).
cosmos_test1_2__loop_1(K1, K2) :- true, ((K1 = 0), (K2 = 2, cosmos_test1_2__loop_2(T1, K2, K1, T2), print("-"), print(K1)), cosmos_test1_2__loop_1(K1, K2) ; (dif(K1, 0)), true).
